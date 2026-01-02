# Papyrxis Workspace

A modular, extensible LaTeX workspace for technical books and academic papers. Not a framework. Not a package. Just well-organized components you can use.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

## Philosophy

LaTeX is powerful but messy. Projects accumulate cruft. Templates multiply. Consistency suffers.

Papyrxis provides:
- **Modularity**: Use what you need, ignore the rest
- **Flexibility**: Override anything easily
- **Standards**: IEEE, ACM, academic conventions built in
- **Simplicity**: No magic, just organized TeX files

## Quick Start

### Installation

As a git submodule (recommended):

```bash
mkdir my-book
cd my-book
git init
git submodule add https://github.com/papyrxis/workspace.git
bash workspace/src/init.sh -t book --title "My Book"
make
```

Or direct clone:

```bash
git clone https://github.com/papyrxis/workspace.git my-book
cd my-book
bash src/init.sh -t book --title "My Book"
make
```

### Create a Book

```bash
bash workspace/src/init.sh -t book --title "My Technical Book"
make
```

### Create an Article

```bash
bash workspace/src/init.sh -t article --title "My Research Paper"
make
```

## Features

### For Books

- Part/chapter structure
- Front matter (title, preface, TOC)
- Back matter (appendix, index, bibliography)
- Custom page styles
- Technical and academic presets
- Version management
- Watch mode for development

### For Articles

- Single and two-column layouts
- IEEE/ACM formats
- Technical and academic styles
- Bibliography management
- Theorem environments
- Quick compilation

### General

- **Modular colors**: Define schemes, apply easily
- **Modular commands**: Override or extend
- **Smart layouts**: Responsive to content
- **Build automation**: Make, watch, version
- **Git integration**: Version from tags
- **Comprehensive documentation**

## Configuration

Everything is configured through `workspace.yml`:

```yaml
project:
  type: book
  category: technical
  title: "My Book"
  author: "Your Name"

components:
  - fonts
  - math
  - graphics
  - colors
  - layout

colors:
  scheme: technical

overrides:
  allow:
    - colors.tex
    - commands/base.tex
```

Run `make sync` after editing to apply changes.

## Building

```bash
make              # Build document
make watch        # Auto-rebuild on changes
make clean        # Clean build artifacts
make version      # Show version info
```

## Customization

Override any component:

1. Create `configs/colors.tex` with your custom colors
2. Add to workspace.yml:
```yaml
overrides:
  allow:
    - colors.tex
```
3. Run `make sync`

Your custom colors are now used instead of defaults.

## Generators

Generate structure:

```bash
# New part
bash workspace/src/generator/part.sh -n 2 -t "Advanced Topics"

# New chapter
bash workspace/src/generator/chapter.sh -p 1 -c 3 -t "Data Structures"

# Cover page
bash workspace/src/generator/cover.sh workspace.yml
```

## Documentation

- **[Getting Started](docs/getting-started.md)** - Complete setup guide
- **[Configuration](docs/configuration.md)** - All configuration options
- **[Customization](docs/customization.md)** - How to customize everything
- **[Templates](docs/templates.md)** - Template documentation
- **[Scripts](docs/scripts.md)** - Script reference

## Requirements

Required:
- TeX Live or MiKTeX (full installation)
- Git
- Bash 4.0+
- Make
- Python 3 with PyYAML
- inotifywait or fswatch

## System Installation

Install globally:

```bash
sudo make install
```

Then use anywhere:

```bash
papyrxis -t book --title "My Book"
```

## Contributing

We welcome contributions!

- Bug reports
- Feature requests
- Documentation improvements
- New templates
- Code contributions

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Support

- **Issues**: [GitHub Issues](https://github.com/papyrxis/workspace/issues)
- **Discussions**: [GitHub Discussions](https://github.com/papyrxis/workspace/discussions)
- **Email**: bitsgenix@gmail.com

## License

MIT License - see [LICENSE](LICENSE)

## Credits

Created and maintained by Mahdi (Genix).

Built with:
- LaTeX
- TeX Live
- Git
- Bash
- Love for typography

## Star History

If you find Papyrxis useful, please star the repository!