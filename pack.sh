#!/usr/bin/env bash
# Linux equivalent of pack.ps1: fetch the AdGuardHome binary and build the
# flashable module zip.
#
# Usage: ./pack.sh [arm64|armv7]   (default: arm64)

set -euo pipefail

ARCH="${1:-arm64}"
case "$ARCH" in
arm64 | armv7) ;;
*)
  echo "Unsupported arch: $ARCH (expected arm64 or armv7)" >&2
  exit 1
  ;;
esac

cd "$(dirname "$0")"

CACHE_DIR="cache"
ARCHIVE="$CACHE_DIR/AdGuardHome_linux_$ARCH.tar.gz"
URL="https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_$ARCH.tar.gz"
OUT="AdGuardHomeForRoot_$ARCH.zip"

mkdir -p "$CACHE_DIR"

if [ ! -f "$ARCHIVE" ]; then
  echo "==> Downloading AdGuardHome ($ARCH)"
  curl -fL "$URL" -o "$ARCHIVE"
else
  echo "==> Using cached $ARCHIVE"
fi

if [ ! -d "$CACHE_DIR/$ARCH" ]; then
  echo "==> Extracting"
  mkdir -p "$CACHE_DIR/$ARCH"
  tar -xzf "$ARCHIVE" -C "$CACHE_DIR/$ARCH"
fi

echo "==> Staging module files"
rm -rf staging
mkdir -p staging
cp -a src/. staging/
cp "$CACHE_DIR/$ARCH/AdGuardHome/AdGuardHome" staging/bin/AdGuardHome

echo "==> Building $OUT"
rm -f "$OUT"
(cd staging && zip -qr "../$OUT" .)
rm -rf staging

echo "==> Built $OUT ($(du -h "$OUT" | cut -f1))"
