# Run from the repository with: bundle exec ruby tools/tests/photo_gallery_test.rb
require 'fileutils'
require 'jekyll'
require 'nokogiri'
require 'tmpdir'
require 'yaml'

root = File.expand_path(ARGV.shift || '../..', __dir__)
settings = YAML.safe_load(File.read(File.join(root, '_config.yml')))
checks = 0
assert = lambda do |condition, message|
  abort "FAILED: #{message}" unless condition
  checks += 1
end
write = lambda do |path, text|
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, text)
end

Dir.mktmpdir('photo-gallery-tests-') do |fixture|
  # Safe-mode includes reject symlinked paths; macOS may expose TMPDIR through /var.
  fixture = File.realpath(fixture)
  source = File.join(fixture, 'source')
  destination = File.join(fixture, 'output')
  layouts = settings.fetch('layouts_dir')
  includes = settings.fetch('includes_dir')
  content = settings.fetch('collections_dir')
  data = settings.fetch('data_dir')

  %w[photos.html photo_album.html].each do |name|
    write.call(File.join(source, layouts, name), File.read(File.join(root, layouts, name)))
  end
  write.call(File.join(source, includes, 'site/photo.html'),
             File.read(File.join(root, includes, 'site/photo.html')))
  write.call(File.join(source, layouts, 'base.html'),
             '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>{{ page.title | escape }}</title></head><body><main>{{ content }}</main></body></html>')
  write.call(File.join(source, 'photos.md'), <<~MARKDOWN)
    ---
    layout: photos
    title: Photos
    permalink: /photos/
    ---
    Amateur photography fixture, with feedback welcome.
  MARKDOWN

  albums = {
    'cities' => { 'title' => 'Cities', 'cover' => '/images/shared.jpg', 'cover_alt' => 'Evening over a city' },
    'nature' => { 'title' => 'Nature' },
    'sunsets' => { 'title' => 'Sunsets' }
  }
  albums.each do |slug, metadata|
    metadata['show_dates'] = false
    write.call(File.join(source, content, '_albums', "#{slug}.md"),
               "#{YAML.dump(metadata)}---\n")
  end
  photos = [
    { 'albums' => %w[cities sunsets], 'image' => '/images/shared.jpg',
      'thumbnail' => '/images/shared-thumb.jpg', 'title' => 'Roof <light>',
      'alt' => 'A city at sunset', 'location' => 'Montréal & Laval',
      'date' => '2024-07-20', 'width' => 800, 'height' => 1200 },
    { 'album' => 'cities', 'image' => '/images/legacy.jpg',
      'title' => 'Street', 'alt' => 'A street', 'location' => 'Paris' },
    { 'album' => 'cities', 'albums' => ['cities'], 'image' => '/images/both-fields.jpg',
      'title' => 'Square', 'alt' => 'A square', 'location' => 'Paris' },
    { 'albums' => ['sunsets'], 'image' => '/images/sunset.jpg',
      'title' => 'Evening', 'alt' => 'An evening sky', 'location' => 'Montréal & Laval' },
    { 'image' => '/images/independent.jpg', 'title' => 'Independent', 'alt' => 'A photograph without an album' },
    { 'albums' => [], 'image' => '/images/empty-list.jpg', 'title' => 'Unassigned', 'alt' => 'An unassigned photograph' }
  ]
  write.call(File.join(source, data, 'photos.yml'), YAML.dump(photos))

  config = Jekyll.configuration(settings.merge(
    'source' => source, 'destination' => destination, 'baseurl' => '/preview',
    'safe' => true, 'quiet' => true, 'incremental' => false,
    'plugins' => [], 'url' => 'https://example.test'
  ))
  begin
    Jekyll::Site.new(config).process
  rescue StandardError => error
    abort "FAILED: real gallery layouts could not build with isolated fixture (#{error.class}): #{error.message}"
  end

  read_page = lambda do |route|
    path = File.join(destination, route, 'index.html')
    assert.call(File.file?(path), "Missing generated gallery route: /#{route}/")
    Nokogiri::HTML(File.read(path))
  end
  index = read_page.call('photos')
  cities = read_page.call('photos/cities')
  sunsets = read_page.call('photos/sunsets')
  nature = read_page.call('photos/nature')
  assert.call([cities, sunsets, nature].all? { |page| page.css('.album-heading time').empty? },
              'Undated themed albums must not display the automatic document modification date')
  expected_images = {
    cities => %w[/preview/images/shared.jpg /preview/images/legacy.jpg /preview/images/both-fields.jpg],
    sunsets => %w[/preview/images/shared.jpg /preview/images/sunset.jpg]
  }
  expected_images.each do |page, images|
    figures = page.css('.photo-grid figure')
    assert.call(figures.map { |figure| figure.at_css('a')['href'] }.sort == images.sort,
                'Album membership must include both array and legacy fields without duplicates')
    assert.call(figures.all? { |figure| ([figure] + figure.ancestors.to_a).none? { |node| node.key?('hidden') } },
                'Album photographs must remain visible without JavaScript')
    assert.call(page.at_css('[data-photo-count]')&.text&.strip == "#{images.size} photos",
                'The initial album photo count must match the rendered images')
  end

  cards = index.css('.album-card')
  assert.call(cards.map { |card| card.at_css('h2 a').text } == %w[Cities Nature Sunsets],
              'The overview must render themed albums in title order without requiring dates')
  assert.call(cards.map { |card| card.at_css('h2 a')['href'] } ==
              %w[/preview/photos/cities/ /preview/photos/nature/ /preview/photos/sunsets/],
              'Album title links must respect baseurl')
  assert.call(cards.map { |card| card.at_css('.album-meta').text.strip } == ['3 photos', '0 photos', '2 photos'],
              'Overview counts must use the same membership rules as album pages')
  cities_cover = cards.first.at_css('.album-cover')
  assert.call(cities_cover['href'] == '/preview/photos/cities/' &&
              cities_cover.at_css('img')['src'] == '/preview/images/shared-thumb.jpg',
              'Selected album cover must use its thumbnail and open the album')
  assert.call(cards.last.at_css('.album-cover img')['src'] == '/preview/images/shared-thumb.jpg',
              'An unspecified cover must fall back to the first album photograph')
  assert.call(index.text.include?('Amateur photography fixture, with feedback welcome.'),
              'The gallery must retain its Markdown introduction')

  independent = index.css('.loose-photos figure')
  independent_links = independent.map { |figure| figure.at_css('a')['href'] }
  assert.call(independent_links ==
              %w[/preview/images/independent.jpg /preview/images/empty-list.jpg],
              "Photos with no album or an empty album list must remain in the main gallery; found #{independent_links.inspect}")
  assert.call(independent.all? { |figure| ([figure] + figure.ancestors.to_a).none? { |node| node.key?('hidden') } },
              'Independent photographs must remain visible without JavaScript')

  shared = cities.at_css('.photo-grid figure')
  assert.call(shared.at_css('img')['src'] == '/preview/images/shared-thumb.jpg' &&
              shared.at_css('a')['href'] == '/preview/images/shared.jpg',
              'Photo thumbnails must link to the full image')
  assert.call(shared.at_css('img')['width'] == '800' && shared.at_css('img')['height'] == '1200',
              'The photo include must preserve the image dimensions')
  assert.call(shared.at_css('figcaption').text.include?('Roof <light>') &&
              shared.at_css('figcaption').css('light').empty?,
              'Photo captions must escape text instead of treating it as markup')
  assert.call(shared['data-photo-location'] == 'Montréal & Laval' &&
              shared.at_css('figcaption').text.include?('Montréal & Laval'),
              'The visible place and filter value must preserve accents and special characters')
  assert.call(shared.at_css('time')['datetime'] == '2024-07-20', 'Photo capture dates must be retained')

  places = cities.at_css('select#photo-location')
  assert.call(!places.nil? && places.css('option').map { |option| option['value'] } == ['', 'Montréal & Laval', 'Paris'],
              'The place selector must offer each distinct location exactly once')
  assert.call(places.at_xpath('ancestor::*[contains(@class, "photo-location-filter")]')&.key?('hidden'),
              'Place controls must wait for JavaScript enhancement')
  assert.call(sunsets.css('select#photo-location').empty?, 'A single-location album does not need a place selector')
  assert.call(nature.css('.photo-grid figure').empty? && nature.at_css('.empty-message'),
              'An empty album must retain a clear empty state')
end

puts "Passed #{checks} isolated photo gallery rendering checks using the real site layouts."
