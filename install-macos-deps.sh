#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install-macos-toolchain.sh

Installs dependencies required to run build-nix.sh on macOS.

Required Homebrew formulas:
  - meson
  - ninja
  - pkg-config
  - argp-standalone
  - gettext

Also ensures likely prerequisites:
  - Xcode Command Line Tools available (clang, make, SDK headers)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this installer is for macOS hosts only." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "error: Homebrew is required but was not found in PATH." >&2
  echo "Install Homebrew from: https://brew.sh" >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "error: Xcode Command Line Tools are required but not installed." >&2
  echo "Run: xcode-select --install" >&2
  exit 1
fi

BREW_PKGS=(
  meson
  ninja
  pkg-config
  argp-standalone
  gettext
)

echo "==> Updating Homebrew metadata"
brew update

echo "==> Installing required formulas"
brew install "${BREW_PKGS[@]}"

verify_tools() {
  local missing=0
  local required_tools=(
    meson
    ninja
    pkg-config
    clang
    clang++
  )

  local tool
  for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "error: required tool not found after install: $tool" >&2
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    exit 1
  fi
}

verify_brew_libs() {
  local argp_prefix gettext_prefix

  argp_prefix="$(brew --prefix argp-standalone)"
  gettext_prefix="$(brew --prefix gettext)"

  if [[ ! -f "$argp_prefix/lib/libargp.a" ]]; then
    echo "error: expected argp static library not found: $argp_prefix/lib/libargp.a" >&2
    exit 1
  fi

  if [[ ! -f "$gettext_prefix/include/libintl.h" ]]; then
    echo "error: expected gettext header not found: $gettext_prefix/include/libintl.h" >&2
    exit 1
  fi
}

verify_tools
verify_brew_libs

echo
echo "Done. Next step: run ./build-nix.sh"
