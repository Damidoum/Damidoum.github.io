#!/usr/bin/env ruby
# Check the generated production site without Jekyll or third-party dependencies.
require 'cgi'
require 'date'
require 'optparse'
require 'pathname'
require 'uri'
require 'yaml'

class SiteChecker
  # Keep the original article URLs and a few public entry points stable.
  REQUIRED_ROUTES = %w[
    / /blog/ /photos/ /mountains/ /resume /year-archive/
    /projects/2025/project_inria/
    /projects/2026/mva-projects/
    /projects/2026/learning-pendulum/
    /projects/2026/time-reversal/
    /preprints/2025-09-26-non-vacuous-bounds/
    /preprints/2025-09-26-non-vacuous-bounds.html
    /sitemap.xml /feed.xml
  ].freeze
  PRIVATE_DIRECTORIES = %w[
    PHOTO tools docs settings content scripts templates .git .github .openai .bundle
    .jekyll-cache .sass-cache vendor node_modules _site _drafts _posts _pages
    _projects _publications _albums _layouts _includes _data _sass
    design/layouts design/includes
  ].freeze
  PRIVATE_FILES = %w[
    site Gemfile Gemfile.lock package.json package-lock.json Dockerfile
    docker-compose.yaml _config.yml _config_docker.yml .DS_Store .gitignore
  ].freeze

  def initialize(root, destination = nil)
    @root = File.expand_path(root)
    @config = yaml(File.read(File.join(@root, '_config.yml'))) || {}
    @destination = File.expand_path(destination || @config.fetch('destination', '_site'), @root)
    @canonical_host = URI.parse(@config.fetch('url', '')).host
    @baseurl = @config.fetch('baseurl', '').to_s.sub(%r{/+\z}, '')
    @errors = []
    @link_count = 0
  end

  def run
    unless File.directory?(@destination)
      warn "Dossier de destination introuvable : #{@destination}. Lancez d’abord ./site build."
      return false
    end

    @destination = File.realpath(@destination)
    files = Dir.glob(File.join(@destination, '**', '*'), File::FNM_DOTMATCH).select { |path| File.file?(path) }
    files.each do |file|
      relative = Pathname.new(file).relative_path_from(Pathname.new(@destination)).to_s
      if private_file?(relative)
        @errors << "#{relative}: source or authoring file was published"
      end
      unless inside_destination?(File.realpath(file))
        @errors << "#{relative}: symbolic link points outside the site destination"
        next
      end
      check_html(file, relative) if File.extname(file).downcase == '.html'
    end

    REQUIRED_ROUTES.each do |route|
      @errors << "Required route #{route}: no generated file" unless output_for(route)
    end
    check_drafts(files)

    if @errors.empty?
      puts "Vérification réussie : #{files.count { |file| File.extname(file).downcase == '.html' }} pages HTML, #{@link_count} liens internes, #{REQUIRED_ROUTES.length} routes historiques."
      true
    else
      warn "Échec de la vérification (#{@errors.length} erreurs) :"
      @errors.uniq.each { |error| warn "  - #{error}" }
      false
    end
  end

  private

  def yaml(text)
    YAML.safe_load(text, permitted_classes: [Date, Time], aliases: true)
  end

  def private_file?(relative)
    PRIVATE_DIRECTORIES.any? { |directory| relative == directory || relative.start_with?("#{directory}/") } ||
      PRIVATE_FILES.include?(relative) ||
      File.basename(relative).match?(/\A(?:README|CUSTOMIZE|CONTRIBUTING|AGENTS)(?:\.|\z)/i) ||
      File.basename(relative) == '.DS_Store'
  end

  def inside_destination?(path)
    path == @destination || path.start_with?("#{@destination}/")
  end

  # Accept both directory permalinks and extensionless redirects such as /resume.
  def output_for(path)
    relative = path.sub(%r{\A/+}, '')
    candidate = File.expand_path(relative, @destination)
    return nil unless inside_destination?(candidate)

    candidates = path.end_with?('/') ? [File.join(candidate, 'index.html')] : [candidate, File.join(candidate, 'index.html'), "#{candidate}.html"]
    candidates.find do |file|
      File.file?(file) && inside_destination?(File.realpath(file))
    end
  end

  def check_html(file, relative)
    html = File.read(file, encoding: 'UTF-8')
    # Generated markup uses quoted attributes. Strip comments to avoid checking
    # examples or inactive markup; fragment targets are intentionally not checked.
    html = html.gsub(/<!--.*?-->/m) { |comment| comment.gsub(/[^\n]/, ' ') }
    html.to_enum(:scan, /\b(href|src|poster)\s*=\s*(["'])(.*?)\2/im).each do
      match = Regexp.last_match
      attribute, _quote, value = match.captures
      line = html[0...match.begin(0)].count("\n") + 1
      location = "#{relative}:#{line} #{attribute}=#{value.inspect}"
      check_link(CGI.unescapeHTML(value).strip, relative, location)
    end
  end

  def check_link(value, relative, location)
    return if value.empty? || value.start_with?('#', '?')

    if value.start_with?('//') || value.match?(/\A[a-z][a-z0-9+.-]*:/i)
      return unless value.start_with?('//') || value.match?(/\Ahttps?:/i)

      url = URI.parse(value.start_with?('//') ? "https:#{value}" : value)
      return unless @canonical_host && url.host&.casecmp?(@canonical_host)

      path = url.path.to_s.empty? ? '/' : url.path
    else
      path = value.split(/[?#]/, 2).first
    end
    path = URI::DEFAULT_PARSER.unescape(path)
    if path.match?(/[\x00-\x1f\x7f\\]/)
      @errors << "#{location}: invalid local URL path"
      return
    end

    rooted = path.start_with?('/')
    if rooted && !@baseurl.empty?
      unless path == @baseurl || path.start_with?("#{@baseurl}/")
        @errors << "#{location}: internal URL is outside baseurl #{@baseurl}"
        return
      end
      path = path.delete_prefix(@baseurl)
    end
    segments = rooted ? [] : File.dirname(relative).split('/').reject { |segment| segment == '.' }
    path.split('/').each do |segment|
      next if segment.empty? || segment == '.'
      if segment == '..'
        if segments.empty?
          @errors << "#{location}: path escapes the site destination"
          return
        end
        segments.pop
      else
        segments << segment
      end
    end

    resolved = "/#{segments.join('/')}"
    resolved += '/' if path.end_with?('/') && resolved != '/'
    @link_count += 1
    @errors << "#{location}: missing target #{resolved}" unless output_for(resolved)
  rescue URI::InvalidURIError => error
    @errors << "#{location}: invalid URL (#{error.message})"
  end

  def check_drafts(files)
    source = File.expand_path(@config.fetch('source', '.'), @root)
    collections = File.expand_path(@config.fetch('collections_dir', '.'), source)
    html_paths = files.select { |file| File.extname(file).downcase == '.html' }
    candidates = %w[_drafts _projects _publications _albums].flat_map { |directory| Dir.glob(File.join(collections, directory, '**', '*')) }
    candidates.select { |file| File.file?(file) && file.match?(/\.(?:md|markdown|html)\z/i) }.each do |draft|
      body = File.read(draft, encoding: 'UTF-8')
      front_matter = body.match(/\A---\s*\n(.*?)\n---\s*(?:\n|\z)/m)
      metadata = front_matter ? yaml(front_matter[1]) || {} : {}
      next unless draft.start_with?(File.join(collections, '_drafts') + '/') || metadata['published'] == false

      relative = Pathname.new(draft).relative_path_from(Pathname.new(@root)).to_s
      if metadata['permalink'] && !metadata['permalink'].include?(':')
        if (output = output_for(metadata['permalink']))
          @errors << "#{relative}: draft was published at #{output.delete_prefix("#{@destination}/")}"
        end
      else
        # Jekyll uses the filename (or an explicit slug) for draft URLs. Match
        # its final path component, independent of the draft's preview date.
        slug = metadata.fetch('slug', File.basename(draft, File.extname(draft))).to_s
        pattern = %r{/(?:#{Regexp.escape(slug)}/index\.html|#{Regexp.escape(slug)}\.html)\z}i
        html_paths.grep(pattern).each do |output|
          @errors << "#{relative}: matching draft slug was published at #{output.delete_prefix("#{@destination}/")}"
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  destination = nil
  parser = OptionParser.new do |options|
    options.banner = 'Utilisation : ruby tools/check_site.rb [--destination DOSSIER]'
    options.on('--destination DOSSIER', 'Dossier généré (par défaut : destination de la configuration ou _site)') { |value| destination = value }
    options.on('-h', '--help', 'Afficher cette aide') { puts options; exit }
  end
  begin
    parser.parse!
    raise OptionParser::InvalidArgument, ARGV.join(' ') unless ARGV.empty?
    exit(SiteChecker.new(File.expand_path('..', __dir__), destination).run ? 0 : 1)
  rescue OptionParser::ParseError, Psych::Exception, SystemCallError, URI::InvalidURIError, ArgumentError => error
    warn "Impossible de vérifier le site : #{error.message}"
    exit 1
  end
end
