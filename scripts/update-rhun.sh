#!/usr/bin/env bash
set -euo pipefail

REPO="vshvedov/rhun"
FLAKE_FILE="flake.nix"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

cd "$PROJECT_ROOT"

echo "Fetching latest release from $REPO..."
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)

if [ -z "$LATEST_RELEASE" ]; then
  echo "Error: Could not fetch latest release"
  exit 1
fi

VERSION="${LATEST_RELEASE#v}"
echo "Latest release: $LATEST_RELEASE (version: $VERSION)"

CURRENT_VERSION=$(grep 'version = "' "$FLAKE_FILE" | head -1 | sed 's/.*version = "\([^"]*\)".*/\1/')
if [ "$VERSION" = "$CURRENT_VERSION" ]; then
  echo "Already at version $VERSION"
  exit 0
fi

echo "Updating $FLAKE_FILE from $CURRENT_VERSION to $VERSION..."
sed -i.bak "s|github:$REPO/v[^\"]*|github:$REPO/$LATEST_RELEASE|g" "$FLAKE_FILE"
sed -i.bak "s/version = \"[^\"]*\"/version = \"$VERSION\"/" "$FLAKE_FILE"
rm -f "$FLAKE_FILE.bak"

echo "Running nix flake update..."
nix flake update

# Builds, runs the upstream test suite, and checks `rhun --version`.
echo "Verifying build..."
nix build .#default -L

git add flake.nix flake.lock
git commit -m "chore: update rhun to $VERSION"

if [ "$DRY_RUN" = 1 ]; then
  echo "Dry run: not pushing"
else
  git push origin main
fi

echo "✓ Successfully updated rhun to $VERSION"
