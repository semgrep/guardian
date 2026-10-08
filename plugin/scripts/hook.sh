#!/bin/bash

set -u -e -o pipefail

DIR="$(dirname "$0")"
DIR="$(cd "$DIR" && pwd)"

if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
  exec "$DIR/hook.exe" "$@"
fi

case "${OSTYPE:-}" in
  darwin*)
    case "${HOSTTYPE:-}" in
      arm64) exec "$DIR/hook-darwin-arm64" "$@" ;;
      aarch64) exec "$DIR/hook-darwin-arm64" "$@" ;;
      *)     exec "$DIR/hook-darwin-amd64" "$@" ;;
    esac ;;
  linux*)
    case "${HOSTTYPE:-}" in
      aarch64) exec "$DIR/hook-linux-arm64" "$@" ;;
      *)       exec "$DIR/hook-linux-amd64" "$@" ;;
    esac ;;
  msys*|cygwin*)
    exec "$DIR/hook.exe" "$@" ;;
  *)
    echo "unsupported platform: OSTYPE=${OSTYPE:-}" >&2
    exit 2 ;;
esac
