#!/usr/bin/env bash
# Stamps this fork's identity onto a staged module tree, and optionally writes
# the update manifest the module points at.
#
# Why this is a build step instead of a committed patch: every upstream release
# rewrites src/module.prop and version.json to bump the version. Those are
# exactly the fields a fork wants to change, so carrying them as a diff means a
# conflict on every single sync. Leaving both files byte-identical to upstream
# in git and rewriting them here keeps the rebase clean forever.
#
# Usage: ./fork-brand.sh <staging-dir> [version] [manifest-out]

set -euo pipefail

STAGING="${1:?usage: fork-brand.sh <staging-dir> [version] [manifest-out]}"
VERSION="${2:-$(date -u +%Y%m%d)}"
MANIFEST_OUT="${3:-}"

FORK_NAME="AdGuardHome for Root (Aliyerki)"
FORK_AUTHOR="twoone3, Aliyerki"
FORK_REPO="Aliyerki/AdGuardHomeForRoot"
# A file upstream does not have, so syncing never touches it. Served raw rather
# than through /releases/latest/download so the root manager gets a plain 200
# instead of a redirect.
MANIFEST_URL="https://raw.githubusercontent.com/$FORK_REPO/main/fork-version.json"

if [[ ! "$VERSION" =~ ^[0-9]{8}$ ]]; then
  echo "Version must be an 8-digit date (YYYYMMDD), got: $VERSION" >&2
  exit 1
fi

# The date doubles as the versionCode: it only has to be monotonic and only the
# fork's own releases are ever compared against it, so upstream renumbering
# (52, 53, ...) can never collide with it.
VERSION_CODE="$VERSION"

PROP="$STAGING/module.prop"
[ -f "$PROP" ] || { echo "No module.prop in $STAGING" >&2; exit 1; }

sed -i \
  -e "s|^name=.*|name=$FORK_NAME|" \
  -e "s|^version=.*|version=$VERSION|" \
  -e "s|^versionCode=.*|versionCode=$VERSION_CODE|" \
  -e "s|^author=.*|author=$FORK_AUTHOR|" \
  -e "s|^updateJson=.*|updateJson=$MANIFEST_URL|" \
  "$PROP"

# A silently unbranded build would keep pulling updates from upstream, so fail
# loudly if any key was missing from module.prop rather than absent-mindedly
# shipping it.
for key in name version versionCode author updateJson; do
  grep -q "^$key=" "$PROP" || { echo "module.prop has no $key= line" >&2; exit 1; }
done

echo "==> Branded $PROP as $FORK_NAME $VERSION"

if [ -n "$MANIFEST_OUT" ]; then
  cat >"$MANIFEST_OUT" <<JSON
{
  "versionCode": $VERSION_CODE,
  "version": "$VERSION",
  "zipUrl": "https://github.com/$FORK_REPO/releases/download/$VERSION/AdGuardHomeForRoot_arm64.zip",
  "changelog": "https://raw.githubusercontent.com/$FORK_REPO/main/changelog.md"
}
JSON
  echo "==> Wrote $MANIFEST_OUT"
fi
