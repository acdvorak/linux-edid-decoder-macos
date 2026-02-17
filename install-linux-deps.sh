#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install-linux-deps.sh

Install dependencies required by build-nix.sh so Linux hosts can
build both x86_64 and aarch64 targets (native + cross where needed).

Supported distributions:
  - Debian / Ubuntu (apt)
  - Arch / Manjaro (pacman)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "error: this installer is for Linux hosts only." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "error: cannot detect distribution (/etc/os-release missing)." >&2
  exit 1
fi

. /etc/os-release
DISTRO_ID="${ID:-}"
DISTRO_LIKE="${ID_LIKE:-}"

normalize_arch() {
  case "$1" in
    aarch64|arm64)
      echo "aarch64"
      ;;
    x86_64|amd64)
      echo "x86_64"
      ;;
    *)
      echo "$1"
      ;;
  esac
}

contains_word() {
  local haystack="$1"
  local needle="$2"
  [[ " $haystack " == *" $needle "* ]]
}

HOST_ARCH="$(normalize_arch "$(uname -m)")"
if [[ "$HOST_ARCH" != "x86_64" && "$HOST_ARCH" != "aarch64" ]]; then
  echo "error: unsupported host architecture '$HOST_ARCH'." >&2
  echo "supported hosts: x86_64 and aarch64." >&2
  exit 1
fi

APT_COMMON_PKGS=(
  meson
  ninja-build
  pkg-config
  build-essential
)

PACMAN_COMMON_PKGS=(
  base-devel
  meson
  ninja
  pkgconf
)

if [[ "$HOST_ARCH" == "x86_64" ]]; then
  REQUIRED_CROSS_PREFIX="aarch64-linux-gnu"
  APT_CROSS_PKGS=(
    gcc-aarch64-linux-gnu
    g++-aarch64-linux-gnu
    binutils-aarch64-linux-gnu
  )
  PACMAN_CROSS_PKGS=(
    aarch64-linux-gnu-gcc
    aarch64-linux-gnu-binutils
  )
else
  REQUIRED_CROSS_PREFIX="x86_64-linux-gnu"
  APT_CROSS_PKGS=(
    gcc-x86-64-linux-gnu
    g++-x86-64-linux-gnu
    binutils-x86-64-linux-gnu
  )
  PACMAN_CROSS_PKGS=(
    x86_64-linux-gnu-gcc
    x86_64-linux-gnu-binutils
  )
fi

install_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "error: expected apt-get, but it is not available." >&2
    exit 1
  fi

  echo "==> Updating apt metadata"
  sudo apt-get update

  echo "==> Installing native build dependencies"
  sudo apt-get install -y "${APT_COMMON_PKGS[@]}"

  echo "==> Installing Linux cross toolchain (${REQUIRED_CROSS_PREFIX})"
  sudo apt-get install -y "${APT_CROSS_PKGS[@]}"
}

install_pacman() {
  if ! command -v pacman >/dev/null 2>&1; then
    echo "error: expected pacman, but it is not available." >&2
    exit 1
  fi

  echo "==> Syncing package databases"
  sudo pacman -Sy --noconfirm

  echo "==> Installing native build dependencies"
  sudo pacman -S --needed --noconfirm "${PACMAN_COMMON_PKGS[@]}"

  echo "==> Installing Linux cross toolchain (${REQUIRED_CROSS_PREFIX})"
  sudo pacman -S --needed --noconfirm "${PACMAN_CROSS_PKGS[@]}"
}

verify_tools() {
  local missing=0

  local required_tools=(
    meson
    ninja
    gcc
    g++
    "${REQUIRED_CROSS_PREFIX}-gcc"
    "${REQUIRED_CROSS_PREFIX}-g++"
  )

  local tool
  for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "error: required tool not found after install: $tool" >&2
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    if command -v pacman >/dev/null 2>&1; then
      echo "hint: on some Arch-like distros, prefixed cross C++ tools may come from AUR packages." >&2
    fi
    exit 1
  fi
}

if [[ "$DISTRO_ID" == "ubuntu" || "$DISTRO_ID" == "debian" ]] || contains_word "$DISTRO_LIKE" "debian"; then
  install_apt
elif [[ "$DISTRO_ID" == "arch" || "$DISTRO_ID" == "manjaro" ]] || contains_word "$DISTRO_LIKE" "arch"; then
  install_pacman
else
  echo "error: unsupported distribution '$DISTRO_ID'." >&2
  echo "supported: Debian/Ubuntu (apt), Arch/Manjaro (pacman)." >&2
  exit 1
fi

verify_tools

echo
echo "Done. Next step: run ./build-nix.sh"
