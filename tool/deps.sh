#!/usr/bin/env bash
# Local parity for .github/workflows/deps-audit.yml — osv-scanner over
# pubspec.lock, pinned to the same version+sha256 as CI.
# Usage:
#   tool/deps.sh           # default: fetch the pinned scanner if needed, scan
#   tool/deps.sh --offline # never touch the network; skip if scanner missing
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

OSV_SCANNER_VERSION="2.7.0"
OSV_SCANNER_SHA256="160c6253e2922e9e0a6a9771c5c4c40a4b3c6090b34a3cdd5e80c96cc2e4218b"

# Toolchain cache: out of the repo, per user (repo uses mise for other tools;
# osv-scanner is fetched as a pinned static binary because no mise dep fits).
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sudoku-deps"

if command -v osv-scanner >/dev/null 2>&1; then
  scanner="osv-scanner"
elif [ -x "$CACHE_DIR/osv-scanner" ]; then
  scanner="$CACHE_DIR/osv-scanner"
elif [ "${1:-}" = "--offline" ]; then
  echo "deps: --offline set and no scanner cached — skipping network fetch, no audit ran."
  exit 0
else
  mkdir -p "$CACHE_DIR"
  url="https://github.com/google/osv-scanner/releases/download/v${OSV_SCANNER_VERSION}/osv-scanner_linux_amd64"
  scratch="$(mktemp -d)"
  trap 'rm -rf "$scratch"' EXIT
  echo "deps: fetching osv-scanner v${OSV_SCANNER_VERSION} (sha256-pinned)"
  curl -fsSL "$url" -o "$scratch/osv-scanner"
  printf '%s  %s\n' "$OSV_SCANNER_SHA256" "$scratch/osv-scanner" | sha256sum -c - >/dev/null
  chmod +x "$scratch/osv-scanner"
  mv "$scratch/osv-scanner" "$CACHE_DIR/osv-scanner"
  scanner="$CACHE_DIR/osv-scanner"
fi

if [ ! -f pubspec.lock ]; then
  echo "deps: pubspec.lock missing — run flutter pub get and commit it." >&2
  exit 1
fi

echo "deps: osv-scanner scan --lockfile=pubspec.lock ."
status=0
"$scanner" scan --lockfile=pubspec.lock "$PWD" || status=$?
case "$status" in
  0)
    echo "deps: no known vulnerabilities in pubspec.lock";;
  1)
    echo "deps: patch hint — upgrade each package to the FIXED version from the table above (flutter pub upgrade <pkg>), then re-run." >&2
    exit 1;;
  *)
    exit "$status";;
esac
