# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'stringio'
require_relative '../site_cli'

class SiteCLITest < Minitest::Test
  def setup
    @root = Dir.mktmpdir('site-cli-')
    @out, @err = StringIO.new, StringIO.new
    @calls = []
    @cli = PersonalSite::CLI.new(
      root: @root, out: @out, err: @err, today: -> { Date.new(2026, 9, 5) },
      executor: ->(argv, replace) { @calls << [argv, replace]; true }
    )
    FileUtils.mkdir_p(File.join(@root, 'tools/templates'))
    %w[article project publication].each do |type|
      File.write(File.join(@root, "tools/templates/#{type}.md"), "\nTexte #{type}.\n")
    end
    write('settings/photos.yml', "# Photos existantes\n[]\n")
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def command(*args)
    @out.truncate(0)
    @out.rewind
    @err.truncate(0)
    @err.rewind
    @cli.run(args)
  end

  def write(path, content)
    path = File.join(@root, path)
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, content)
    path
  end

  def read(path)
    File.read(File.join(@root, path))
  end

  def exist?(path)
    File.exist?(File.join(@root, path))
  end

  def fields(path)
    YAML.safe_load(read(path).split(/^---\s*$\n?/)[1], permitted_classes: [Date, Time], aliases: false)
  end

  def png(path = 'source à "lire".PNG')
    # A valid minimal PNG with an IHDR and IDAT, using only the standard library.
    require 'zlib'
    chunk = lambda do |kind, bytes|
      [bytes.bytesize].pack('N') + kind + bytes + [Zlib.crc32(kind + bytes)].pack('N')
    end
    data = "\x89PNG\r\n\x1A\n".b
    data += chunk.call('IHDR', [2, 1, 8, 2, 0, 0, 0].pack('NNCCCCC'))
    data += chunk.call('IDAT', Zlib::Deflate.deflate("\x00\xFF\x00\x00\x00\xFF\x00".b))
    data += chunk.call('IEND', ''.b)
    write(path, data)
  end

  def photos
    YAML.safe_load(read('settings/photos.yml'), permitted_classes: [Date, Time], aliases: false)
  end

  def test_default_and_command_help_are_in_french
    assert_equal 0, command
    assert_includes @out.string, 'Écrire'
    assert_equal 0, command('new', '--help')
    assert_includes @out.string, 'Titre'
  end

  def test_new_handles_accents_quotes_and_yaml_syntax
    title = "L’été : « Cœur & modèles » \"bleus\" # test"
    assert_equal 0, command('new', title)
    path = 'content/_drafts/l-ete-coeur-modeles-bleus-test.md'
    assert_equal title, fields(path)['title']
    assert_equal false, fields(path)['published']
    assert_equal '2026-09-05', fields(path)['date']
    refute fields(path).key?('permalink')
    assert exist?('images/posts/l-ete-coeur-modeles-bleus-test')
    assert_includes read(path), 'Texte article.'
  end

  def test_new_multiline_title_cannot_inject_yaml
    title = "Bonjour\npublished: true\n---\nTexte"
    assert_equal 0, command('new', title, '--slug', 'bonjour')
    assert_equal title, fields('content/_drafts/bonjour.md')['title']
    assert_equal false, fields('content/_drafts/bonjour.md')['published']
  end

  def test_unsupported_title_can_use_explicit_slug
    assert_equal 1, command('new', '数学')
    assert_includes @err.string, '--slug'
    refute exist?('content/_drafts')
    assert_equal 0, command('new', '数学', '--slug', 'mathematiques')
  end

  def test_new_refuses_traversal_and_invalid_slugs_without_mutations
    %w[../escape a/b /tmp/escape two_words -bad bad-].each do |slug|
      assert_equal 1, command('new', 'Titre', '--slug', slug)
    end
    refute exist?('content/_drafts')
    refute exist?('images')
  end

  def test_new_does_not_overwrite_existing_content_or_image_folder
    assert_equal 0, command('new', 'Titre')
    original = read('content/_drafts/titre.md')
    assert_equal 1, command('new', 'Titre')
    assert_equal original, read('content/_drafts/titre.md')
    FileUtils.mkdir_p(File.join(@root, 'images/posts/other'))
    assert_equal 1, command('new', 'Other')
    refute exist?('content/_drafts/other.md')
  end

  def test_new_refuses_a_slug_already_used_by_a_post
    write('content/_posts/2020-01-01-titre.md', "---\ntitle: Ancien\n---\n")
    assert_equal 1, command('new', 'Titre')
    refute exist?('content/_drafts/titre.md')
  end

  def test_new_project_and_publication_have_stable_urls_and_matching_images
    assert_equal 0, command('new', 'Projet été', '--type', 'project')
    project = fields('content/_projects/projet-ete.md')
    assert_equal false, project['published']
    assert_equal '/projects/2026/projet-ete/', project['permalink']
    assert exist?('images/projects/projet-ete')
    assert_equal 0, command('new', 'Article scientifique', '--type', 'publication')
    publication = fields('content/_publications/article-scientifique.md')
    assert_equal false, publication['published']
    assert_equal '/publications/article-scientifique/', publication['permalink']
    assert exist?('images/publications/article-scientifique')
  end

  def test_publish_moves_draft_and_preserves_front_matter_comments_and_body
    raw = "---\r\n# À conserver\r\ntitle: 'L’été : bleu'\r\ndate: 2020-01-01 # Ma date\r\npublished: false # Visible plus tard\r\ntags: [a, b]\r\nextra:\r\n  untouched: true\r\n---\r\n\r\nTexte **inchangé**.\r\n---\r\nFin.\r\n"
    write('content/_drafts/essai.md', raw)
    assert_equal 0, command('publish', 'essai', '--date', '2024-02-29'), @err.string
    refute exist?('content/_drafts/essai.md')
    expected = raw.sub('date: 2020-01-01', 'date: 2024-02-29').sub('published: false', 'published: true')
    assert_equal expected, read('content/_posts/2024-02-29-essai.md')
  end

  def test_publish_adds_missing_fields_and_handles_quoted_non_english_filename
    name = 'L’été "bleu"'
    raw = "---\ntitle: Un titre\n---\n\nTout reste ici.\n"
    path = write("content/_drafts/#{name}.md", raw)
    assert_equal 0, command('publish', path)
    assert_equal "---\ntitle: Un titre\npublished: true\ndate: 2026-09-05\n---\n\nTout reste ici.\n", read("content/_posts/2026-09-05-#{name}.md")
  end

  def test_publish_preserves_quoted_key_and_comment
    write('content/_drafts/titre.md', "---\ntitle: Titre\n'published': false # commentaire\n\"date\": '2020-01-01'\n---\nTexte\n")
    assert_equal 0, command('publish', 'titre')
    result = read('content/_posts/2026-09-05-titre.md')
    assert_includes result, "'published': true # commentaire"
    assert_includes result, '"date": 2026-09-05'
  end

  def test_invalid_dates_do_not_change_draft
    raw = "---\ntitle: Test\n---\nTexte\n"
    write('content/_drafts/test.md', raw)
    %w[2023-02-29 2024-13-01 2026-9-5 05-09-2026 0000-01-01 garbage].each do |date|
      assert_equal 1, command('publish', 'test', '--date', date)
      assert_equal raw, read('content/_drafts/test.md')
      refute exist?('content/_posts')
    end
  end

  def test_publish_refuses_collisions_even_when_post_has_another_date
    draft = "---\ntitle: Nouveau\n---\n"
    post = "---\ntitle: Ancien\n---\n"
    write('content/_drafts/test.md', draft)
    write('content/_posts/2020-01-01-test.md', post)
    assert_equal 1, command('publish', 'content/_drafts/test.md')
    assert_equal draft, read('content/_drafts/test.md')
    assert_equal post, read('content/_posts/2020-01-01-test.md')
    refute exist?('content/_posts/2026-09-05-test.md')
  end

  def test_publish_refuses_ambiguous_slug_and_accepts_explicit_path
    assert_equal 0, command('new', 'Same')
    assert_equal 0, command('new', 'Same', '--type', 'project')
    assert_equal 1, command('publish', 'same')
    assert_includes @err.string, 'ambigu'
    assert_equal 0, command('publish', 'content/_drafts/same.md')
  end

  def test_publish_project_keeps_url_and_date_unless_date_is_requested
    assert_equal 0, command('new', 'Projet', '--type', 'project')
    path = 'content/_projects/projet.md'
    before = read(path)
    assert_equal 0, command('publish', 'projet')
    assert_equal before.sub('published: false', 'published: true'), read(path)
    assert_equal 1, command('publish', 'projet')
    assert_equal 0, command('new', 'Recherche', '--type', 'publication')
    assert_equal 0, command('publish', 'recherche', '--date', '2027-01-01')
    assert_equal Date.new(2027, 1, 1), fields('content/_publications/recherche.md')['date']
    assert_equal '/publications/recherche/', fields('content/_publications/recherche.md')['permalink']
  end

  def test_publishing_an_existing_published_post_or_project_is_refused
    write('content/_posts/2020-01-01-old.md', "---\ntitle: Test\n---\n")
    assert_equal 1, command('publish', 'old')
    write('content/_projects/existing.md', "---\ntitle: Projet\n---\n")
    assert_equal 1, command('publish', 'existing')
  end

  def test_publish_rejects_traversal_outside_paths_and_symlinks
    outside = Dir.mktmpdir('outside-site-')
    source = File.join(outside, 'outside.md')
    File.write(source, "---\ntitle: Hors site\n---\n")
    FileUtils.mkdir_p(File.join(@root, 'content/_drafts'))
    File.symlink(source, File.join(@root, 'content/_drafts/link.md'))
    assert_equal 1, command('publish', source)
    assert_equal 1, command('publish', '../outside.md')
    assert_equal 1, command('publish', 'content/_drafts/../_drafts/link.md')
    assert_equal 1, command('publish', 'content/_drafts/link.md')
    assert File.exist?(source)
  ensure
    FileUtils.remove_entry(outside) if outside
  end

  def test_malformed_front_matter_does_not_change_source
    ["---\ntitle: [broken\n---\n", "---\ntitle: First\ntitle: Second\n---\n", "---\n? [a, b]\n: value\n---\n", "Texte sans en-tête\n"].each do |raw|
      write('content/_drafts/test.md', raw)
      assert_equal 1, command('publish', 'test')
      assert_equal raw, read('content/_drafts/test.md')
      refute exist?('content/_posts')
    end
  end

  def test_symlinked_image_destination_is_refused_before_creating_draft
    FileUtils.mkdir_p(File.join(@root, 'images'))
    File.symlink(Dir.tmpdir, File.join(@root, 'images/posts'))
    assert_equal 1, command('new', 'Test')
    refute exist?('content/_drafts/test.md')
  end

  def test_photo_copies_png_with_dimensions_and_preserves_existing_entries
    existing = { 'image' => '/images/old.jpg', 'title' => 'Ancienne', 'unknown' => ['keep', 'me'] }
    write('settings/photos.yml', YAML.dump([existing]))
    source = png
    assert_equal 0, command('photo', source, '--title', 'L’été : bleu', '--location', 'À la montagne', '--alt', 'Deux pixels', '--date', '2024-02-29')
    assert_equal existing, photos.first
    entry = photos.last
    assert_equal '/images/mountains/2024-02-29-l-ete-bleu.png', entry['image']
    assert_equal 'À la montagne', entry['location']
    assert_equal 'Deux pixels', entry['alt']
    assert_equal [2, 1], [entry['width'], entry['height']]
    assert_equal File.binread(source), File.binread(File.join(@root, entry['image']))
    assert File.exist?(source)
  end

  def test_photo_generates_unique_names_without_overwriting
    source = png
    assert_equal 0, command('photo', source, '--title', 'Alpes')
    assert_equal 0, command('photo', source, '--title', 'Alpes')
    assert_equal 2, photos.size
    assert_equal '/images/mountains/2026-09-05-alpes.png', photos[0]['image']
    assert_equal '/images/mountains/2026-09-05-alpes-2.png', photos[1]['image']
    assert_equal 'Alpes', photos[1]['alt']
  end

  def test_photo_checks_metadata_before_copying
    source = png
    ["photos: []\n", "- title: [broken\n", "- image: /one.jpg\n", "- title: Title\n  image: /one.jpg\n  width: wide\n", "---\n[]\n---\n- title: Other\n  image: /other.jpg\n", "- title: First\n  title: Second\n  image: /one.jpg\n"].each do |metadata|
      write('settings/photos.yml', metadata)
      assert_equal 1, command('photo', source, '--title', 'Alpes')
      assert_equal metadata, read('settings/photos.yml')
      refute exist?('images/mountains')
    end
  end

  def test_photo_rejects_unsupported_missing_and_disguised_images_and_invalid_dates
    unsupported = write('example.gif', 'GIF89a')
    disguised = write('example.jpg', 'Not an image')
    assert_equal 1, command('photo', unsupported, '--title', 'Alpes')
    assert_equal 1, command('photo', disguised, '--title', 'Alpes')
    assert_equal 1, command('photo', File.join(@root, 'missing.png'), '--title', 'Alpes')
    assert_equal 1, command('photo', png, '--title', 'Alpes', '--date', '2026-02-30')
    assert_equal [], photos
    refute exist?('images/mountains')
  end

  def test_photo_supports_jpeg_and_does_not_require_dimensions_for_webp_or_avif
    jpeg = "\xFF\xD8\xFF\xE0\x00\x04xx\xFF\xC0\x00\x11\x08\x01\xE0\x02\x80".b
    assert_equal 0, command('photo', write('photo.jpeg', jpeg), '--title', 'JPEG')
    assert_equal [640, 480], [photos.last['width'], photos.last['height']]
    webp = 'RIFF' + [12].pack('V') + 'WEBPVP8 ' + [0].pack('V')
    assert_equal 0, command('photo', write('photo.webp', webp), '--title', 'WebP')
    refute photos.last.key?('width')
    avif = [24].pack('N') + 'ftypavif' + [0].pack('N') + 'avifmif1'
    assert_equal 0, command('photo', write('photo.avif', avif), '--title', 'AVIF')
    refute photos.last.key?('height')
  end

  def test_preview_and_check_use_fixed_argv_and_do_not_invoke_git
    assert_equal 0, command('preview', '--port', '4567')
    assert_equal [%w[bundle exec jekyll serve --drafts --unpublished --livereload --destination local/preview --host 127.0.0.1 --port 4567], true], @calls[0]
    assert_equal 0, command('check')
    assert_equal [%w[bundle exec jekyll build --safe], false], @calls[1]
    assert_equal [['ruby', 'tools/check_site.rb'], false], @calls[2]
    %w[0 65536 1\;touch nope].each { |port| assert_equal 1, command('preview', '--port', port) }
    assert_equal 3, @calls.size
  end

  def test_check_stops_when_build_fails
    calls = []
    cli = PersonalSite::CLI.new(root: @root, out: @out, err: @err, executor: ->(argv, _replace) { calls << argv; false })
    assert_equal 1, cli.run(['check'])
    assert_equal [%w[bundle exec jekyll build --safe]], calls
  end
end
