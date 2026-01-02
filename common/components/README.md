# Components

Reusable LaTeX components for building documents.

## Overview

This directory contains modular LaTeX components that can be mixed and matched based on your needs. Each component handles a specific aspect of document formatting or functionality.

## Component Categories

### Layout and Typography

**colors.tex**
- Color scheme system
- Defines three schemes: default, technical, academic
- Provides applyColorScheme command
- Custom color definitions

**layout.tex**
- Page geometry and margins
- Line spacing and paragraph formatting
- Float positioning rules
- List formatting (itemize, enumerate, description)
- Widow and orphan control

**titles.tex**
- Section title formatting
- Spacing before and after titles
- Works with titlesec package

**pagestyles.tex**
- Header and footer styles
- Multiple page styles: main, chapter, frontmatter, part, backmatter
- Decorative rules and elements
- Page numbering formats

### Content Environments

**env.tex**
- Special environments for content organization
- partintro, chapterintro, sectionintro
- keyidea, motivation, important
- note, warning, historicalnote, connection
- All with custom formatting

**boxes.tex**
- Colored box environments using tcolorbox
- notebox, tipbox, warningbox
- examplebox, definitionbox
- Fully customizable

### Functional Components

**index.tex**
- Index generation setup
- Uses imakeidx package

**bibliography.tex**
- Bibliography configuration
- Uses biblatex with biber backend

**commands/base.tex**
- Common command definitions
- Complexity notation (bigO, bigOmega, etc.)
- Number sets (Naturals, Integers, etc.)
- Probability operators
- Set notation helpers
- Text formatting commands

### Graphics and Code

Graphics handled by graphics.tex in packages.
Code handled by code.tex in packages.

## Using Components

Components are loaded based on workspace.yml configuration:

```yaml
components:
  - colors
  - layout
  - titles
  - env
```

Each component is copied to .pxis/components/ during sync and included in the document.

## Component Dependencies

Some components depend on others:

- pagestyles requires colors (uses color definitions)
- env requires colors (for colored environments)
- boxes requires colors (for box colors)

Load dependencies before dependent components. The sync process handles this automatically for standard configurations.

## Overriding Components

To use custom versions:

1. Create configs/ directory in your project
2. Create your version: configs/colors.tex
3. Add to allow list in workspace.yml:

```yaml
overrides:
  allow:
    - colors.tex
```

4. Run make sync

Your version will be used instead.

## Component Structure

Each component should:

- Be self-contained (load own packages)
- Use consistent naming
- Follow LaTeX best practices
- Include comments explaining major sections
- Work independently when possible

## Adding New Components

To add a new component:

1. Create component-name.tex in this directory
2. Include necessary package loads
3. Define commands/environments
4. Test with both book and article types
5. Document in this README
6. Update default component lists if widely useful

## Package vs Component

Distinction:

**Packages** (common/packages/):
- Load LaTeX packages
- Minimal configuration
- Just package setup

**Components** (common/components/):
- Define commands, environments, styles
- Can load packages too
- Provide functionality

Example:
- packages/fonts.tex loads lmodern and sets encoding
- components/colors.tex loads xcolor and defines color schemes

## Component Reference

### colors.tex

Provides:
- defineColorScheme: Define new scheme
- applyColorScheme: Apply scheme
- Color variables: primary, accent, subtle, textprimary, textsecondary, border, pagebackground, codebackground

Usage:
```latex
\applyColorScheme{technical}
\textcolor{accent}{This is accent color}
```

### layout.tex

Provides:
- Page geometry via geometry package
- Line spacing via setspace
- List formatting via enumitem
- Float control
- Paragraph settings

### titles.tex

Provides:
- Title spacing for chapters, sections
- Uses titlesec package

### pagestyles.tex

Provides:
- Page styles: main, chapter, frontmatter, part, backmatter, empty
- Commands: headerrule, footerrule, decorativerule
- Font commands for headers/footers

Usage:
```latex
\pagestyle{main}
```

### env.tex

Provides environments:
- partintro, chapterintro, sectionintro, subsectionintro
- keyidea, motivation, important
- note, warning, historicalnote, connection

Usage:
```latex
\begin{keyidea}
The main idea is...
\end{keyidea}
```

### boxes.tex

Provides:
- notebox, tipbox, warningbox
- examplebox, definitionbox

Usage:
```latex
\begin{notebox}
This is a note.
\end{notebox}
```

### commands/base.tex

Provides:
- Complexity: \bigO, \bigOmega, \bigTheta
- Number sets: \Naturals, \Integers, \Reals, etc.
- Probability: \Prob, \Expect, \Var
- Set notation: \set, \setbuilder
- Text: \keyword, \term

Usage:
```latex
Algorithm runs in \bigO(n \log n) time.
Let x \in \Reals.
```

### index.tex

Provides:
- Index setup with imakeidx
- makeindex command executed

Usage in document:
```latex
Important term\index{term}
```

At end:
```latex
\printindex
```

## Best Practices

Component design:
- One responsibility per component
- Clear naming
- Minimal dependencies
- Well commented
- Tested

Using components:
- Load only what you need
- Check dependencies
- Override when needed
- Keep custom versions organized

## Troubleshooting

Common issues:

**Component not found**
- Check spelling in workspace.yml
- Verify file exists in common/components/
- Check for .tex extension

**Component not applying**
- Run make sync to regenerate .pxis/
- Check for errors in sync output
- Verify component dependencies loaded

**Override not working**
- Check file in correct location (configs/)
- Verify in allow list
- Check for typos in workspace.yml
- Run make sync

**Conflicting components**
- Some components may conflict
- Load in correct order
- Check for duplicate definitions

## Contributing Components

To contribute new components:

1. Fork repository
2. Create component in common/components/
3. Test with book and article
4. Document in this README
5. Submit pull request

Include:
- Component description
- Usage examples
- Dependencies
- Testing results

Good components are:
- Useful to many projects
- Well documented
- Properly tested
- Follow existing patterns

## Related Documentation

See also:
- docs/configuration.md - Component configuration
- docs/customization.md - Overriding components
- common/packages/README.md - Package loading