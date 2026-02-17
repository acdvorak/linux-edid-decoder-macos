#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# darwin, linux
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# arm64
ARCH=$(uname -m)

OUT_DIR="build-${OS}-${ARCH}"

meson setup "$OUT_DIR" --wipe
meson compile -C "$OUT_DIR" edid-decode

echo
echo "$OUT_DIR/utils/edid-decode/edid-decode"
