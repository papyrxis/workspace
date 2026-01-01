# Papyrxis Workspace

A modular LaTeX template system for technical books and academic papers. Built for flexibility without the bloat.

## Quick Start

```bash
# Clone the repo
git clone https://github.com/papyrxis/workspace.git
cd workspace

# Use as a book template
cp -r template/books my-book
cd my-book
make

# Or as an article
cp -r template/article/single-column my-paper
cd my-paper
pdflatex main.tex
```

## What's This?

A collection of LaTeX components you can mix and match. No forcing you into one way of doing things.

- **Common components**: Colors, commands, layouts that work across projects
- **Templates**: Starting points for books and articles
- **Scripts**: Helpers for building and managing large documents
- **Presets**: Quick configs for different document types

## Using Common Components

Instead of copying everything, symlink what you need:

```bash
cd your-project
ln -s ../workspace/common .

# In your main.tex
\input{common/packages/document.tex}
\input{common/packages/fonts.tex}
\input{common/components/colors.tex}
```

## Building Documents

### Books

```bash
cd template/books
make              # Build full book
make chapter-01   # Build single chapter
make clean        # Remove build files
```

### Articles

```bash
pdflatex main.tex
biber main
pdflatex main.tex
pdflatex main.tex
```

Or use the build script:

```bash
./scripts/build-article.sh main.tex
```

## Templates

### Book Template

Full-featured book with:
- Front matter (cover, copyright, acknowledgments)
- Part/chapter structure
- Back matter (appendix, index)
- Custom page styles

### Article Templates

**Single Column**: Traditional academic paper layout
**Two Column**: Conference paper format

## Customization

Everything's designed to be overridden. Don't like the colors? Change them:

```latex
\definecolor{myblue}{RGB}{100, 150, 200}
```

Want different fonts? Swap them:

```latex
\usepackage{times}  % Instead of charter
```

## Documentation

- [getting-started](./docs/getting-started.md) - Detailed setup guide
- [configuration](./docs/configuration.md) - All the knobs you can turn
- [customization](./docs/customization.md) - How to make it yours
- [templates](./docs/templates.md) - Template details

## Scripts

- [build-book.sh](./scripts/build-book.sh) - Full book compilation
- [build-article.sh](./scripts/build-article.sh) - Article compilation

## Philosophy

Keep it simple. LaTeX is already complex enough.

- Modular components you can use or ignore
- No magic - everything's in plain tex files
- Works with standard LaTeX tools
- Easy to modify without breaking everything

## License

[MIT](./LICENSE) - do whatever you want with it.

## Contributing

Found a bug? Have a better way to do something? Pull requests welcome.

Keep changes minimal and focused. One thing per PR.

## Contact

Issues: GitHub issues
Email: bitsgenix@gmail.com