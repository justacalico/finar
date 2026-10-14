#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

RELEASE_TAG="${RELEASE_TAG:-}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"
PROJECT_DIR="${CI_PROJECT_DIR:-$PWD}"

cd "$PROJECT_DIR"

# Determine which GitHub release to sync.
if [ -z "$RELEASE_TAG" ]; then
  RELEASE_TAG=$(gh api "repos/justacalico/finar/releases?per_page=1" --jq '.[0].tag_name')
fi

echo "Syncing GitHub release: $RELEASE_TAG"

# Download assets from the GitHub release.
rm -rf release-assets SHA256SUMS.txt
mkdir -p release-assets
gh release download "$RELEASE_TAG" -R justacalico/finar --dir release-assets

# Fetch GitHub Actions job logs if a run ID was provided.
if [ -n "$GITHUB_RUN_ID" ]; then
  gh run view "$GITHUB_RUN_ID" -R justacalico/finar --log > github-logs.txt 2>/dev/null || true
  if [ -s github-logs.txt ]; then
    cp github-logs.txt release-assets/
  fi
fi

# Generate checksums.
cd release-assets
sha256sum * > "$PROJECT_DIR/SHA256SUMS.txt"
cd "$PROJECT_DIR"
cp SHA256SUMS.txt release-assets/

ls -la release-assets/

# Remove any stale GitLab release, tag and generic package so the
# package-registry upload does not collide with existing assets and the release
# is recreated at the current commit.
glab release delete "$RELEASE_TAG" -R "$CI_PROJECT_PATH" -y 2>/dev/null || true
PKG_ID=$(glab api "projects/$CI_PROJECT_ID/packages?package_name=release-assets&package_version=$RELEASE_TAG" 2>/dev/null | jq -r '.[0].id // empty')
if [ -n "$PKG_ID" ] && [ "$PKG_ID" != "null" ]; then
  glab api --method DELETE "projects/$CI_PROJECT_ID/packages/$PKG_ID" 2>/dev/null || true
fi

# Move the release tag to the commit the GitHub release tagged, so the tag
# matches on both hosts. The CI job token cannot modify tags, but a deploy key
# with write access can.
RELEASE_SHA=$(gh api "repos/justacalico/finar/git/ref/tags/$RELEASE_TAG" --jq '.object.sha' 2>/dev/null || true)
RELEASE_SHA="${RELEASE_SHA:-$CI_COMMIT_SHA}"
if [ -n "${GITLAB_RELEASE_SSH_KEY:-}" ]; then
  git remote add gitlab-ssh "git@gitlab.com:${CI_PROJECT_PATH}.git" 2>/dev/null || true
  git fetch --depth=1 gitlab-ssh "$RELEASE_TAG" 2>/dev/null || true
  git tag -f "$RELEASE_TAG" "$RELEASE_SHA"
  git push -f gitlab-ssh "$RELEASE_TAG"
fi

# Upload assets to the package registry before creating the release so it is
# never visible without files. --use-package-registry creates the release first
# and uploads afterwards, leaving it empty while the uploads run.
LINKS_FILE=$(mktemp)
echo '[]' > "$LINKS_FILE"
for asset in "$PROJECT_DIR/release-assets"/*; do
  ASSET_NAME="$(basename "$asset")"
  echo "Uploading $ASSET_NAME..."
  glab api --method PUT --input "$asset" \
    "projects/$CI_PROJECT_ID/packages/generic/release-assets/$RELEASE_TAG/$ASSET_NAME" > /dev/null
  jq --arg name "$ASSET_NAME" \
    --arg url "${CI_API_V4_URL:-https://gitlab.com/api/v4}/projects/$CI_PROJECT_ID/packages/generic/release-assets/$RELEASE_TAG/$ASSET_NAME" \
    '. += [{name: $name, url: $url, link_type: "other", direct_asset_path: ("/" + $name)}]' \
    "$LINKS_FILE" > "$LINKS_FILE.new"
  mv "$LINKS_FILE.new" "$LINKS_FILE"
done

# Mirror to a GitLab release. The tag is kept the same as GitHub.
# glab in CI will use CI_JOB_TOKEN when GLAB_ENABLE_CI_AUTOLOGIN is set.
glab release create "$RELEASE_TAG" \
  --name "Finar $RELEASE_TAG" \
  --notes "Mirrored from the GitHub release." \
  --ref "$RELEASE_SHA" \
  --assets-links "$(cat "$LINKS_FILE")"
rm -f "$LINKS_FILE"
