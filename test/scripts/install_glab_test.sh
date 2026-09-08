#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/install-glab.sh"

if ! bash "$SCRIPT" >/dev/null; then
  echo "FAIL: install-glab.sh did not exit cleanly" >&2
  exit 1
fi

echo "install-glab.sh test passed"
