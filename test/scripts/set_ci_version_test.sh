#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/pubspec.yaml" <<'YAML'
name: finar
version: 6.0.0
YAML

bash ../../scripts/set-ci-version.sh 42 "$tmp/pubspec.yaml" >/dev/null
grep -q '^version: 6.0.0+42' "$tmp/pubspec.yaml" || {
  echo "FAIL: version not stamped"
  exit 1
}

if bash ../../scripts/set-ci-version.sh abc "$tmp/pubspec.yaml" 2>/dev/null; then
  echo "FAIL: non-numeric build number accepted"
  exit 1
fi

if bash ../../scripts/set-ci-version.sh 42 "$tmp/missing.yaml" 2>/dev/null; then
  echo "FAIL: missing pubspec accepted"
  exit 1
fi

echo "ok set-ci-version"
