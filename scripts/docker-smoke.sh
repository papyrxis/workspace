#!/usr/bin/env bash
set -euo pipefail

image="${1:-papyrxis-workspace:smoke}"
build_image=true

if [[ "${2:-}" == "--no-build" ]]; then
  build_image=false
elif [[ $# -gt 1 ]]; then
  echo "Usage: $0 [image] [--no-build]" >&2
  exit 2
fi

if [[ "$build_image" == true ]]; then
  docker build --pull -t "$image" .
fi

docker run --rm "$image" --help >/dev/null
docker run --rm --entrypoint px "$image" --root /opt/workspace/examples/multi-document list --json >/dev/null
docker run --rm --entrypoint python "$image" -c "from px.logger import native_logger_available; assert native_logger_available(), 'native log.c library is not loaded'"

# Exercise a complete real LaTeX build inside the container, not a mocked compiler.
project="$(mktemp -d)"
trap 'rm -rf "$project"' EXIT
mkdir -p "$project/.home"
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/workspace/.home -v "$project:/workspace" "$image" init --type article --language en
cat > "$project/main.tex" <<'EOF'
\documentclass[11pt]{article}
\input{article/ieee.tex}
\title{Workspace Container E2E}
\author{Papyrxis}
\begin{document}
\maketitle
\section{Preset test}
This document is built using the shared Workspace IEEE article preset.
\end{document}
EOF
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/workspace/.home -v "$project:/workspace" "$image" build
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/workspace/.home -v "$project:/workspace" "$image" verify

echo "Docker image, native logger, LaTeX build and manifest verification passed: $image"
