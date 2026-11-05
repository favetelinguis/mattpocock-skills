#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
UPSTREAM_URL="https://github.com/mattpocock/skills.git"

if git -C "$REPO" remote get-url upstream >/dev/null 2>&1; then
  existing_url="$(git -C "$REPO" remote get-url upstream)"
  case "$existing_url" in
    https://github.com/mattpocock/skills.git|https://github.com/mattpocock/skills|git@github.com:mattpocock/skills.git|git@github.com:mattpocock/skills) ;;
    *)
      echo "error: upstream points to $existing_url, not $UPSTREAM_URL" >&2
      exit 1
      ;;
  esac
else
  git -C "$REPO" remote add upstream "$UPSTREAM_URL"
fi

git -C "$REPO" fetch upstream
git -C "$REPO" switch main
git -C "$REPO" merge --no-edit upstream/main
git -C "$REPO" push origin main
