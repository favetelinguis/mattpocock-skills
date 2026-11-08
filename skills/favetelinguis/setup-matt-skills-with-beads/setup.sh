#!/usr/bin/env bash
# Personal beads_rust (br) workspace for the current git repo.
#
#   setup.sh check           report the repo's state; changes nothing
#   setup.sh apply <prefix>  init br at the main worktree root and exclude
#                            /.beads/ locally; safe to re-run
#
# Everything lands in .beads/ and the shared .git/info/exclude, so linked
# worktrees see the same workspace and nothing reaches a commit.
set -euo pipefail
export RUST_LOG=error

die() { echo "error: $*" >&2; exit 1; }

command -v br >/dev/null || die "br is not on PATH; install beads_rust first"
command -v jq >/dev/null || die "jq is not on PATH"
common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" ||
  die "not inside a git repository"

# The first worktree listed is the main one, even when run from a linked one.
main_entry="$(git worktree list --porcelain | head -n 2)"
[[ "$main_entry" == *$'\nbare'* ]] && die "bare repository; run this from a repo with a main worktree"
root="${main_entry%%$'\n'*}"
root="${root#worktree }"
exclude="$common/info/exclude"
line="/.beads/"
block_marker="setup-matt-skills-with-beads/issue-tracker-beads.md"

workspace() { (cd "$root" && br where --json 2>/dev/null | jq -r '.path // empty') || true; }

report() {
  local ws prefix
  ws="$(workspace)"
  prefix="$(basename "$root" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
  echo "root: $root"
  echo "default prefix: $prefix"
  if [[ "$ws" == "$root/.beads" ]]; then
    echo "workspace: present ($ws, prefix $(cd "$root" && br where --json | jq -r .prefix))"
  elif [[ -n "$ws" ]]; then
    echo "workspace: none at root; br resolves an outer one at $ws"
  else
    echo "workspace: none"
  fi
  if grep -qxF "$line" "$exclude" 2>/dev/null; then echo "exclude: present"; else echo "exclude: missing"; fi
  if [[ -n "$(git -C "$root" ls-files -- .beads)" ]]; then echo "tracked: .beads/ is committed in this repo"; fi
  for f in "$HOME/.pi/agent/AGENTS.md" "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"; do
    if [[ ! -f "$f" ]]; then echo "global block: $f (no file)"
    elif grep -qF "$block_marker" "$f"; then echo "global block: $f (present)"
    else echo "global block: $f (missing)"; fi
  done
}

apply() {
  local prefix="${1:-}"
  [[ -n "$prefix" ]] || die "usage: setup.sh apply <prefix>"
  [[ -z "$(git -C "$root" ls-files -- .beads)" ]] || die ".beads/ is committed in this repo; refusing to make it personal"

  if [[ "$(workspace)" != "$root/.beads" ]]; then
    (cd "$root" && br init --prefix "$prefix" >/dev/null)
    echo "initialised br workspace at $root/.beads (prefix $prefix)"
  else
    echo "br workspace already at $root/.beads"
  fi

  mkdir -p "$common/info"
  if ! grep -qxF "$line" "$exclude" 2>/dev/null; then
    printf '%s\n' "$line" >>"$exclude"
    echo "added $line to $exclude"
  else
    echo "$line already in $exclude"
  fi

  # Verify: workspace resolves, br is healthy, git sees nothing under .beads/.
  [[ "$(workspace)" == "$root/.beads" ]] || die "br where does not resolve $root/.beads"
  (cd "$root" && br doctor health >/dev/null) || die "br doctor health failed; run 'br doctor' in $root"
  [[ -z "$(git -C "$root" status --porcelain --untracked-files=all -- .beads)" ]] ||
    die "git still sees files under .beads/"
  echo "verified: br resolves $root/.beads, br doctor health passes, git status is clean for .beads/"
}

case "${1:-}" in
  check) report ;;
  apply) shift; apply "$@" ;;
  *) die "usage: setup.sh check | setup.sh apply <prefix>" ;;
esac
