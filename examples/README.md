# Papyrxis Examples

Complete, working examples demonstrating Papyrxis features.

## Available Examples

### minimal-book

**Simplest book structure**

Perfect for:
- First-time users
- Quick start
- Learning basics

Features:
- Minimal configuration
- Single part
- Basic front matter
- No customization

```bash
cd examples/minimal-book
make
```

### technical-book

**Full-featured technical book**

Perfect for:
- Technical documentation
- Programming books
- Algorithm textbooks

Features:
- Multiple parts and chapters
- Code listings
- Mathematical content
- Custom environments
- Index and bibliography
- Custom colors

```bash
cd examples/technical-book
make
```

### workspace.config.yml

**Complete configuration reference**

Shows all available options with explanations and examples.

Use as:
- Configuration reference
- Template for your workspace.yml
- Learning tool

```bash
cp examples/workspace.config.yml my-project/workspace.yml
```

## Example Categories

### By Complexity

**Minimal** (Start here)
- minimal-book - Bare essentials

**Standard** (Most users)
- technical-book - Full features

**Advanced** (Experts)
- custom-styling - Deep customization
- multilingual - Multiple languages

### By Purpose

**Technical Writing**
- technical-book - Programming, algorithms
- software-manual - Software documentation

**Academic**
- academic-paper - Research paper
- thesis - PhD/Master's thesis

**General**
- minimal-book - Any book
- report - Technical reports

## Quick Start

### Using an Example

```bash
# 1. Copy example
cp -r examples/minimal-book my-book

# 2. Navigate to project
cd my-book

# 3. Update configuration
vim workspace.yml

# 4. Build
make
```

### Exploring Examples

```bash
# Build all examples
cd examples
for dir in */; do
    if [ -f "$dir/Makefile" ]; then
        echo "Building $dir"
        (cd "$dir" && make)
    fi
done
```

## Example Structure

Each example includes:

```
example-name/
├── README.md           # Detailed documentation
├── workspace.yml       # Configuration
├── main.tex           # Document entry
├── Makefile           # Build system
├── parts/             # Content (books)
├── frontmatter/       # Front matter
├── backmatter/        # Back matter
├── figures/           # Images
├── references/        # Bibliography
└── configs/           # Custom overrides (if any)
```

## Common Commands

All examples support:

```bash
make              # Build document
make sync         # Sync components
make clean        # Clean artifacts
make watch        # Auto-rebuild
make version      # Show version
make help         # Show help

# Generators
make part ARGS='-n 2 -t "Part Title"'
make chapter ARGS='-p 1 -c 2 -t "Chapter Title"'
```

## Learning Path

### Beginner

1. **Start**: minimal-book
2. **Build**: Make it work
3. **Modify**: Change title, add chapter
4. **Understand**: Read generated files

### Intermediate

1. **Explore**: technical-book
2. **Features**: Try code, math, index
3. **Customize**: Modify colors
4. **Extend**: Add your content

### Advanced

1. **Study**: custom-styling
2. **Override**: Components
3. **Create**: Custom environments
4. **Master**: Full customization

## Feature Comparison

| Feature | minimal-book | technical-book |
|---------|-------------|---------------|
| Parts | 1 | 2+ |
| Chapters | 1 | 4+ |
| Code Listings | ✗ | ✓ |
| Math | ✓ | ✓ |
| Index | ✗ | ✓ |
| Custom Colors | ✗ | ✓ |
| Bibliography | ✓ | ✓ |
| Custom Envs | ✗ | ✓ |

## Customization Examples

### Change Colors

```yaml
# workspace.yml
colors:
  scheme: academic  # or technical
```

### Add Code Support

```yaml
# workspace.yml
components:
  - code
```

### Enable Index

```yaml
# workspace.yml
features:
  index: true
```

### Custom Colors

```yaml
# workspace.yml
colors:
  scheme: custom
  custom:
    primary: "25,45,85"
    accent: "0,120,215"
```

## Tips

### Building

- Use `make watch` during writing
- Run `make clean` before final build
- Check `build/main.log` for errors

### Customizing

- Start with closest example
- Modify workspace.yml first
- Override components only if needed
- Keep customizations organized

### Troubleshooting

- Verify LaTeX installation
- Check workspace.yml syntax
- Run `make sync` after config changes
- See build logs for errors

## Common Issues

**Build fails**
```bash
# Check LaTeX
pdflatex --version

# Clean and retry
make clean && make

# Check logs
cat build/main.log
```

**Components not found**
```bash
# Sync components
make sync

# Check config
cat workspace.yml
```

**PDF looks wrong**
```bash
# Update workspace
cd workspace
git pull

# Resync
cd ..
make sync && make
```

## Creating Your Example

Want to contribute an example?

1. Create complete working example
2. Include comprehensive README
3. Test build process
4. Document features
5. Submit pull request

Good examples:
- Are complete and working
- Demonstrate specific features
- Include clear documentation
- Have realistic content
- Are well-tested

## Related Documentation

- [Getting Started](../docs/getting-started.md)
- [Configuration](../docs/configuration.md)
- [Customization](../docs/customization.md)
- [Templates](../docs/templates.md)

## Support

Questions about examples:
- Check example README
- See main documentation
- Search GitHub issues
- Ask in discussions

Found a bug:
- Report in GitHub issues
- Include example name
- Provide error logs
- Show configuration

## Contributing

Improve examples:
- Fix errors
- Add documentation
- Create new examples
- Update existing ones

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.