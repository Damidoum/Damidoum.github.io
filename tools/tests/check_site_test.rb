require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative '../check_site'

def write(path, text = '')
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, text)
end

checks = 0
Dir.mktmpdir('site-check-tests') do |root|
  checker = File.join(root, 'tools', 'check_site.rb')
  FileUtils.mkdir_p(File.dirname(checker))
  FileUtils.cp(File.expand_path('../check_site.rb', __dir__), checker)
  write(File.join(root, '_config.yml'), "url: https://damidoum.github.io\ncollections_dir: content\n")
  output = File.join(root, '_site')
  SiteChecker::REQUIRED_ROUTES.each do |route|
    name = route == '/' ? 'index.html' : route.delete_prefix('/')
    name = "#{name}index.html" if name.end_with?('/')
    name += '.html' unless File.extname(name) != ''
    write(File.join(output, name), '<!doctype html><title>Test</title>')
  end
  write(File.join(output, 'assets', 'photo with spaces.png'))
  valid = <<~HTML
    <!doctype html>
    <a href="/resume">CV redirect</a>
    <a href="/blog/?page=1&amp;x=2#notes">Notebook</a>
    <a href="https://DAMIDOUM.github.io/blog/?q=yes#notes">Canonical domain</a>
    <a href="//damidoum.github.io/blog/">Protocol relative</a>
    <a href="mailto:a@example.com">Email</a>
    <link href="data:," rel="icon">
    <script src="https://cdn.example.com/missing.js"></script>
    <img src="assets/photo%20with%20spaces.png">
    <video poster="assets/photo with spaces.png"></video>
    <a href="#fragment">Fragment</a>
    <!-- <a href="/ignored-missing">Comment</a> -->
  HTML
  index = File.join(output, 'index.html')
  write(index, valid)
  run = lambda do |expected, substring = nil, *arguments|
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, checker, *arguments)
    unless status.success? == expected && (!substring || (stdout + stderr).include?(substring))
      abort "FAILED: expected success=#{expected}, message=#{substring.inspect}\n#{stdout}#{stderr}"
    end
    checks += 1
  end
  run.call(true, 'Vérification réussie')
  run.call(true, 'Vérification réussie', '--destination', output)
  write(index, valid + '<img src="missing.png">')
  run.call(false, 'missing target /missing.png')
  write(index, valid + '<a href="../outside.html">Bad path</a>')
  write(File.join(root, 'outside.html'))
  run.call(false, 'path escapes the site destination')
  write(index, valid + '<a href="/%2e%2e/outside.html">Encoded path</a>')
  run.call(false, 'path escapes the site destination')
  write(index, valid + '<a href="/resume/">Invalid slash</a>')
  run.call(false, 'missing target /resume/')
  write(index, valid)
  write(File.join(output, 'tools', 'author.rb'))
  run.call(false, 'tools/author.rb: source or authoring file was published')
  FileUtils.rm_r(File.join(output, 'tools'))
  write(File.join(output, 'docs', 'authoring.md'))
  run.call(false, 'docs/authoring.md: source or authoring file was published')
  FileUtils.rm_r(File.join(output, 'docs'))
  write(File.join(output, 'settings', 'profile.yml'))
  run.call(false, 'settings/profile.yml: source or authoring file was published')
  FileUtils.rm_r(File.join(output, 'settings'))
  write(File.join(output, 'PHOTO', 'original.raw'))
  run.call(false, 'PHOTO/original.raw: source or authoring file was published')
  FileUtils.rm_r(File.join(output, 'PHOTO'))
  write(File.join(output, 'design', 'layouts', 'site.html'))
  run.call(false, 'design/layouts/site.html: source or authoring file was published')
  FileUtils.rm_r(File.join(output, 'design'))
  write(File.join(output, 'README.md'))
  run.call(false, 'README.md: source or authoring file was published')
  FileUtils.rm(File.join(output, 'README.md'))
  draft = File.join(root, 'content', '_drafts', 'unpublished.md')
  write(draft, "---\ntitle: Unpublished\npermalink: /draft-url/\n---\nPrivate text")
  run.call(true, 'Vérification réussie')
  write(File.join(output, 'draft-url', 'index.html'))
  run.call(false, 'content/_drafts/unpublished.md: draft was published at draft-url/index.html')
  FileUtils.rm_r(File.join(output, 'draft-url'))
  write(draft, "---\ntitle: Unpublished\n---\nPrivate text")
  write(File.join(output, 'blog', '2026', '09', '05', 'unpublished', 'index.html'))
  run.call(false, 'matching draft slug was published at blog/2026/09/05/unpublished/index.html')
  FileUtils.rm_r(File.join(output, 'blog', '2026'))
  %w[projects publications albums].each do |collection|
    unpublished = File.join(root, 'content', "_#{collection}", 'future-work.md')
    write(unpublished, "---\ntitle: Future work\npublished: false\npermalink: /#{collection}/future-work/\n---\nPrivate text")
    run.call(true, 'Vérification réussie')
    write(File.join(output, collection, 'future-work', 'index.html'))
    run.call(false, "content/_#{collection}/future-work.md: draft was published at #{collection}/future-work/index.html")
    FileUtils.rm_r(File.join(output, collection, 'future-work'))
  end
  FileUtils.rm(File.join(output, 'feed.xml'))
  run.call(false, 'Required route /feed.xml: no generated file')
end
puts "Passed #{checks} isolated checker scenarios."
