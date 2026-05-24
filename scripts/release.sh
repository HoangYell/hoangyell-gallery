#!/usr/bin/env bash
#
# scripts/release.sh — local end-to-end release for @hoangyell/gallery
#
# Pipeline:
#   pre-flight  → bump versions → typecheck → dry-run publish → commit + tag
#   → npm publish (using your local `npm login` session)
#   → push commit + tag to GitHub
#
# Local-only design: no CI, no NPM_TOKEN, no GitHub secrets. Uses whatever
# npm account you authenticated with via `npm login`.
#
# Usage:
#   ./scripts/release.sh                # auto-bump patch (default)
#   ./scripts/release.sh patch          # auto-bump patch
#   ./scripts/release.sh minor          # auto-bump minor
#   ./scripts/release.sh major          # auto-bump major
#   ./scripts/release.sh 1.0.3          # explicit version
#   ./scripts/release.sh v1.0.3         # leading 'v' is stripped
#
# If your npm account requires 2FA for publish, pass OTP via env:
#   OTP=123456 ./scripts/release.sh

# -E makes the ERR trap inherit into subshells, so the rollback fires
# even if `npm publish` is invoked in a `(...)` group or pipeline.
set -Eeuo pipefail

# ── pretty output ─────────────────────────────────────────────────────────
c_cyan='\033[36m'; c_green='\033[32m'; c_red='\033[31m'; c_dim='\033[2m'; c_off='\033[0m'
log() { printf "${c_cyan}›${c_off} %s\n" "$*"; }
ok()  { printf "${c_green}✓${c_off} %s\n" "$*"; }
err() { printf "${c_red}✗${c_off} %s\n" "$*" >&2; }
dim() { printf "${c_dim}%s${c_off}\n" "$*"; }

PACKAGE_NAME="@hoangyell/gallery"
PACKAGE_DIR="packages/astro"
REMOTE="origin"
BRANCH="main"

