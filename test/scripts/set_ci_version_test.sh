#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/set-ci-version.sh"

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

PUBSPEC="$TMPDIR_TEST/pubspec.yaml"
printf 'name: finar\nversion: 4.1.1\n' > "$PUBSPEC"

# Stamps the run number as the build number.
bash "$SCRIPT" 42 "$PUBSPEC" >/dev/null
if ! grep -qx 'version: 4.1.1+42' "$PUBSPEC"; then
  echo "FAIL: expected 'version: 4.1.1+42', got:" >&2
  cat "$PUBSPEC" >&2
  exit 1
fi

# Other fields are left alone.
if ! grep -qx 'name: finar' "$PUBSPEC"; then
  echo "FAIL: stamping changed other pubspec fields" >&2
  exit 1
fi

# Re-stamping replaces an existing build number instead of appending.
bash "$SCRIPT" 7 "$PUBSPEC" >/dev/null
if ! grep -qx 'version: 4.1.1+7' "$PUBSPEC"; then
  echo "FAIL: re-stamp did not replace existing build number" >&2
  cat "$PUBSPEC" >&2
  exit 1
fi

# Missing or non-numeric build numbers fail.
if bash "$SCRIPT" >/dev/null 2>&1; then
  echo "FAIL: missing build number should fail" >&2
  exit 1
fi
if bash "$SCRIPT" abc "$PUBSPEC" >/dev/null 2>&1; then
  echo "FAIL: non-numeric build number should fail" >&2
  exit 1
fi

# A pubspec without a version field fails.
printf 'name: finar\n' > "$PUBSPEC"
if bash "$SCRIPT" 3 "$PUBSPEC" >/dev/null 2>&1; then
  echo "FAIL: pubspec without version should fail" >&2
  exit 1
fi

echo "set-ci-version.sh test passed"
