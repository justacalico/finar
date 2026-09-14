#!/bin/bash
set -euo pipefail

# Stamp pubspec.yaml with the CI run number as the build number so each run's
# artifacts report <version>+<run> (e.g. 4.1.1+42). The committed pubspec
# keeps the plain semantic version.

BUILD_NUMBER="${1:-}"
PUBSPEC="${2:-pubspec.yaml}"

if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "usage: set-ci-version.sh <build-number> [pubspec-path]" >&2
  exit 1
fi

if [ ! -f "$PUBSPEC" ]; then
  echo "$PUBSPEC not found" >&2
  exit 1
fi

VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: *//g' | cut -d'+' -f1 | tr -d '[:space:]')
if [ -z "$VERSION" ]; then
  echo "No version found in $PUBSPEC" >&2
  exit 1
fi

# Write via a temp file so this works with both GNU and BSD sed (macOS runners).
sed "s/^version:.*/version: ${VERSION}+${BUILD_NUMBER}/" "$PUBSPEC" > "$PUBSPEC.stamped"
mv "$PUBSPEC.stamped" "$PUBSPEC"

echo "Version set to ${VERSION}+${BUILD_NUMBER}"
