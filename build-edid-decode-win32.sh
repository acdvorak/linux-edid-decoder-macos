#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "error: this script is intended for a Linux host." >&2
  exit 1
fi

if ! command -v meson >/dev/null 2>&1; then
  echo "error: meson is required but not found in PATH." >&2
  exit 1
fi

find_toolchain_prefix() {
  local prefix
  for prefix in "$@"; do
    if command -v "${prefix}-gcc" >/dev/null 2>&1; then
      echo "$prefix"
      return 0
    fi
  done
  return 1
}

make_cross_file() {
  local cross_file="$1"
  local prefix="$2"
  local cpu_family="$3"
  local cpu="$4"

  cat >"$cross_file" <<EOF
[binaries]
c = '${prefix}-gcc'
cpp = '${prefix}-g++'
ar = '${prefix}-ar'
strip = '${prefix}-strip'

[host_machine]
system = 'windows'
cpu_family = '${cpu_family}'
cpu = '${cpu}'
endian = 'little'
EOF

  if command -v "${prefix}-pkg-config" >/dev/null 2>&1; then
    printf "pkgconfig = '%s-pkg-config'\n" "$prefix" >>"$cross_file"
  fi

  if command -v "wine" >/dev/null 2>&1; then
    printf "exe_wrapper = 'wine'\n" >>"$cross_file"
  elif command -v "wine64" >/dev/null 2>&1; then
    printf "exe_wrapper = 'wine64'\n" >>"$cross_file"
  fi
}

build_arch() {
  local arch_name="$1"
  local prefix="$2"
  local cpu_family="$3"
  local cpu="$4"
  local builddir="builddir-win32-${arch_name}"
  local cross_file="${builddir}.cross"

  make_cross_file "$cross_file" "$prefix" "$cpu_family" "$cpu"

  echo "==> Configuring ${arch_name} build with ${prefix}"
  meson setup "$builddir" --wipe --cross-file "$cross_file"

  echo "==> Building edid-decode (${arch_name})"
  meson compile -C "$builddir" edid-decode

  local exe_path="${builddir}/utils/edid-decode/edid-decode.exe"
  if [[ -f "$exe_path" ]]; then
    echo "built: ${exe_path}"
  else
    echo "warning: build finished but expected binary not found at ${exe_path}" >&2
  fi
}

x86_prefix="$(find_toolchain_prefix x86_64-w64-mingw32)" || {
  echo "error: could not find x86_64 MinGW toolchain (expected x86_64-w64-mingw32-gcc)." >&2
  exit 1
}

build_arch "x86_64" "$x86_prefix" "x86_64" "x86_64"

arm64_prefix=""
if arm64_prefix="$(find_toolchain_prefix aarch64-w64-mingw32 aarch64-w64-mingw32ucrt)"; then
  build_arch "aarch64" "$arm64_prefix" "aarch64" "aarch64"
else
  echo "note: no Win32 ARM64 MinGW toolchain found; skipping aarch64 build." >&2
  echo "      looked for: aarch64-w64-mingw32-gcc, aarch64-w64-mingw32ucrt-gcc" >&2
fi
