#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/build-ios.sh"

if ! bash "$SCRIPT" >/dev/null; then
  echo "FAIL: build-ios.sh did not exit cleanly" >&2
  exit 1
fi

echo "build-ios.sh test passed"
