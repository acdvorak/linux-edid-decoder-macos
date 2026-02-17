#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# darwin, linux
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# arm64
ARCH=$(uname -m)

OUT_DIR="build-${OS}-${ARCH}"

MESON_SETUP_ARGS=(
	--wipe
)

if [[ "$OS" == "linux" ]]; then
	MESON_SETUP_ARGS+=(
		-Ddefault_library=static
		-Dedid-decode-static=true
	)
elif [[ "$OS" == "darwin" ]]; then
	echo "note: fully-static binaries are not supported by the macOS system toolchain; building default binary." >&2
fi

meson setup "$OUT_DIR" "${MESON_SETUP_ARGS[@]}"
meson compile -C "$OUT_DIR" edid-decode

echo
echo '-----------------------------------------------------------------------'
echo
printf '\033[1;32m%s\033[0m\n' "$OUT_DIR/utils/edid-decode/edid-decode"
echo
