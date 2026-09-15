#!/usr/bin/env bash
# Build the Cribl pack archive (.crbl) for this repo.
#
# A .crbl is a gzipped tarball with the pack contents (package.json, default/,
# data/, README.md, ...) at the archive root. Output lands in dist/ along with a
# .sha256 checksum file.
#
# Usage: scripts/build-pack.sh [output-dir]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$ROOT/dist}"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 1
fi

NAME="$(jq -r .name "$ROOT/package.json")"
VERSION="$(jq -r .version "$ROOT/package.json")"
ARCHIVE="$OUT_DIR/${NAME}-${VERSION}.crbl"

mkdir -p "$OUT_DIR"
rm -f "$ARCHIVE" "$ARCHIVE.sha256"

# COPYFILE_DISABLE stops macOS tar from adding ._* AppleDouble entries.
COPYFILE_DISABLE=1 tar \
  --exclude='./.git' \
  --exclude='./.github' \
  --exclude='./.claude' \
  --exclude='./.gitignore' \
  --exclude='./dist' \
  --exclude='./scripts' \
  --exclude='.DS_Store' \
  --exclude='*.crbl' \
  -czf "$ARCHIVE" -C "$ROOT" .

# Sanity check: package.json must sit at the archive root.
if ! tar -tzf "$ARCHIVE" | grep -qx './package.json'; then
  echo "error: package.json missing from archive root" >&2
  exit 1
fi

(cd "$OUT_DIR" && shasum -a 256 "$(basename "$ARCHIVE")" > "$(basename "$ARCHIVE").sha256")

echo "built $ARCHIVE"
cat "$ARCHIVE.sha256"
