#!/bin/sh
# Binary-only mfw install: resolve the latest version, download + SHA-256-verify
# the asset for this platform, install it to ~/.local/bin/mfw, and STOP — it does
# NOT run `mfw fixup`.
#
# This is a trimmed mirror of the published install.sh (curl|sh). The skill uses
# it when the user's shell rc files are *managed* (symlinked into nix /
# home-manager / chezmoi / stow): the bundled `mfw fixup --yes` would atomically
# replace a symlinked rc with a regular file and clobber the managed config, so
# we install the binary here and drive fixup deliberately afterward.
#
# Same env overrides as install.sh:
#   MFW_BACKEND_URL  backend host (default https://semgrep.dev)
#   MFW_DIST_URL     full dist base URL (wins over MFW_BACKEND_URL)
#   MFW_INSTALL_DIR  install dir (default ~/.local/bin)
set -eu

BACKEND_URL="${MFW_BACKEND_URL:-https://semgrep.dev}"
DIST_URL="${MFW_DIST_URL:-$BACKEND_URL/dist/mfw}"
INSTALL_DIR="${MFW_INSTALL_DIR:-$HOME/.local/bin}"

tmp=""
cleanup() { [ -n "$tmp" ] && rm -rf "$tmp"; }
trap cleanup EXIT

err() {
	echo "mfw-install: $*" >&2
	exit 1
}

os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
Linux)
	case "$arch" in
	x86_64 | amd64) platform_tag="linux_x86_64" ;;
	aarch64 | arm64) platform_tag="linux_aarch64" ;;
	*) err "unsupported Linux architecture: $arch" ;;
	esac
	;;
Darwin)
	case "$arch" in
	arm64 | aarch64) platform_tag="macosx_11_0_arm64" ;;
	x86_64) err "no x86_64 macOS build is published; mfw requires Apple silicon" ;;
	*) err "unsupported macOS architecture: $arch" ;;
	esac
	;;
*) err "unsupported OS: $os (the installer supports Linux x86_64/aarch64 and Apple-silicon macOS)" ;;
esac

if command -v curl >/dev/null 2>&1; then
	download() { curl -fsSL "$1" -o "$2"; }
	download_stdout() { curl -fsSL "$1"; }
elif command -v wget >/dev/null 2>&1; then
	download() { wget -qO "$2" "$1"; }
	download_stdout() { wget -qO- "$1"; }
else
	err "need curl or wget to download mfw"
fi

VERSION="$(download_stdout "$DIST_URL/LATEST" | tr -d '[:space:]')"
[ -n "$VERSION" ] || err "could not resolve the latest version from $DIST_URL/LATEST"
asset="mfw-$VERSION-$platform_tag"

if [ -x "$INSTALL_DIR/mfw" ]; then
	installed="$("$INSTALL_DIR/mfw" --version 2>/dev/null | awk '{print $2}')" || installed=""
	if [ "$installed" = "$VERSION" ]; then
		echo "mfw $VERSION already installed at $INSTALL_DIR/mfw (no fixup run)"
		exit 0
	fi
fi

tmp="$(mktemp -d)"
download "$DIST_URL/$asset" "$tmp/$asset"
download "$DIST_URL/SHA256SUMS" "$tmp/SHA256SUMS"

grep -E "  ${asset}\$" "$tmp/SHA256SUMS" >"$tmp/SHA256SUMS.one" || true
[ -s "$tmp/SHA256SUMS.one" ] || err "no SHA256SUMS entry for $asset at $DIST_URL"
(
	cd "$tmp"
	if [ "$os" = "Darwin" ]; then
		shasum -a 256 -c SHA256SUMS.one
	else
		sha256sum -c SHA256SUMS.one
	fi
) || err "checksum verification failed for $asset"

mkdir -p "$INSTALL_DIR"
mv "$tmp/$asset" "$INSTALL_DIR/mfw"
chmod +x "$INSTALL_DIR/mfw"
echo "installed mfw $VERSION to $INSTALL_DIR/mfw (no fixup run)"

case ":$PATH:" in
*":$INSTALL_DIR:"*) ;;
*) echo "note: $INSTALL_DIR is not on your PATH yet" ;;
esac
