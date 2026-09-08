#!/usr/bin/env bash
set -euo pipefail

# Install the CLIs needed by the release pipeline on a shell runner.
# Everything lands in $HOME/.local/bin so no package manager or sudo is needed.

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

install_jq() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  download "https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux64" "$BIN_DIR/jq"
  chmod +x "$BIN_DIR/jq"
}

install_gh() {
  if command -v gh >/dev/null 2>&1; then
    return 0
  fi
  local version="2.97.0"
  local arch="amd64"
  download "https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_${arch}.tar.gz" /tmp/gh.tar.gz
  tar -xzf /tmp/gh.tar.gz -C /tmp
  cp "/tmp/gh_${version}_linux_${arch}/bin/gh" "$BIN_DIR/gh"
  chmod +x "$BIN_DIR/gh"
}

install_glab() {
  if command -v glab >/dev/null 2>&1; then
    return 0
  fi
  local version="${GLAB_VERSION:-1.113.0}"
  local arch="${CI_RUNNER_ARCH:-amd64}"
  case "$arch" in
    arm|armv7l) arch="armv6" ;;
    aarch64|arm64) arch="arm64" ;;
    386|i386) arch="386" ;;
  esac
  download "https://gitlab.com/gitlab-org/cli/-/releases/v${version}/downloads/glab_${version}_linux_${arch}.tar.gz" /tmp/glab.tar.gz
  tar -xzf /tmp/glab.tar.gz -C /tmp --strip-components=1
  cp /tmp/glab "$BIN_DIR/glab"
  chmod +x "$BIN_DIR/glab"
}

install_jq
install_gh
install_glab
