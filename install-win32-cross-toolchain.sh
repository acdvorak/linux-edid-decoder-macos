#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install-win32-cross-toolchain.sh [--no-arm64]

Installs dependencies needed by build-edid-decode-win32.sh on Linux hosts.

Supported distributions:
  - Debian / Ubuntu (apt)
  - Fedora (dnf)

Options:
  --no-arm64      Skip Win32 ARM64 cross toolchain package checks/installs.
EOF
}

HOST_ARCH="$(uname -m)"
if [[ "$HOST_ARCH" == "aarch64" || "$HOST_ARCH" == "arm64" ]]; then
  WITH_ARM64=1
else
  WITH_ARM64=0
fi

while (($#)); do
  case "$1" in
    --no-arm64)
      WITH_ARM64=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

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

contains_word() {
  local haystack="$1"
  local needle="$2"
  [[ " $haystack " == *" $needle "* ]]
}

install_apt() {
  local -a base_pkgs=(
    meson
    ninja-build
    pkg-config
    mingw-w64
    gcc-mingw-w64-x86-64
    g++-mingw-w64-x86-64
    binutils-mingw-w64-x86-64
  )
  local -a arm_candidates=(
    gcc-mingw-w64-aarch64
    g++-mingw-w64-aarch64
    binutils-mingw-w64-aarch64
  )

  echo "==> Updating apt metadata"
  sudo apt-get update

  echo "==> Installing base packages (x86_64 Windows cross toolchain)"
  sudo apt-get install -y "${base_pkgs[@]}"

  if [[ "$WITH_ARM64" -eq 1 ]]; then
    local -a arm_found=()
    local pkg
    for pkg in "${arm_candidates[@]}"; do
      if apt-cache show "$pkg" >/dev/null 2>&1; then
        arm_found+=("$pkg")
      fi
    done

    if ((${#arm_found[@]} > 0)); then
      echo "==> Installing available ARM64-target packages"
      sudo apt-get install -y "${arm_found[@]}"
    else
      echo "note: no ARM64 MinGW packages found in current apt repositories." >&2
      echo "      x86_64 Windows cross-compilation is still installed and ready." >&2
    fi
  fi
}

install_dnf() {
  local -a base_pkgs=(
    meson
    ninja-build
    pkgconf-pkg-config
    mingw64-gcc
    mingw64-gcc-c++
    mingw64-binutils
  )
  local -a arm_candidates=(
    mingw64-aarch64-gcc
    mingw64-aarch64-gcc-c++
    mingw64-aarch64-binutils
  )

  echo "==> Installing base packages (x86_64 Windows cross toolchain)"
  sudo dnf install -y "${base_pkgs[@]}"

  if [[ "$WITH_ARM64" -eq 1 ]]; then
    local -a arm_found=()
    local pkg
    for pkg in "${arm_candidates[@]}"; do
      if dnf list --available "$pkg" >/dev/null 2>&1; then
        arm_found+=("$pkg")
      fi
    done

    if ((${#arm_found[@]} > 0)); then
      echo "==> Installing available ARM64-target packages"
      sudo dnf install -y "${arm_found[@]}"
    else
      echo "note: no ARM64 MinGW packages found in enabled dnf repositories." >&2
      echo "      x86_64 Windows cross-compilation is still installed and ready." >&2
    fi
  fi
}

if [[ "$DISTRO_ID" == "ubuntu" || "$DISTRO_ID" == "debian" ]] || contains_word "$DISTRO_LIKE" "debian"; then
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "error: expected apt-get, but it is not available." >&2
    exit 1
  fi
  install_apt
elif [[ "$DISTRO_ID" == "fedora" ]] || contains_word "$DISTRO_LIKE" "fedora" || contains_word "$DISTRO_LIKE" "rhel"; then
  if ! command -v dnf >/dev/null 2>&1; then
    echo "error: expected dnf, but it is not available." >&2
    exit 1
  fi
  install_dnf
else
  echo "error: unsupported distribution '$DISTRO_ID'." >&2
  echo "supported: Debian/Ubuntu (apt), Fedora (dnf)." >&2
  exit 1
fi

echo
echo "Done. Next step: run ./build-edid-decode-win32.sh"
