#!/usr/bin/env bash
set -euo pipefail

image="${1:-papyrxis-workspace:smoke}"
docker build --pull -t "$image" .
docker run --rm "$image" --help >/dev/null
docker run --rm --entrypoint px "$image" --root /opt/workspace/examples/multi-document list --json >/dev/null
docker run --rm --entrypoint python "$image" -c "from px.logger import native_logger_available; assert native_logger_available(), 'native log.c library is not loaded'"

# Exercise a complete real LaTeX build inside the container, not a mocked compiler.
project="$(mktemp -d)"
trap 'rm -rf "$project"' EXIT
docker run --rm --user "$(id -u):$(id -g)" -v "$project:/workspace" "$image" init --type article --language en
docker run --rm --user "$(id -u):$(id -g)" -v "$project:/workspace" "$image" build
docker run --rm --user "$(id -u):$(id -g)" -v "$project:/workspace" "$image" verify

echo "Docker image, native logger, LaTeX build and manifest verification passed: $image"
