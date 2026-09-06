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
    assert_equal 0, command('photo', '--help')
    assert_includes @out.string, '--category'
    assert_includes @out.string, 'Other par défaut'
    assert_equal 0, command('album', '--help')
    assert_includes @out.string, '--location'
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

  def test_album_creates_place_and_date_metadata_with_a_stable_filename
    assert_equal 0, command('album', 'L’été à Paris', '--location', 'Paris, France', '--date', '2026-06-20', '--end-date', '2026-06-22', '--category', 'Cities')
    album = fields('content/_albums/l-ete-a-paris.md')
    assert_equal 'L’été à Paris', album['title']
    assert_equal 'photo_album', album['layout']
    assert_equal 'photos', album['nav']
    assert_equal 'Paris, France', album['location']
    assert_equal '2026-06-20', album['date']
    assert_equal '2026-06-22', album['end_date']
    refute_equal false, album['show_dates']
    assert_equal 'Cities', album['category']
    assert_equal '', album['cover']
    assert_equal 'L’été à Paris', album['cover_alt']
    assert_includes @out.string, '--album l-ete-a-paris'
  end

  def test_album_default_category_and_explicit_slug
    assert_equal 0, command('album', '東京', '--location', 'Tokyo', '--date', '2024-02-29', '--slug', 'tokyo-2024')
    album = fields('content/_albums/tokyo-2024.md')
    assert_equal 'Other', album['category']
    refute album.key?('end_date')
  end

  def test_album_creates_a_theme_without_location_or_dates
    assert_equal 0, command('album', 'Sunsets')
    album = fields('content/_albums/sunsets.md')
    assert_equal 'Sunsets', album['title']
    assert_equal 'photo_album', album['layout']
    %w[location date end_date category].each { |key| refute album.key?(key) }
    assert_equal false, album['show_dates']
    assert_includes @out.string, '--location "Lieu de prise de vue"'
  end

  def test_album_accepts_a_location_or_date_independently
    assert_equal 0, command('album', 'Paris', '--location', 'Paris')
    assert_equal 'Paris', fields('content/_albums/paris.md')['location']
    refute fields('content/_albums/paris.md').key?('date')
    assert_equal 0, command('album', 'Summer', '--date', '2026-06-20')
    assert_equal '2026-06-20', fields('content/_albums/summer.md')['date']
    refute fields('content/_albums/summer.md').key?('location')
  end

  def test_album_refuses_invalid_metadata_and_paths_before_writing
    invalid = [
      ['--end-date', '2026-06-20'], ['--date', ''],
      ['--location', ' ', '--date', '2026-06-20'],
      ['--location', 'Paris', '--date', '2026-02-30'],
      ['--location', 'Paris', '--date', '2026-06-20', '--end-date', '2026-06-19'],
      ['--location', 'Paris', '--date', '2026-06-20', '--category', ' '],
      ['--location', 'Paris', '--date', '2026-06-20', '--slug', '../escape']
    ]
    invalid.each do |arguments|
      assert_equal 1, command('album', 'Paris', *arguments)
      refute exist?('content/_albums')
    end
  end

  def test_album_refuses_to_overwrite_existing_files_or_follow_symlinks
    assert_equal 0, command('album', 'Paris', '--location', 'Paris', '--date', '2026-06-20')
    original = read('content/_albums/paris.md')
    assert_equal 1, command('album', 'Paris', '--location', 'Paris', '--date', '2026-06-21')
    assert_equal original, read('content/_albums/paris.md')
    File.symlink(File.join(@root, 'content/_albums/paris.md'), File.join(@root, 'content/_albums/link.md'))
    assert_equal 1, command('album', 'Link', '--location', 'Paris', '--date', '2026-06-20')
    assert_equal original, read('content/_albums/paris.md')
  end

  def test_photo_adds_album_and_inherits_its_category_and_location_without_changing_the_cover
    assert_equal 0, command('album', 'Paris', '--location', 'Paris', '--date', '2026-06-20', '--category', 'Cities')
    original = read('content/_albums/paris.md')
    source = png
    assert_equal 0, command('photo', source, '--title', 'The Seine', '--album', 'paris')
    assert_equal ['paris'], photos.last['albums']
    refute photos.last.key?('album')
    assert_equal 'Cities', photos.last['category']
    assert_equal 'Paris', photos.last['location']
    assert_equal original, read('content/_albums/paris.md')
    assert_equal 0, command('photo', source, '--title', 'A church', '--album', 'paris', '--category', 'Architecture', '--location', 'Montmartre, Paris')
    assert_equal 'Architecture', photos.last['category']
    assert_equal 'Montmartre, Paris', photos.last['location']
  end

  def test_photo_can_join_several_themes_without_copying_the_image_twice
    assert_equal 0, command('album', 'Cities')
    assert_equal 0, command('album', 'Sunsets')
    assert_equal 0, command('photo', png, '--title', 'Evening on the Seine', '--album', 'cities', '--album', 'sunsets', '--album', 'cities', '--location', 'Paris')
    assert_equal ['cities', 'sunsets'], photos.last['albums']
    assert_equal 'Paris', photos.last['location']
    refute photos.last.key?('category')
    assert_equal 1, photos.size
    assert_equal 1, Dir.glob(File.join(@root, 'images/photos/*')).length
  end

  def test_photo_accepts_comma_separated_albums_and_preserves_legacy_memberships
    assert_equal 0, command('album', 'Cities')
    assert_equal 0, command('album', 'Sunsets')
    legacy = { 'title' => 'Legacy', 'image' => '/images/mountains/old.jpg', 'album' => 'old-album' }
    current = { 'title' => 'Current', 'image' => '/images/photos/current.jpg', 'albums' => ['cities', 'sunsets'] }
    write('settings/photos.yml', YAML.dump([legacy, current]))
    assert_equal 0, command('photo', png, '--title', 'Sunset', '--albums', 'cities, sunsets', '--location', 'Paris')
    assert_equal ['cities', 'sunsets'], photos.last['albums']
    assert_equal legacy, photos.first
    assert_equal current, photos[1]
  end

  def test_photo_requires_a_place_for_themes_and_checks_all_albums_before_copying
    assert_equal 0, command('album', 'Cities')
    source = png
    original = read('settings/photos.yml')
    attempts = [
      ['--album', 'cities'],
      ['--album', 'cities', '--album', 'missing', '--location', 'Paris'],
      ['--albums', '', '--location', 'Paris'],
      ['--albums', 'cities,', '--location', 'Paris'],
      ['--albums', 'cities,../escape', '--location', 'Paris']
    ]
    attempts.each do |arguments|
      assert_equal 1, command('photo', source, '--title', 'Sunset', *arguments)
      assert_equal original, read('settings/photos.yml')
      refute exist?('images/photos')
    end
  end

  def test_photo_inherits_only_metadata_shared_by_every_selected_album
    assert_equal 0, command('album', 'Paris morning', '--location', 'Paris', '--category', 'Cities')
    assert_equal 0, command('album', 'Paris evening', '--location', 'Paris', '--category', 'Cities')
    assert_equal 0, command('album', 'Lyon', '--location', 'Lyon', '--category', 'Architecture')
    source = png
    assert_equal 0, command('photo', source, '--title', 'Paris', '--albums', 'paris-morning,paris-evening')
    assert_equal 'Paris', photos.last['location']
    assert_equal 'Cities', photos.last['category']
    assert_equal 1, command('photo', source, '--title', 'Places', '--albums', 'paris-morning,lyon')
    assert_equal 1, photos.size
    assert_equal 0, command('photo', source, '--title', 'Places', '--albums', 'paris-morning,lyon', '--location', 'France')
    assert_equal 'France', photos.last['location']
    refute photos.last.key?('category')
  end

  def test_photo_rejects_malformed_existing_album_lists_before_copying
    source = png
    [nil, 'cities', [], [''], [' '], [42], ['../escape']].each do |albums|
      original = YAML.dump([{ 'title' => 'Example', 'image' => '/images/example.jpg', 'albums' => albums }])
      write('settings/photos.yml', original)
      assert_equal 1, command('photo', source, '--title', 'Sunset')
      assert_equal original, read('settings/photos.yml')
      refute exist?('images/photos')
    end
  end

  def test_photo_refuses_missing_or_invalid_albums_before_copying
    source = png
    original = read('settings/photos.yml')
    ['', 'missing', '../escape', 'a/b'].each do |album|
      assert_equal 1, command('photo', source, '--title', 'Paris', '--album', album)
      assert_equal original, read('settings/photos.yml')
      refute exist?('images/photos')
    end
    write('content/_albums/broken.md', "---\ntitle: [broken\n---\n")
    assert_equal 1, command('photo', source, '--title', 'Paris', '--album', 'broken')
    assert_equal original, read('settings/photos.yml')
    refute exist?('images/photos')
  end

  def test_photo_copies_png_with_dimensions_and_preserves_existing_entries
    existing = { 'image' => '/images/mountains/old.jpg', 'title' => 'Ancienne', 'unknown' => ['keep', 'me'], 'thumbnail' => '/images/mountains/old-small.jpg' }
    write('settings/photos.yml', YAML.dump([existing]))
    source = png
    assert_equal 0, command('photo', source, '--title', 'L’été : bleu', '--location', 'À la montagne', '--alt', 'Deux pixels', '--date', '2024-02-29')
    assert_equal existing, photos.first
    entry = photos.last
    assert_equal '/images/photos/2024-02-29-l-ete-bleu.png', entry['image']
    assert_equal 'Other', entry['category']
    refute entry.key?('album')
    assert_equal 'À la montagne', entry['location']
    assert_equal 'Deux pixels', entry['alt']
    assert_equal [2, 1], [entry['width'], entry['height']]
    assert_equal File.binread(source), File.binread(File.join(@root, entry['image']))
    assert File.exist?(source)
  end

  def test_photo_accepts_custom_categories_and_serializes_them_as_text
    category = 'Architecture : églises & "ponts"'
    assert_equal 0, command('photo', png, '--title', 'Paris', '--category', " #{category} ")
    assert_equal category, photos.last['category']
    assert_equal '/images/photos/2026-09-05-paris.png', photos.last['image']
  end

  def test_photo_rejects_blank_categories_before_copying
    source = png
    original = read('settings/photos.yml')
    ['', '   ', "\n\t"].each do |category|
      assert_equal 1, command('photo', source, '--title', 'Paris', '--category', category)
      assert_includes @err.string, 'catégorie'
      assert_equal original, read('settings/photos.yml')
      refute exist?('images/photos')
    end
  end

  def test_photo_rejects_invalid_utf8_categories_before_copying
    original = read('settings/photos.yml')
    assert_equal 1, command('photo', png, '--title', 'Paris', '--category', "\xFF".dup.force_encoding(Encoding::UTF_8))
    assert_includes @err.string, 'UTF-8'
    assert_equal original, read('settings/photos.yml')
    refute exist?('images/photos')
  end

  def test_photo_preserves_legacy_entries_with_a_null_category
    existing = { 'image' => '/images/mountains/old.jpg', 'title' => 'Ancienne', 'category' => nil }
    write('settings/photos.yml', YAML.dump([existing]))
    assert_equal 0, command('photo', png, '--title', 'Paris', '--category', 'Cities')
    assert_equal existing, photos.first
    assert_equal 'Cities', photos.last['category']
  end

  def test_photo_generates_unique_names_without_overwriting
    source = png
    assert_equal 0, command('photo', source, '--title', 'Alpes')
    assert_equal 0, command('photo', source, '--title', 'Alpes')
    assert_equal 2, photos.size
    assert_equal '/images/photos/2026-09-05-alpes.png', photos[0]['image']
    assert_equal '/images/photos/2026-09-05-alpes-2.png', photos[1]['image']
    assert_equal 'Alpes', photos[1]['alt']
  end

  def test_photo_checks_metadata_before_copying
    source = png
    ["photos: []\n", "- title: [broken\n", "- image: /one.jpg\n", "- title: Title\n  image: /one.jpg\n  width: wide\n", "---\n[]\n---\n- title: Other\n  image: /other.jpg\n", "- title: First\n  title: Second\n  image: /one.jpg\n", "- title: Title\n  image: /one.jpg\n  category: 123\n", "- title: Title\n  image: /one.jpg\n  category: ' '\n"].each do |metadata|
      write('settings/photos.yml', metadata)
      assert_equal 1, command('photo', source, '--title', 'Alpes')
      assert_equal metadata, read('settings/photos.yml')
      refute exist?('images/photos')
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
    refute exist?('images/photos')
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
    assert_equal [%w[bundle exec jekyll serve --drafts --unpublished --livereload --force_polling --destination local/preview --host 127.0.0.1 --port 4567], true], @calls[0]
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
