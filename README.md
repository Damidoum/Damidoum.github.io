# Damien Rouchouse — personal website

A custom Jekyll website for research, mathematical notes, and mountain photography.
The interface is independent of the original Academic Pages theme. The existing
GitHub Pages/Jekyll workflow and Markdown content are retained.

```sh
bundle install
bundle exec jekyll serve --host 127.0.0.1 --port 4000
```

See [CUSTOMIZE.md](CUSTOMIZE.md) for editing the design, publishing a note, adding
photographs, and maintaining research content.

Build with `bundle exec jekyll build --safe`. The active design lives in
`assets/css/site.css`, `_layouts/site.html`, and `_includes/site/`.

Original Academic Pages/Minimal Mistakes source files and their licence are
retained in this repository. Unused demo content is excluded from the site.
