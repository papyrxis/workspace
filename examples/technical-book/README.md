# Technical Book Example

Complete technical book with advanced features.

## Purpose

Demonstrates a full-featured technical book:
- Multiple parts and chapters
- Code listings with syntax highlighting
- Mathematical content
- Custom environments
- Index and bibliography
- Custom color scheme

## Features

- **Code Support**: Syntax-highlighted code blocks
- **Mathematics**: Full math support with theorems
- **Custom Environments**: keyidea, note, warning boxes
- **Index**: Automatic index generation
- **Bibliography**: BibTeX references
- **Custom Colors**: Technical color scheme
- **Version Control**: Git-based versioning

## Structure

```
technical-book/
├── workspace.yml           # Full configuration
├── main.tex               # Document entry
├── Makefile              # Build system
├── parts/
│   ├── part01/           # Fundamentals
│   │   ├── chapter01/
│   │   └── chapter02/
│   └── part02/           # Advanced Topics
│       ├── chapter03/
│       └── chapter04/
├── frontmatter/
│   ├── preface.tex
│   └── introduction.tex
├── backmatter/
│   └── appendix.tex
├── references/
│   └── main.bib
├── figures/
│   └── diagram.pdf
└── configs/
    └── colors.tex        # Custom colors
```

## Building

```bash
# Full build
make

# Watch mode
make watch

# Clean build
make clean && make

# Generate new chapter
make chapter ARGS='-p 1 -c 3 -t "New Chapter"'
```

## Configuration Highlights

### Custom Colors

Uses custom technical color scheme:

```yaml
colors:
  scheme: custom
  custom:
    primary: "25,45,85"
    accent: "0,120,215"
```

### Full Component Set

Includes all technical writing components:

```yaml
components:
  - fonts
  - math
  - code
  - graphics
  - tables
  - colors
  - layout
  - env
  - boxes
  - index
  - bibliography
  - commands/base
```

### Version Management

Git tag-based versioning:

```yaml
version:
  source: git
  format: "v{major}.{minor}.{patch}"
```

## Custom Elements

### Code Listings

```latex
\begin{lstlisting}[language=Python]
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
\end{lstlisting}
```

### Key Ideas

```latex
\begin{keyidea}
Dynamic programming optimizes recursive solutions by storing intermediate results.
\end{keyidea}
```

### Notes and Warnings

```latex
\begin{note}
Time complexity is O(n) with memoization.
\end{note}

\begin{warning}
Naive recursion can be exponentially slow.
\end{warning}
```

### Algorithms

```latex
\begin{algorithm}
\caption{Binary Search}
\begin{algorithmic}
\Require Sorted array $A$, target value $x$
\Ensure Index of $x$ or $-1$
\State $left \gets 0$
\State $right \gets |A| - 1$
\While{$left \leq right$}
    \State $mid \gets \lfloor(left + right) / 2\rfloor$
    \If{$A[mid] = x$}
        \Return $mid$
    \ElsIf{$A[mid] < x$}
        \State $left \gets mid + 1$
    \Else
        \State $right \gets mid - 1$
    \EndIf
\EndWhile
\Return $-1$
\end{algorithmic}
\end{algorithm}
```

## Customization

This example shows how to:

1. **Custom colors** - `configs/colors.tex`
2. **Custom commands** - `configs/commands/base.tex`
3. **Override components** - Through `overrides.allow`

## Usage as Template

To use as starting point:

```bash
# Copy example
cp -r examples/technical-book my-book
cd my-book

# Update configuration
vim workspace.yml

# Update content
vim parts/part01/part01.tex

# Build
make
```

## Tips

- Use `make watch` during writing
- Generate chapters with `make chapter`
- Index important terms with `\index{term}`
- Cite references with `\cite{key}`
- Use environments for visual emphasis

## Next Steps

- Add more chapters
- Include diagrams and figures
- Build bibliography
- Generate index
- Customize styling

## Related Examples

- **minimal-book** - Simpler structure
- **custom-styling** - More customization
- **academic-paper** - Different format