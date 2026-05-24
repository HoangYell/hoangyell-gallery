#!/usr/bin/env bash
#
# scripts/deploy-pages.sh — build + deploy gallery.hoangyell.com to
# Cloudflare Pages under the account selected by `wrangler login`.
#
# Account: Ngohoang.yell@gmail.com's Account (3b36a5c51daee9566d07c97a0c78c887)
# Project: hoangyell-gallery
# Domain:  https://gallery.hoangyell.com
#
# First-time setup:
#   1. wrangler login                        # one-time browser OAuth
#   2. ./scripts/deploy-pages.sh             # build + deploy
#   3. (optional, one-time) add the custom domain via the dashboard:
#        https://dash.cloudflare.com/?to=/:account/pages/view/hoangyell-gallery/domains
#      then click "Set up a custom domain" → "gallery.hoangyell.com"
#
# Day-to-day:
#   ./scripts/deploy-pages.sh                # ship the latest dist/

set -Eeuo pipefail

c_cyan='\033[36m'; c_green='\033[32m'; c_red='\033[31m'; c_dim='\033[2m'; c_off='\033[0m'
log() { printf "${c_cyan}›${c_off} %s\n" "$*"; }
ok()  { printf "${c_green}✓${c_off} %s\n" "$*"; }
err() { printf "${c_red}✗${c_off} %s\n" "$*" >&2; }
dim() { printf "${c_dim}%s${c_off}\n" "$*"; }

PROJECT_NAME="hoangyell-gallery"
SITE_DIR="examples/astro-basic"
EXPECTED_ACCOUNT_ID="3b36a5c51daee9566d07c97a0c78c887"

cd "$(git rev-parse --show-toplevel)"

# Make sure node and pnpm are reachable (cold zsh sessions sometimes miss).
for d in "$HOME/Library/pnpm" "/opt/homebrew/bin" "/usr/local/bin"; do
  [[ -d "$d" ]] && export PATH="$d:$PATH"
done

for cmd in pnpm npx git node; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "$cmd is not installed or not on PATH."
    exit 1
  fi
done

# Verify the wrangler login is the expected account (best-effort).
log "Verifying Cloudflare account"
WHOAMI="$(npx -y -p wrangler@4 wrangler whoami 2>&1 || true)"
if echo "$WHOAMI" | grep -qi "not authenticated"; then
  err "wrangler is not logged in. Run: wrangler login"
  exit 1
fi
if echo "$WHOAMI" | grep -q "$EXPECTED_ACCOUNT_ID"; then
  ok "Logged into Ngohoang.yell@gmail.com's Account"
else
  err "wrangler is NOT logged into the expected account."
  err "Expected account ID: $EXPECTED_ACCOUNT_ID"
  err "Run: wrangler login   (and pick ngohoang.yell@gmail.com)"
  echo "$WHOAMI"
  exit 1
fi

# Pin the account ID so multi-account logins don't bite us.
export CLOUDFLARE_ACCOUNT_ID="$EXPECTED_ACCOUNT_ID"

# ── Build ─────────────────────────────────────────────────────────────────
log "Building $SITE_DIR (Astro static)"
pnpm install --no-frozen-lockfile >/dev/null
pnpm --filter astro-basic build

DIST_DIR="$SITE_DIR/dist"
if [[ ! -d "$DIST_DIR" ]]; then
  err "Build did not produce $DIST_DIR"
  exit 1
fi

PAGE_COUNT=$(find "$DIST_DIR" -name "*.html" | wc -l | tr -d ' ')
SIZE=$(du -sh "$DIST_DIR" | awk '{print $1}')
ok "Built $PAGE_COUNT page(s), total $SIZE"

# ── Deploy ────────────────────────────────────────────────────────────────
log "Deploying to Cloudflare Pages project '$PROJECT_NAME'"
# --commit-dirty=true lets us deploy from a working tree with uncommitted
# changes (handy mid-iteration). Remove for stricter CI-like runs.
npx -y -p wrangler@4 wrangler pages deploy "$DIST_DIR" \
  --project-name="$PROJECT_NAME" \
  --branch=main \
  --commit-dirty=true

echo
ok "Deployed"
dim "  preview: https://$PROJECT_NAME.pages.dev"
dim "  prod:    https://gallery.hoangyell.com  (after custom domain is bound)"
echo
dim "  If gallery.hoangyell.com still 404s, bind the custom domain once:"
dim "    https://dash.cloudflare.com/$EXPECTED_ACCOUNT_ID/pages/view/$PROJECT_NAME/domains"
