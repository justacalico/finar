#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$REPO_ROOT"

fail=0

for script in scripts/*.sh; do
  [ -e "$script" ] || continue
  if ! bash -n "$script"; then
    echo "FAIL: $script has syntax errors" >&2
    fail=1
  fi
done

for script in test/scripts/*.sh; do
  [ -e "$script" ] || continue
  if ! bash -n "$script"; then
    echo "FAIL: $script has syntax errors" >&2
    fail=1
  fi
done

for py in scripts/*.py test/scripts/*.py; do
  [ -e "$py" ] || continue
  if ! python3 -m py_compile "$py"; then
    echo "FAIL: $py has syntax errors" >&2
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "Syntax tests passed"
