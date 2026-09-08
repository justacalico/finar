#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/install-ci-tools.sh"

if ! bash "$SCRIPT" >/dev/null; then
  echo "FAIL: install-ci-tools.sh did not exit cleanly" >&2
  exit 1
fi

for tool in jq gh glab; do
  if ! command -v "$tool" >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/$tool" ]; then
    echo "FAIL: $tool was not installed" >&2
    exit 1
  fi
done

echo "install-ci-tools.sh test passed"
