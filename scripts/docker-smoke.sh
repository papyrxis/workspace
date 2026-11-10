#!/usr/bin/env bash
set -euo pipefail

image="${1:-papyrxis-workspace:smoke}"
docker build --pull -t "$image" .
docker run --rm "$image" --help >/dev/null
docker run --rm --entrypoint px "$image" --root /opt/workspace/examples/multi-document list --json >/dev/null
echo "Docker image smoke test passed: $image"