# ── 1) parse args (auto-bump or explicit semver) ──────────────────────────
# Compute the next version from current root package.json + a bump kind.
bump_version() {
  local current="$1" kind="$2"
  node -e "
    const [maj, min, pat] = process.argv[1].split('.').map(Number);
    const kind = process.argv[2];
    if (kind === 'major') console.log(\`\${maj + 1}.0.0\`);
    else if (kind === 'minor') console.log(\`\${maj}.\${min + 1}.0\`);
    else console.log(\`\${maj}.\${min}.\${pat + 1}\`);
  " "$current" "$kind"
}

cd "$(git rev-parse --show-toplevel)"
CURRENT_VERSION="$(node -p "require('./$PACKAGE_DIR/package.json').version")"

ARG="${1:-patch}"
case "$ARG" in
  patch|minor|major)
    VERSION="$(bump_version "$CURRENT_VERSION" "$ARG")"
    ;;
  *)
    VERSION="${ARG#v}"
    if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
      err "'$ARG' is not 'patch|minor|major' or valid semver (e.g. 1.0.3, 1.0.3-beta.1)"
      exit 1
    fi
    ;;
esac

echo
dim "  current:  $CURRENT_VERSION"
dim "  next:     $VERSION"
echo

# ── 2) pre-flight checks ──────────────────────────────────────────────────
log "Pre-flight checks for v$VERSION"

if [[ -n "$(git status --porcelain)" ]]; then
  err "Working tree is not clean. Commit or stash changes first."
  git status --short
  exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
  err "Not on '$BRANCH' (current: '$CURRENT_BRANCH'). Releases must come from $BRANCH."
  exit 1
fi

for cmd in pnpm npm git node; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "$cmd is not installed or not on PATH."
    exit 1
  fi
done

if ! npm whoami >/dev/null 2>&1; then
  err "You are not logged into npm. Run: npm login"
  exit 1
fi
NPM_USER="$(npm whoami)"
ok "npm user: $NPM_USER"

if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  err "Git tag v$VERSION already exists locally. Delete with: git tag -d v$VERSION"
  exit 1
fi

if git ls-remote --tags "$REMOTE" "refs/tags/v$VERSION" | grep -q .; then
  err "Git tag v$VERSION already exists on $REMOTE."
  exit 1
fi

if npm view "$PACKAGE_NAME@$VERSION" version >/dev/null 2>&1; then
  err "$PACKAGE_NAME@$VERSION is already published on npm."
  exit 1
fi

ok "All pre-flight checks passed"

# ── 3) bump versions ──────────────────────────────────────────────────────
log "Bumping package.json versions to $VERSION"
pnpm version "$VERSION" --no-git-tag-version >/dev/null
(cd "$PACKAGE_DIR" && pnpm version "$VERSION" --no-git-tag-version >/dev/null)
ok "Versions bumped"

# ── 4) refresh lockfile ───────────────────────────────────────────────────
log "Refreshing pnpm lockfile"
pnpm install --no-frozen-lockfile >/dev/null
ok "Lockfile in sync"

# ── 5) typecheck ──────────────────────────────────────────────────────────
log "Typechecking $PACKAGE_NAME"
pnpm --filter "$PACKAGE_NAME" run typecheck >/dev/null
ok "Typecheck passed"

# ── 6) dry-run publish (catches perms before any commit) ──────────────────
log "Dry-run npm publish (validates auth + tarball)"
pnpm --dir "$PACKAGE_DIR" exec npm publish --dry-run --access public >/dev/null 2>&1
ok "Dry-run OK"

# ── 7) commit + tag locally ───────────────────────────────────────────────
log "Committing version bump and tagging v$VERSION"
git add -A
git commit -m "chore: release v$VERSION" >/dev/null
git tag -a "v$VERSION" -m "Release v$VERSION"
ok "Commit + tag created locally"

# Rollback only the commit + tag if npm publish fails.
# We do NOT push anything until after publish succeeds.
rollback() {
  err "Publish failed — rolling back local commit + tag"
  git tag -d "v$VERSION" >/dev/null 2>&1 || true
  git reset --hard HEAD~1 >/dev/null
  err "Rolled back to previous HEAD."
  err "If the error above was 'EOTP' (2FA required), re-run with:"
  echo "    OTP=<your-6-digit-code> ./scripts/release.sh ${ARG}"
  exit 1
}
trap rollback ERR

# ── 8) real npm publish ───────────────────────────────────────────────────
log "Publishing $PACKAGE_NAME@$VERSION to npm"
PUBLISH_ARGS=(--access public)
if [[ -n "${OTP:-}" ]]; then
  PUBLISH_ARGS+=(--otp "$OTP")
  dim "  using OTP from env"
fi
pnpm --dir "$PACKAGE_DIR" exec npm publish "${PUBLISH_ARGS[@]}"
ok "Published $PACKAGE_NAME@$VERSION to npm"

# Publish succeeded — disarm the rollback before touching remotes.
trap - ERR

# ── 9) push commit + tag to GitHub ────────────────────────────────────────
log "Pushing $BRANCH and v$VERSION to $REMOTE"
if ! git push "$REMOTE" "$BRANCH"; then
  err "git push of $BRANCH failed. The release IS on npm. Push manually when fixed:"
  echo "    git push $REMOTE $BRANCH"
  echo "    git push $REMOTE v$VERSION"
  exit 1
fi
if ! git push "$REMOTE" "v$VERSION"; then
  err "git push of tag v$VERSION failed. Push manually when fixed:"
  echo "    git push $REMOTE v$VERSION"
  exit 1
fi
ok "Pushed commit + tag to $REMOTE"

# ── done ──────────────────────────────────────────────────────────────────
echo
ok "Released v$VERSION"
dim "  npm:    https://www.npmjs.com/package/$PACKAGE_NAME/v/$VERSION"
dim "  tag:    https://github.com/HoangYell/hoangyell-gallery/releases/tag/v$VERSION"
dim "  commit: $(git rev-parse --short HEAD)"
