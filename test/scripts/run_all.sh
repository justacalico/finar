#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$REPO_ROOT"

fail=0

for test in test/scripts/*_test.sh; do
  [ -e "$test" ] || continue
  echo "Running $test..."
  if ! bash "$test"; then
    echo "FAILED: $test" >&2
    fail=1
  fi
done

for test in test/scripts/*_test.py; do
  [ -e "$test" ] || continue
  echo "Running $test..."
  if ! python3 "$test"; then
    echo "FAILED: $test" >&2
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "One or more script tests failed" >&2
  exit 1
fi

echo "All script tests passed"
