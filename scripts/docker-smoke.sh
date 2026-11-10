#!/usr/bin/env bash
set -euo pipefail

image="${1:-papyrxis-workspace:smoke}"
docker build --pull -t "$image" .
docker run --rm "$image" --help >/dev/null
docker run --rm --entrypoint px "$image" --root /opt/workspace/examples/multi-document list --json >/dev/null
docker run --rm --entrypoint python "$image" -c "from px.logger import native_logger_available; assert native_logger_available(), 'native log.c library is not loaded'"
echo "Docker image smoke test passed: $image"
