#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# darwin, linux
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

HOST_ARCH=$(uname -m)

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

HOST_ARCH="$(normalize_arch "$HOST_ARCH")"

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

make_linux_cross_file() {
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
system = 'linux'
cpu_family = '${cpu_family}'
cpu = '${cpu}'
endian = 'little'
EOF

	if command -v "${prefix}-pkg-config" >/dev/null 2>&1; then
		printf "pkgconfig = '%s-pkg-config'\n" "$prefix" >>"$cross_file"
	fi
}

build_native() {
	local target_arch="$1"
	local out_dir="build-${OS}-${target_arch}"

	echo "==> Configuring native ${OS}/${target_arch} build"
	meson setup "$out_dir" "${MESON_SETUP_ARGS[@]}"

	echo "==> Building edid-decode (${target_arch})"
	meson compile -C "$out_dir" edid-decode

	echo
	echo '-----------------------------------------------------------------------'
	echo
	printf '\033[1;32m%s\033[0m\n' "$out_dir/utils/edid-decode/edid-decode"
	echo
}

build_cross_linux() {
	local target_arch="$1"
	local prefix="$2"
	local cpu_family="$3"
	local cpu="$4"
	local out_dir="build-${OS}-${target_arch}"
	local cross_file="${out_dir}.cross"

	make_linux_cross_file "$cross_file" "$prefix" "$cpu_family" "$cpu"

	echo "==> Configuring cross ${OS}/${target_arch} build with ${prefix}"
	meson setup "$out_dir" "${MESON_SETUP_ARGS[@]}" --cross-file "$cross_file"

	echo "==> Building edid-decode (${target_arch})"
	meson compile -C "$out_dir" edid-decode

	echo
	echo '-----------------------------------------------------------------------'
	echo
	printf '\033[1;32m%s\033[0m\n' "$out_dir/utils/edid-decode/edid-decode"
	echo
}

if [[ "$OS" == "linux" ]]; then
	if [[ "$HOST_ARCH" == "x86_64" ]]; then
		build_native "x86_64"

		if arm64_prefix="$(find_toolchain_prefix aarch64-linux-gnu)"; then
			build_cross_linux "aarch64" "$arm64_prefix" "aarch64" "aarch64"
		else
			echo "warning: no ARM64 Linux cross toolchain found; skipping aarch64 build." >&2
			echo "         expected compiler like: aarch64-linux-gnu-gcc" >&2
		fi
	elif [[ "$HOST_ARCH" == "aarch64" ]]; then
		build_native "aarch64"

		if x86_prefix="$(find_toolchain_prefix x86_64-linux-gnu)"; then
			build_cross_linux "x86_64" "$x86_prefix" "x86_64" "x86_64"
		else
			echo "warning: no x86_64 Linux cross toolchain found; skipping x86_64 build." >&2
			echo "         expected compiler like: x86_64-linux-gnu-gcc" >&2
		fi
	else
		echo "error: unsupported Linux host architecture: ${HOST_ARCH}" >&2
		exit 1
	fi
else
	OUT_DIR="build-${OS}-${HOST_ARCH}"
	meson setup "$OUT_DIR" "${MESON_SETUP_ARGS[@]}"
	meson compile -C "$OUT_DIR" edid-decode

	echo
	echo '-----------------------------------------------------------------------'
	echo
	printf '\033[1;32m%s\033[0m\n' "$OUT_DIR/utils/edid-decode/edid-decode"
	echo
fi
