# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'optparse'
require 'pathname'
require 'tempfile'
require 'yaml'

module PersonalSite
  class Error < StandardError; end
  class HelpRequested < StandardError; end

  # Local authoring only: no Git command and no deployment action.
  class CLI
    COLLECTIONS = {
      'article' => 'content/_drafts',
      'project' => 'content/_projects',
      'publication' => 'content/_publications'
    }.freeze
    CONTENT_DIRS = (COLLECTIONS.values + ['content/_posts']).freeze
    IMAGE_DIRS = { 'article' => 'posts', 'project' => 'projects', 'publication' => 'publications' }.freeze
    IMAGE_TYPES = %w[.jpg .jpeg .png .webp .avif].freeze
    SLUG_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/.freeze
    HELP = <<~TEXT.freeze
      Écrire et prévisualiser le site

        ./site new "Titre" [--type article|project|publication] [--slug nom-court]
        ./site publish <slug-ou-chemin-content> [--date AAAA-MM-JJ]
        ./site album "Titre" [--location "Lieu"] [--date AAAA-MM-JJ]
                     [--end-date AAAA-MM-JJ] [--category "Cities"] [--slug nom-court]
        ./site photo <image> --title "Titre" [--location "Lieu"] [--alt "Description"]
                     [--album cities --album sunsets] [--date AAAA-MM-JJ] [--slug nom-court]
        ./site preview [--port 4000]
        ./site build
        ./site check

      new crée un brouillon et son dossier d’images, sans écraser de fichier.
      album crée un album thématique, avec un lieu et des dates facultatifs.
      photo accepte --album plusieurs fois, ou --albums cities,sunsets.
      Précisez --location pour une photo lorsque ses albums ne partagent pas un même lieu.
      publish prépare la publication locale. Il ne lance ni commit ni envoi sur GitHub.
      preview affiche aussi les brouillons, uniquement sur cet ordinateur.
      check construit le site puis vérifie les pages et les liens locaux.
      Les titres contenant des espaces doivent être entre guillemets.
    TEXT

    # executor receives an argv array and true only when preview should replace
    # this process. Injection keeps tests independent of Bundler and the browser.
    def initialize(root:, out: $stdout, err: $stderr, today: -> { Date.today }, executor: nil)
      @given_root = File.expand_path(root)
      @root = File.realpath(root)
      @out, @err, @today, @executor = out, err, today, executor
    end

    def run(arguments)
      args = arguments.dup
      command = args.shift
      case command
      when nil, 'help', '--help', '-h' then @out.puts HELP
      when 'new' then new_content(args)
      when 'publish' then publish(args)
      when 'album' then album(args)
      when 'photo' then photo(args)
      when 'preview' then preview(args)
      when 'build', 'check'
        parse_options(args, "./site #{command}") {}
        require_count(args, 0)
        execute(%w[bundle exec jekyll build --safe])
        execute(['ruby', 'tools/check_site.rb']) if command == 'check'
      else raise Error, "Commande inconnue : #{command}. Lancez ./site --help."
      end
      0
    rescue HelpRequested => e
      @out.puts e.message
      0
    rescue Error, OptionParser::ParseError, SystemCallError => e
      @err.puts "Erreur : #{e.message}"
      1
    end

    private

    def parse_options(args, banner)
      raise Error, 'Les arguments doivent être des textes UTF-8 valides.' unless args.all?(&:valid_encoding?)
      parser = OptionParser.new
      parser.banner = banner
      yield parser
      parser.on('-h', '--help', 'Afficher cette aide') { raise HelpRequested, parser.to_s }
      parser.parse!(args)
    end

    def require_count(args, count)
      raise Error, 'Arguments manquants ou en trop. Lancez ./site --help.' unless args.size == count
    end

    def nonempty(value, label)
      raise Error, "#{label} est obligatoire." unless value.is_a?(String)
      raise Error, "#{label} doit être un texte UTF-8 valide." unless value.valid_encoding?
      raise Error, "#{label} est obligatoire." if value.strip.empty?
      value
    end

    def slug_for(title, explicit = nil)
      if explicit
        unless explicit.match?(SLUG_PATTERN)
          raise Error, 'Le slug doit contenir uniquement a-z, 0-9 et des tirets entre les mots.'
        end
        return explicit
      end
      text = title.downcase.gsub('œ', 'oe').gsub('æ', 'ae').gsub('ß', 'ss')
      text = text.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
      slug = text.encode('ASCII', invalid: :replace, undef: :replace, replace: '-').gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
      raise Error, 'Ce titre ne donne pas de slug latin. Précisez --slug nom-court.' if slug.empty?
      slug
    end

    def date_for(value)
      return @today.call unless value
      raise Error, 'Date invalide : utilisez AAAA-MM-JJ.' unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      date = Date.iso8601(value)
      raise Error, 'Date invalide : l’année doit être comprise entre 0001 et 9999.' unless date.year.between?(1, 9999)
      date
    rescue ArgumentError
      raise Error, 'Date invalide : utilisez une date réelle au format AAAA-MM-JJ.'
    end

    # Reject lexical traversal and symlinks even if they currently resolve inside
    # the repository, so writes cannot silently target a different directory.
    def safe_path(path)
      raise Error, 'Les chemins avec « .. » sont refusés.' if path.split(File::SEPARATOR).include?('..')
      absolute = File.expand_path(path, @root)
      if absolute.start_with?(@given_root + File::SEPARATOR)
        absolute = @root + absolute.delete_prefix(@given_root)
      end
      unless absolute.start_with?(@root + File::SEPARATOR)
        raise Error, 'Le chemin doit rester dans le dossier du site.'
      end
      relative = absolute.delete_prefix(@root + File::SEPARATOR)
      current = @root
      relative.split(File::SEPARATOR).each do |part|
        current = File.join(current, part)
        raise Error, "Lien symbolique refusé : #{relative}" if File.symlink?(current)
      end
      absolute
    end

    def relative(path)
      path.delete_prefix(@root + File::SEPARATOR)
    end

    def content_files(directories = CONTENT_DIRS)
      directories.flat_map do |directory|
        base = safe_path(directory)
        Dir.glob(File.join(base, '**', '*.{md,markdown}')).map { |path| safe_path(path) }
      end
    end

    def file_slug(path)
      File.basename(path, File.extname(path)).sub(/\A\d{4}-\d{2}-\d{2}-/, '')
    end

    def read_utf8(path)
      text = File.binread(path).force_encoding(Encoding::UTF_8)
      raise Error, "Texte UTF-8 invalide : #{relative(path)}" unless text.valid_encoding?
      text
    end

    def new_content(args)
      options = { type: 'article' }
      parse_options(args, './site new "Titre" [--type article|project|publication] [--slug nom-court]') do |parser|
        parser.on('--type TYPE', 'Type de contenu') { |value| options[:type] = value }
        parser.on('--slug SLUG', 'Nom court pour le fichier et les images') { |value| options[:slug] = value }
      end
      require_count(args, 1)
      title = nonempty(args.first, 'Le titre')
      type = options[:type]
      raise Error, 'Type inconnu : choisissez article, project ou publication.' unless COLLECTIONS.key?(type)
      slug = slug_for(title, options[:slug])
      date = date_for(nil)
      path = safe_path("#{COLLECTIONS.fetch(type)}/#{slug}.md")
      assets = safe_path("images/#{IMAGE_DIRS.fetch(type)}/#{slug}")
      directories = type == 'article' ? %w[content/_drafts content/_posts] : [COLLECTIONS.fetch(type)]
      if File.exist?(path) || File.exist?(assets) || content_files(directories).any? { |file| file_slug(file) == slug }
        raise Error, "Ce slug ou son dossier d’images existe déjà : #{slug}. Choisissez --slug."
      end
      template = safe_path("tools/templates/#{type}.md")
      raise Error, "Modèle introuvable : #{relative(template)}" unless File.file?(template)
      body = read_utf8(template)
      fields = { 'title' => title, 'date' => date.iso8601, 'slug' => slug, 'published' => false, 'description' => '' }
      fields['permalink'] = "/projects/#{date.year}/#{slug}/" if type == 'project'
      if type == 'publication'
        fields.merge!('permalink' => "/publications/#{slug}/", 'category' => 'preprints', 'authors' => '', 'venue' => '', 'paperurl' => '')
      end
      cover_hint = "# Vignette facultative (chemin depuis la racine du site) :\n# cover: /images/#{IMAGE_DIRS.fetch(type)}/#{slug}/cover.jpg\n"
      document = YAML.dump(fields) + cover_hint + "---\n" + body
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.mkdir_p(File.dirname(assets))
      Dir.mkdir(assets)
      begin
        write_exclusive(path, document)
      rescue StandardError
        Dir.rmdir(assets) if Dir.exist?(assets) && Dir.empty?(assets)
        raise
      end
      @out.puts "Brouillon créé : #{relative(path)}"
      @out.puts "Images : #{relative(assets)}/"
      @out.puts "Prévisualiser : ./site preview"
    end

    def resolve_content(argument)
      nonempty(argument, 'Le slug ou le chemin')
      if argument.include?(File::SEPARATOR) || %w[.md .markdown].include?(File.extname(argument))
        path = safe_path(argument)
        allowed = CONTENT_DIRS.any? { |dir| path.start_with?(safe_path(dir) + File::SEPARATOR) }
        unless allowed && File.file?(path) && %w[.md .markdown].include?(File.extname(path))
          raise Error, 'Indiquez un fichier Markdown dans content/_drafts, _posts, _projects ou _publications.'
        end
        return path
      end
      raise Error, 'Slug invalide.' if %w[. ..].include?(argument)
      candidates = content_files.select { |file| file_slug(file) == argument }
      raise Error, "Aucun contenu ne correspond à « #{argument} »." if candidates.empty?
      if candidates.size > 1
        raise Error, "Slug ambigu. Précisez un chemin : #{candidates.map { |file| relative(file) }.join(', ')}"
      end
      candidates.first
    end

    def safe_yaml(text, label)
      stream = YAML.parse_stream(text)
      raise Error, "Un seul document YAML est autorisé dans #{label}." unless stream.children.size == 1
      validate_yaml_keys(stream, label)
      YAML.safe_load(text, permitted_classes: [Date, Time], aliases: false)
    rescue Psych::Exception => e
      raise Error, "YAML invalide dans #{label} : #{e.message}"
    end

    def validate_yaml_keys(node, label)
      if node.is_a?(Psych::Nodes::Mapping)
        keys = node.children.each_slice(2).map(&:first).select { |key| key.is_a?(Psych::Nodes::Scalar) }.map(&:value)
        raise Error, "Clés YAML dupliquées dans #{label}." unless keys.uniq == keys
      end
      (node.children || []).each { |child| validate_yaml_keys(child, label) }
    end

    def front_matter(raw, path)
      lines = raw.lines
      unless lines.first && lines.first.match?(/\A---[ \t]*\r?\n\z/)
        raise Error, "En-tête YAML absent : #{relative(path)}"
      end
      closing = (1...lines.size).find { |index| lines[index].match?(/\A---[ \t]*(?:\r?\n)?\z/) }
      raise Error, "En-tête YAML non fermé : #{relative(path)}" unless closing
      yaml = lines[1...closing].join
      fields = safe_yaml(yaml, relative(path))
      root = YAML.parse(yaml)&.root
      unless fields.is_a?(Hash) && fields.keys.all? { |key| key.is_a?(String) } && root.is_a?(Psych::Nodes::Mapping) && root.style == Psych::Nodes::Mapping::BLOCK
        raise Error, 'L’en-tête YAML doit contenir une propriété par ligne.'
      end
      [lines.first, yaml, lines[closing..-1].join, fields, root]
    end

    # Only the requested scalar values change. Other fields, comments, ordering,
    # line endings and the complete Markdown body remain byte-for-byte intact.
    def updated_document(raw, path, updates)
      opening, yaml, tail, _fields, root = front_matter(raw, path)
      lines = yaml.lines
      edits = []
      pending = updates.dup
      root.children.each_slice(2) do |key, value|
        next unless pending.key?(key.value)
        unless value.is_a?(Psych::Nodes::Scalar) && value.start_line == value.end_line
          raise Error, "Le champ #{key.value} doit tenir sur une ligne."
        end
        start = lines.take(value.start_line).join.length + value.start_column
        finish = lines.take(value.end_line).join.length + value.end_column
        edits << [start, finish, pending.delete(key.value)]
      end
      edits.sort_by(&:first).reverse_each { |start, finish, value| yaml[start...finish] = value }
      newline = opening.end_with?("\r\n") ? "\r\n" : "\n"
      yaml += newline unless yaml.empty? || yaml.end_with?("\n")
      pending.each { |key, value| yaml += "#{key}: #{value}#{newline}" }
      opening + yaml + tail
    end

    def publish(args)
      options = {}
      parse_options(args, './site publish <slug-ou-chemin-content> [--date AAAA-MM-JJ]') do |parser|
        parser.on('--date DATE', 'Date de publication') { |value| options[:date] = value }
      end
      require_count(args, 1)
      date = date_for(options[:date])
      path = resolve_content(args.first)
      raw = read_utf8(path)
      fields = front_matter(raw, path)[3]
      if path.start_with?(safe_path('content/_posts') + File::SEPARATOR) || fields['published'] == true
        raise Error, 'Ce contenu est déjà publié.'
      end
      article = path.start_with?(safe_path('content/_drafts') + File::SEPARATOR)
      unless article || fields['published'] == false
        raise Error, 'Ce contenu est déjà publié (published: false absent).'
      end
      updates = { 'published' => 'true' }
      updates['date'] = date.iso8601 if article || options[:date]
      document = updated_document(raw, path, updates)
      if article
        slug = File.basename(path, File.extname(path))
        destination = safe_path("content/_posts/#{date.iso8601}-#{slug}.md")
        if File.exist?(destination) || content_files(['content/_posts']).any? { |file| file_slug(file) == slug }
          raise Error, "Un article existe déjà pour ce slug : #{slug}."
        end
        FileUtils.mkdir_p(File.dirname(destination))
        write_exclusive(destination, document, File.stat(path).mode & 0o777)
        begin
          raise Error, 'Le brouillon a changé pendant la publication. Réessayez.' unless File.binread(path) == raw.b
          File.unlink(path)
        rescue StandardError
          File.unlink(destination)
          raise
        end
        path = destination
      else
        atomic_write(path, document, expected: raw)
      end
      @out.puts "Publication préparée : #{relative(path)}"
      @out.puts 'Le contenu reste local. Aucun commit ni envoi sur GitHub n’a été effectué.'
    end

    def album(args)
      options = {}
      parse_options(args, './site album "Titre" [--location "Lieu"] [--date AAAA-MM-JJ] [--category "Cities"] [--end-date AAAA-MM-JJ] [--slug nom-court]') do |parser|
        parser.on('--location LOCATION', 'Lieu de l’album') { |value| options[:location] = value }
        parser.on('--date DATE', 'Date de début') { |value| options[:date] = value }
        parser.on('--end-date DATE', 'Date de fin, facultative') { |value| options[:end_date] = value }
        parser.on('--category CATEGORY', 'Ancienne catégorie facultative') { |value| options[:category] = value }
        parser.on('--slug SLUG', 'Nom court de l’album et de son adresse') { |value| options[:slug] = value }
      end
      require_count(args, 1)
      title = nonempty(args.first, 'Le titre')
      location = nonempty(options[:location], 'Le lieu (--location)') if options[:location]
      date = date_for(options[:date]) if options[:date]
      end_date = date_for(options[:end_date]) if options[:end_date]
      raise Error, 'Précisez --date avant de renseigner --end-date.' if end_date && !date
      raise Error, 'La date de fin doit suivre ou égaler la date de début.' if end_date && end_date < date
      category = nonempty(options[:category], 'La catégorie (--category)').strip if options[:category]
      category ||= 'Other' if location || date
      slug = slug_for(title, options[:slug])
      path = safe_path("content/_albums/#{slug}.md")
      raise Error, "Cet album existe déjà : #{slug}. Choisissez --slug." if File.exist?(path)
      fields = {
        'layout' => 'photo_album', 'nav' => 'photos', 'title' => title,
        'cover' => '', 'cover_alt' => title
      }
      fields['category'] = category if category
      fields['location'] = location if location
      fields['date'] = date.iso8601 if date
      fields['show_dates'] = false unless date
      fields['end_date'] = end_date.iso8601 if end_date
      document = YAML.dump(fields) + "---\n\n<!-- Présentation facultative de cet album, en anglais. -->\n"
      FileUtils.mkdir_p(File.dirname(path))
      write_exclusive(path, document)
      @out.puts "Album créé : #{relative(path)}"
      date_hint = date ? " --date #{date.iso8601}" : ''
      location_hint = location ? '' : ' --location "Lieu de prise de vue"'
      @out.puts "Ajouter une photo : ./site photo \"/chemin/photo.jpg\" --title \"Titre\" --album #{slug}#{location_hint}#{date_hint}"
      @out.puts 'Choisissez ensuite cover et cover_alt dans le fichier de l’album.'
    end

    def resolve_album(slug)
      slug = slug_for('Album', nonempty(slug, 'Le nom de l’album (--album)'))
      path = safe_path("content/_albums/#{slug}.md")
      raise Error, "Album introuvable : #{slug}. Créez-le avec ./site album." unless File.file?(path)
      _opening, _yaml, _tail, fields, _root = front_matter(read_utf8(path), path)
      nonempty(fields['title'], 'Le titre de l’album')
      nonempty(fields['category'], 'La catégorie de l’album') if fields['category']
      nonempty(fields['location'], 'Le lieu de l’album') if fields['location']
      [slug, fields]
    end

    def shared_album_field(albums, field)
      values = albums.map { |_slug, metadata| metadata[field] }.uniq
      values.first if values.length == 1 && values.first.is_a?(String)
    end

    def photo(args)
      options = { albums: [] }
      parse_options(args, './site photo <image> --title "Titre" [--album cities --album sunsets] [--albums cities,sunsets] [--category "Cities"] [--location "Lieu"] [--alt "Description"] [--date AAAA-MM-JJ]') do |parser|
        parser.on('--title TITLE', 'Titre de la photo') { |value| options[:title] = value }
        parser.on('--album ALBUM', 'Album existant ; option répétable') { |value| options[:albums] << value }
        parser.on('--albums ALBUMS', 'Albums existants séparés par des virgules') { |value| options[:albums].concat(nonempty(value, 'Les albums (--albums)').split(',', -1).map(&:strip)) }
        parser.on('--category CATEGORY', 'Ancienne catégorie facultative (Other par défaut sans album)') { |value| options[:category] = value }
        parser.on('--location LOCATION', 'Lieu') { |value| options[:location] = value }
        parser.on('--alt TEXT', 'Description de l’image') { |value| options[:alt] = value }
        parser.on('--date DATE', 'Date de la photo') { |value| options[:date] = value }
        parser.on('--slug SLUG', 'Nom court du fichier') { |value| options[:slug] = value }
      end
      require_count(args, 1)
      title = nonempty(options[:title], 'Le titre (--title)')
      albums = options[:albums].map { |album| resolve_album(album) }.uniq { |slug, _metadata| slug }
      category = options[:category] || shared_album_field(albums, 'category')
      category = nonempty(category, 'La catégorie (--category)').strip if category
      category ||= 'Other' if albums.empty?
      location = options[:location] || shared_album_field(albums, 'location')
      nonempty(location, 'Le lieu (--location)') if location || !albums.empty?
      date = date_for(options[:date])
      slug = slug_for(title, options[:slug])
      source = File.expand_path(args.first)
      extension = File.extname(source).downcase
      raise Error, 'Format refusé : utilisez JPG, PNG, WebP ou AVIF.' unless IMAGE_TYPES.include?(extension)
      raise Error, 'La photo source doit être un fichier existant.' unless File.file?(source)
      dimensions = image_dimensions(source, extension)
      metadata_path = safe_path('settings/photos.yml')
      old_metadata = File.exist?(metadata_path) ? read_utf8(metadata_path) : nil
      photos = old_metadata ? safe_yaml(old_metadata, 'settings/photos.yml') : []
      validate_photos(photos)
      index = 1
      destination = nil
      loop do
        suffix = index == 1 ? '' : "-#{index}"
        destination = safe_path("images/photos/#{date.iso8601}-#{slug}#{suffix}#{extension}")
        break unless File.exist?(destination) || photos.any? { |entry| entry['image'] == '/' + relative(destination) }
        index += 1
      end
      entry = { 'title' => title, 'image' => '/' + relative(destination), 'alt' => options[:alt] || title, 'date' => date.iso8601 }
      entry['category'] = category if category
      entry['albums'] = albums.map(&:first) unless albums.empty?
      entry['location'] = location if location
      entry.merge!('width' => dimensions[0], 'height' => dimensions[1]) if dimensions
      metadata = YAML.dump(photos + [entry])
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.mkdir_p(File.dirname(metadata_path))
      write_exclusive(destination) { |output| File.open(source, 'rb') { |input| IO.copy_stream(input, output) } }
      begin
        if old_metadata
          atomic_write(metadata_path, metadata, expected: old_metadata)
        else
          write_exclusive(metadata_path, metadata)
        end
      rescue StandardError
        File.unlink(destination)
        raise
      end
      @out.puts "Photo ajoutée : #{relative(destination)}"
      @out.puts 'Légende enregistrée : settings/photos.yml'
    end

    def validate_photos(photos)
      valid = photos.is_a?(Array) && photos.all? do |entry|
        entry.is_a?(Hash) && entry.keys.all? { |key| key.is_a?(String) } &&
          %w[image title].all? { |key| entry[key].is_a?(String) && !entry[key].strip.empty? } &&
          %w[alt location].all? { |key| !entry.key?(key) || entry[key].nil? || entry[key].is_a?(String) } &&
          %w[album thumbnail].all? { |key| !entry.key?(key) || entry[key].nil? || (entry[key].is_a?(String) && entry[key].valid_encoding? && !entry[key].strip.empty?) } &&
          (!entry.key?('albums') || (entry['albums'].is_a?(Array) && !entry['albums'].empty? && entry['albums'].all? { |slug| slug.is_a?(String) && slug.valid_encoding? && slug.match?(SLUG_PATTERN) })) &&
          (!entry.key?('category') || entry['category'].nil? || (entry['category'].is_a?(String) && entry['category'].valid_encoding? && !entry['category'].strip.empty?)) &&
          %w[width height].all? { |key| !entry.key?(key) || (entry[key].is_a?(Integer) && entry[key].positive?) } &&
          (!entry.key?('date') || entry['date'].is_a?(Date) || entry['date'].is_a?(Time) || entry['date'].is_a?(String))
      end
      raise Error, 'settings/photos.yml doit contenir une liste de photos avec image et title ; albums doit être une liste de slugs non vides et category un texte non vide si ces champs sont renseignés.' unless valid
    end

    def image_dimensions(path, extension)
      File.open(path, 'rb') do |file|
        header = file.read(64) || ''.b
        valid = case extension
                when '.jpg', '.jpeg' then header.start_with?("\xFF\xD8\xFF".b)
                when '.png' then header.start_with?("\x89PNG\r\n\x1A\n".b) && header.byteslice(12, 4) == 'IHDR' && header.bytesize >= 24
                when '.webp' then header.start_with?('RIFF') && header.byteslice(8, 4) == 'WEBP'
                when '.avif'
                  header.byteslice(4, 4) == 'ftyp' && [header.byteslice(8, 4), *(header.byteslice(16..-1) || '').scan(/.{4}/m)].any? { |brand| %w[avif avis].include?(brand) }
                end
        raise Error, 'Le contenu du fichier ne correspond pas au format de l’image.' unless valid
        if extension == '.png'
          dimensions = header.byteslice(16, 8).unpack('NN')
          return dimensions if dimensions.all?(&:positive?)
        elsif %w[.jpg .jpeg].include?(extension)
          file.rewind
          return jpeg_dimensions(file)
        end
      end
      nil
    end

    def jpeg_dimensions(file)
      file.seek(2)
      4096.times do
        return nil unless file.read(1) == "\xFF".b
        marker = file.read(1)
        marker = file.read(1) while marker == "\xFF".b
        return nil unless marker
        code = marker.getbyte(0)
        return nil if [0xD9, 0xDA].include?(code)
        next if code == 0x01 || code.between?(0xD0, 0xD7)
        length_bytes = file.read(2)
        return nil unless length_bytes && length_bytes.bytesize == 2
        length = length_bytes.unpack1('n')
        return nil if length < 2
        if [0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF].include?(code)
          data = file.read(5)
          return nil unless length >= 7 && data && data.bytesize == 5
          height, width = data.byteslice(1, 4).unpack('nn')
          return [width, height] if width.positive? && height.positive?
          return nil
        end
        file.seek(length - 2, IO::SEEK_CUR)
      end
      nil
    end

    def write_exclusive(path, contents = nil, mode = 0o644)
      created = false
      begin
        File.open(path, File::WRONLY | File::CREAT | File::EXCL, mode) do |file|
          created = true
          file.binmode
          block_given? ? yield(file) : file.write(contents)
        end
      rescue StandardError
        File.unlink(path) if created && File.exist?(path)
        raise
      end
    end

    def atomic_write(path, contents, expected:)
      Tempfile.create(['.site-', '.tmp'], File.dirname(path)) do |file|
        file.binmode
        file.write(contents)
        file.close
        raise Error, 'Le fichier a changé pendant cette opération. Réessayez.' unless File.binread(path) == expected.b
        File.chmod(File.stat(path).mode & 0o777, file.path)
        File.rename(file.path, path)
      end
    end

    def preview(args)
      port = '4000'
      parse_options(args, './site preview [--port 4000]') do |parser|
        parser.on('--port PORT', 'Port local, de 1 à 65535') { |value| port = value }
      end
      require_count(args, 0)
      raise Error, 'Port invalide : choisissez un nombre de 1 à 65535.' unless port.match?(/\A\d+\z/) && port.to_i.between?(1, 65_535)
      @out.puts "Prévisualisation locale : http://127.0.0.1:#{port.to_i}"
      execute(['bundle', 'exec', 'jekyll', 'serve', '--drafts', '--unpublished', '--livereload', '--force_polling', '--destination', 'local/preview', '--host', '127.0.0.1', '--port', port.to_i.to_s], true)
    end

    def execute(argv, replace = false)
      result = if @executor
                 @executor.call(argv, replace)
               else
                 Dir.chdir(@root) { replace ? exec(*argv) : system(*argv) }
               end
      raise Error, "La commande a échoué : #{argv.join(' ')}" unless result
    end
  end
end
