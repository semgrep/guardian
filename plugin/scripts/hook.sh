#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"

case "$OSTYPE" in
  darwin*)
    case "$HOSTTYPE" in
      arm64) exec "$DIR/hook-darwin-arm64" "$@" ;;
      aarch64) exec "$DIR/hook-darwin-arm64" "$@" ;;
      *)     exec "$DIR/hook-darwin-amd64" "$@" ;;
    esac ;;
  linux*)
    case "$HOSTTYPE" in
      aarch64) exec "$DIR/hook-linux-arm64" "$@" ;;
      *)       exec "$DIR/hook-linux-amd64" "$@" ;;
    esac ;;
  msys*|cygwin*)
    exec "$DIR/hook-windows-amd64.exe" "$@" ;;
  *)
    echo "unsupported platform: OSTYPE=$OSTYPE" >&2
    exit 2 ;;
esac
