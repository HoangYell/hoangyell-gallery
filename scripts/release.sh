#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
  echo "Usage: pnpm run release <version>"
  echo "Example: pnpm run release 1.0.0"
  exit 1
fi

VERSION=$1
VERSION=${VERSION#v}

echo "Preparing release for v$VERSION..."

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Working tree is not clean."
  exit 1
fi

echo "Updating package.json versions..."
pnpm version "$VERSION" --no-git-tag-version

if [ -f "packages/astro/package.json" ]; then
  (cd packages/astro && pnpm version "$VERSION" --no-git-tag-version)
fi

echo "Updating lockfile..."
pnpm install --no-frozen-lockfile > /dev/null

echo "Committing version bump..."
git commit -am "chore: release v$VERSION"

echo "Tagging v$VERSION..."
git tag "v$VERSION"

echo "Pushing to GitHub..."
git push origin main
git push origin "v$VERSION"

echo "Done! GitHub Actions will publish @hoangyell/gallery to npm."
