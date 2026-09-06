# Run from the repository with: bundle exec ruby tools/tests/math_render_test.rb
require 'jekyll'
require 'yaml'

root = File.expand_path(ARGV.shift || '../..', __dir__)
settings = YAML.safe_load(File.read(File.join(root, '_config.yml')))
config = Jekyll.configuration(settings.merge('source' => root, 'safe' => true, 'quiet' => true))
converter = Jekyll::Converters::Markdown.new(config)
checks = 0
assert = lambda do |condition, message|
  abort "FAILED: #{message}" unless condition
  checks += 1
end

fixtures = {
  'escaped sets and indices' => [
    'The set $$S = \\{x_i : x_i < a_{i+1}\\}$$ is bounded.',
    '\\(S = \\{x_i : x_i &lt; a_{i+1}\\}\\)'
  ],
  'absolute values in an inline sum' => [
    'The intensity is $$N^{-1}\\sum_j\\lvert\\phi_{\\mathrm{tr}}^{(j)}\\rvert^2$$.',
    '\\(N^{-1}\\sum_j\\lvert\\phi_{\\mathrm{tr}}^{(j)}\\rvert^2\\)'
  ],
  'TeX stars and backslashes' => [
    'Use $$x_{*} + y_{*} = \\{0\\}$$ here.',
    '\\(x_{*} + y_{*} = \\{0\\}\\)'
  ],
  'inline math in a figure caption' => [
    '<figure><figcaption markdown="span">Scale $$r_M=20$$ and set $$\\{x_i\\}$$.</figcaption></figure>',
    '<figcaption>Scale \\(r_M=20\\) and set \\(\\{x_i\\}\\).</figcaption>'
  ],
  'multiline display equation' => [
    <<~'MARKDOWN',
      $$
      \begin{aligned}
      s_{k+1} &= A s_k + B u_k \\
      e_k &= \lvert s_k-s_k^d\rvert^2.
      \end{aligned}
      $$
    MARKDOWN
    <<~'HTML'.strip
      \[\begin{aligned}
      s_{k+1} &= A s_k + B u_k \\
      e_k &= \lvert s_k-s_k^d\rvert^2.
      \end{aligned}\]
    HTML
  ]
}

fixtures.each do |name, (markdown, expected)|
  html = converter.convert(markdown)
  # HTML entities are required in the generated source, including alignment &.
  expected = expected.gsub('&=', '&amp;=')
  assert.call(html.include?(expected), "#{name}: TeX changed during Markdown conversion\n#{html}")
  assert.call(!html.match?(/<(?:table|em|strong)\b/), "#{name}: Markdown interpreted part of the formula")
end

article = File.read(File.join(root, 'content/_projects/mva_time_reversal.md'))
paragraph = article.split(/\n\s*\n/).find { |part| part.start_with?('This measures the part of the field') }
assert.call(!paragraph.nil?, 'Time-reversal intensity paragraph is missing; update its regression fixture')
html = converter.convert(paragraph)
assert.call(html.strip.start_with?('<p>') && html.strip.end_with?('</p>'),
            'Time-reversal intensity paragraph became a table instead of a paragraph')
assert.call(!html.match?(/<(?:table|em|strong)\b/), 'Time-reversal formula contains accidental Markdown markup')
assert.call(html.include?('\\lvert\\phi_{\\mathrm{tr}}^{(j)}\\rvert^2'),
            'Time-reversal intensity formula lost its absolute-value delimiters')
assert.call(html.include?('\\(N^{-1}\\sum_j'), 'Time-reversal inline formula was not protected by the Markdown parser')
puts "Passed #{checks} math rendering checks using the site Markdown configuration."
