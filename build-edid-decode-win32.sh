#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./build-edid-decode-win32.sh [--no-arm64] [--shared-runtime]

Cross-compile edid-decode for Windows on a Linux host.

Options:
  --no-arm64       Skip Win32 ARM64 build attempt.
  --shared-runtime Disable static-runtime linking (may require MinGW DLLs at runtime).
EOF
}

HOST_ARCH="$(uname -m)"
if [[ "$HOST_ARCH" == "aarch64" || "$HOST_ARCH" == "arm64" ]]; then
  WITH_ARM64=1
else
  WITH_ARM64=0
fi

STATIC_RUNTIME=1

while (($#)); do
  case "$1" in
    --no-arm64)
      WITH_ARM64=0
      ;;
    --shared-runtime)
      STATIC_RUNTIME=0
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

  if [[ "$STATIC_RUNTIME" -eq 1 ]]; then
    cat >>"$cross_file" <<EOF

[properties]
c_link_args = ['-static', '-static-libgcc']
cpp_link_args = ['-static', '-static-libgcc', '-static-libstdc++']
EOF
  fi

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
  local builddir="build-win32-${arch_name}"
  local cross_file="${builddir}.cross"

  make_cross_file "$cross_file" "$prefix" "$cpu_family" "$cpu"

  echo "==> Configuring ${arch_name} build with ${prefix}"
  meson setup "$builddir" --wipe --cross-file "$cross_file"

  echo "==> Building edid-decode (${arch_name})"
  meson compile -C "$builddir" edid-decode

  local exe_path="${builddir}/utils/edid-decode/edid-decode.exe"
  if [[ -f "$exe_path" ]]; then
    echo "built: ${exe_path}"
    if command -v "${prefix}-objdump" >/dev/null 2>&1; then
      echo "==> Imported DLLs (${arch_name})"
      "${prefix}-objdump" -p "$exe_path" | grep 'DLL Name' || true
    fi
  else
    echo "warning: build finished but expected binary not found at ${exe_path}" >&2
  fi

  echo
  echo '-----------------------------------------------------------------------'
  echo
  printf '\033[1;32m%s\033[0m\n' "$exe_path"
  echo
  echo '-----------------------------------------------------------------------'
  echo
}

x86_prefix="$(find_toolchain_prefix x86_64-w64-mingw32)" || {
  echo "error: could not find x86_64 MinGW toolchain (expected x86_64-w64-mingw32-gcc)." >&2
  exit 1
}

if [[ "$STATIC_RUNTIME" -eq 1 ]]; then
  echo "==> Static-runtime mode enabled (portable build preference)"
else
  echo "==> Shared-runtime mode enabled (DLL runtimes may be required)"
fi

build_arch "x86_64" "$x86_prefix" "x86_64" "x86_64"

arm64_prefix=""
if [[ "$WITH_ARM64" -eq 1 ]] && arm64_prefix="$(find_toolchain_prefix aarch64-w64-mingw32 aarch64-w64-mingw32ucrt)"; then
  echo "==> ARM64 host/default detected; attempting Win32 ARM64 build"
  build_arch "aarch64" "$arm64_prefix" "aarch64" "aarch64"
elif [[ "$WITH_ARM64" -eq 1 ]]; then
  echo "note: ARM64 build is enabled, but no Win32 ARM64 MinGW toolchain was found; skipping." >&2
  echo "      looked for: aarch64-w64-mingw32-gcc, aarch64-w64-mingw32ucrt-gcc" >&2
else
  echo "==> ARM64 build disabled (non-ARM64 host default or --no-arm64)"
fi
