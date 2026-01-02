# Minimal Book Example

The simplest possible book using Papyrxis workspace.

## Purpose

Demonstrates the absolute minimum required to create a book:
- Minimal configuration
- Single part with one chapter
- Basic front matter
- No customization

Perfect for:
- Learning Papyrxis basics
- Quick start projects
- Understanding core concepts

## Quick Start

```bash
# Copy example
cp -r examples/minimal-book my-book
cd my-book

# Update title and author in workspace.yml
vim workspace.yml

# Build
make
```

## Structure

```
minimal-book/
├── workspace.yml      # Minimal configuration
├── main.tex          # Simple document
├── Makefile          # Build automation
├── parts/
│   └── part01/
│       └── part01.tex
├── frontmatter/
│   └── preface.tex
└── references/
    └── main.bib
```

## Building

```bash
# Build document
make

# Watch mode
make watch

# Clean and rebuild
make clean && make
```

Output: `build/main.pdf`

## Features

What this example includes:

- Minimal `workspace.yml` (only essential options)
- Single part structure
- Basic front matter (title, copyright, preface)
- Bibliography support
- Simple color scheme
- No custom overrides

What it doesn't include:

- Index generation
- Code listings
- Custom environments
- Multiple parts
- Complex styling

## Configuration

The `workspace.yml` is intentionally minimal:

```yaml
project:
  type: book
  category: technical
  title: "My Book"
  author: "Author Name"

build:
  engine: pdflatex

components:
  - fonts
  - math
  - colors
  - layout
  - bibliography

colors:
  scheme: technical
```

## Customization

### Change Title and Author

Edit `workspace.yml`:

```yaml
project:
  title: "Your Book Title"
  author: "Your Name"
  email: "you@example.com"
```

### Add a Chapter

```bash
make chapter ARGS='-p 1 -c 1 -t "Introduction"'
```

### Change Color Scheme

Edit `workspace.yml`:

```yaml
colors:
  scheme: academic  # or technical
```

### Add Components

Edit `workspace.yml` components list:

```yaml
components:
  - fonts
  - math
  - colors
  - layout
  - bibliography
  - code        # Add code support
  - index       # Add index
```

## Extending

After understanding this example:

1. **Add more content**: Generate chapters with `make chapter`
2. **Add features**: Enable index, code listings in workspace.yml
3. **Customize**: Add colors.tex override for custom colors
4. **Advanced**: See technical-book example

## Commands

```bash
# Basic
make              # Build
make clean        # Clean
make watch        # Auto-rebuild

# Generators
make chapter ARGS='-p 1 -c 2 -t "Chapter Two"'
make part ARGS='-n 2 -t "Part Two"'

# Info
make version      # Show version
make help         # Show help
```

## Tips

- Start simple, add features as needed
- Use `make watch` while writing
- Keep workspace.yml clean and minimal
- Add components only when you need them

## Common Issues

**Build fails**
- Check LaTeX installation: `pdflatex --version`
- Ensure workspace.yml is valid YAML

**Components not found**
- Run `make sync` to regenerate
- Check component names in workspace.yml

**PDF not generated**
- Check build/main.log for errors
- Try `make clean && make`

## Next Steps

Once comfortable with this example:

- **technical-book** - Full-featured technical book
- **custom-styling** - Custom colors and styling  
- **academic-paper** - Article format

## Related Documentation

- [Getting Started](../../docs/getting-started.md)
- [Configuration](../../docs/configuration.md)
- [Customization](../../docs/customization.md)