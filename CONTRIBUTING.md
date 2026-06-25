# Contributing

This is a personal workspace project. If you run into something broken or missing, open an issue.

## Bug reports

Include:
- What you did (`make sync`, `make build`, etc.)
- What you expected
- What actually happened (paste the error)
- Your OS, TeX Live version (`pdflatex --version`)

## Pull requests

Keep them small and focused. One thing per PR.
If it's a bigger change, open an issue first to discuss.

## Code style

- Shell: `set -euo pipefail`, consistent quoting, meaningful variable names
- LaTeX: commented, no magic numbers
- Commit messages: short imperative ("fix sync overwriting user files")

## What I'm not interested in

- Adding framework features or abstractions
- IEEE/ACM presets (use your own template folder)
- Anything that makes the repo heavier without clear benefit
