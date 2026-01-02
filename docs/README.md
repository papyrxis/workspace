# Documentation

Complete documentation for Papyrxis workspace.

## Overview

This directory contains all user documentation for understanding and using Papyrxis.

Documentation is organized by topic, from beginner to advanced.

## Documentation Structure

### Getting Started

**getting-started.md** - Complete introduction

Covers:
- Installation methods
- Quick start guide
- Project structure
- Basic building
- Common workflows
- Troubleshooting

Start here if you are new to Papyrxis.

### Configuration

**configuration.md** - Complete configuration reference

Covers:
- workspace.yml file format
- All configuration options
- Default values
- Examples
- Validation

Refer here when configuring your project.

### Customization

**customization.md** - How to customize

Covers:
- Configuration-based customization
- Component overrides
- Custom environments
- Custom color schemes
- Custom fonts
- Examples

Use when you need to adapt Papyrxis to your needs.

### Templates

**templates.md** - Template system

Covers:
- Template structure
- Available templates
- Using templates
- Template variables
- Creating custom templates

Explains how templates work and how to use them.

### Scripts

**scripts.md** - Script reference

Covers:
- Available scripts
- Usage examples
- Options and flags
- Advanced usage
- Troubleshooting

Reference for all scripts in scripts/ directory.

## Reading Order

### First Time Users

1. getting-started.md - Understand basics
2. Try building a simple project
3. configuration.md - Learn options
4. customization.md - When you need changes

### Experienced Users

Jump directly to:
- configuration.md for option reference
- customization.md for advanced features
- scripts.md for automation

### Contributors

Read everything, plus:
- Study examples/
- Review source code
- Check CONTRIBUTING.md

## Documentation Format

All documentation is written in Markdown with:

- Clear headings
- Code examples
- Plain English explanations
- No emoji or excessive formatting
- Focus on understanding, not just instructions

## Documentation Principles

**Clarity:**
- Simple language
- Clear examples
- Obvious structure

**Completeness:**
- All options documented
- All features explained
- Edge cases covered

**Accuracy:**
- Up to date with code
- Tested examples
- Correct information

**Usability:**
- Organized by topic
- Easy to find information
- Searchable

## Using Documentation

### Searching

Use your text editor or terminal:

```bash
# Search all docs
grep -r "color scheme" docs/

# Search specific doc
grep "workspace.yml" docs/configuration.md
```

### Reading Offline

Clone repository and read with any text viewer:

```bash
# Terminal
less docs/getting-started.md

# Text editor
vim docs/configuration.md

# Markdown viewer
glow docs/customization.md
```

### Contributing

Found error or unclear section? Please:

1. Open issue describing problem
2. Or submit pull request with fix
3. Or ask question in discussions

## Documentation Maintenance

Documentation is maintained alongside code:

- Updates with feature changes
- New sections for new features
- Corrections for errors
- Clarifications from user feedback

Version tracked with code in git.

## Related Files

Beyond docs/ directory:

**Root level:**
- README.md - Project overview
- CONTRIBUTING.md - Contribution guide
- CHANGELOG.md - Version history
- LICENSE - License terms

**Directory READMEs:**
- common/components/README.md - Component system
- common/packages/README.md - Package loading
- common/presets/README.md - Preset system
- examples/README.md - Example projects
- scripts/README.md - Script documentation

## Documentation Status

Current documentation coverage:

- getting-started.md - Complete
- configuration.md - Complete
- customization.md - Complete
- templates.md - Complete
- scripts.md - Complete

## Getting Help

If documentation does not answer your question:

1. Check examples/ directory
2. Search existing issues
3. Ask in discussions
4. Open new issue

We improve documentation based on user questions.

## Contributing to Documentation

To improve documentation:

1. Fork repository
2. Edit markdown files
3. Preview changes
4. Submit pull request

Include:
- Clear description of change
- Reason for change (unclear, error, missing)
- Tested examples if adding code

Good documentation contributions:
- Fix errors
- Clarify confusion
- Add missing information
- Provide examples
- Improve organization

## Documentation Style Guide

When contributing:

**Voice:**
- Direct, second person (you)
- Active voice
- Present tense
- Conversational but professional

**Structure:**
- Clear headings
- Short paragraphs
- Lists for steps
- Code blocks for examples

**Code Examples:**
- Complete and working
- Commented when needed
- Realistic use cases
- Copy-paste ready

**Formatting:**
- Standard Markdown
- Inline code for commands: `make`
- Code blocks for multi-line
- No emoji or special characters

**Length:**
- Long enough to be clear
- Short enough to stay focused
- Break long topics into sections

## Documentation Goals

What we aim for:

1. New user can start in under 10 minutes
2. All features are documented
3. Examples are provided for common tasks
4. Edge cases are explained
5. Troubleshooting covers common issues
6. Advanced usage is possible

## Feedback

Documentation feedback is valuable. Tell us:

- What was unclear
- What was missing
- What was confusing
- What examples would help
- What worked well

Open issue or discussion with feedback.