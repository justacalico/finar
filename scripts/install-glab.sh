#!/usr/bin/env bash
set -euo pipefail

# Download and install the GitLab CLI when it is not already available.

if command -v glab >/dev/null 2>&1; then
  glab --version | head -n 1
  exit 0
fi

GLAB_VERSION="${GLAB_VERSION:-1.113.0}"
ARCH="${CI_RUNNER_ARCH:-amd64}"

case "$ARCH" in
  arm|armv7l) ARCH="armv6" ;;
  aarch64|arm64) ARCH="arm64" ;;
  386|i386) ARCH="386" ;;
esac

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

download() {
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import urllib.request; urllib.request.urlretrieve('$url', '$dest')"
  else
    echo "Need curl, wget, or python3 to download $url" >&2
    exit 1
  fi
}

download "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_${ARCH}.tar.gz" /tmp/glab.tar.gz
tar -xzf /tmp/glab.tar.gz -C /tmp --strip-components=1
cp /tmp/glab "$BIN_DIR/glab"
chmod +x "$BIN_DIR/glab"
glab --version | head -n 1
