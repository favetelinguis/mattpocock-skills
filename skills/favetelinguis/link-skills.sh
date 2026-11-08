#!/usr/bin/env bash
set -euo pipefail

skills_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
destination="$HOME/.agents/skills"

# Add, remove, or comment out entries here, then rerun this script.
skills=(
  # Engineering
  engineering/ask-matt
  engineering/code-review
  engineering/codebase-design
  engineering/diagnosing-bugs
  engineering/domain-modeling
  engineering/grill-with-docs
  engineering/implement
  engineering/improve-codebase-architecture
  engineering/pr
  engineering/prototype
  engineering/research
  engineering/retro
  engineering/setup-matt-pocock-skills
  engineering/tdd
  engineering/to-spec
  engineering/to-tickets
  engineering/triage
  engineering/wayfinder
  engineering/wizard

  # Productivity
  productivity/grill-me
  productivity/grilling
  productivity/handoff
  productivity/teach
  productivity/to-questionnaire
  productivity/wait-what
  productivity/writing-for-agents

  # Personal
  favetelinguis/explain-diff
  favetelinguis/external-integration-design
  favetelinguis/infra-and-deploy
  favetelinguis/observability
)

# Keep the destination a real directory so links cannot land in the repo.
if [[ -L "$destination" ]]; then
  echo "Refusing symlinked destination: $destination" >&2
  exit 1
fi
mkdir -p -- "$destination"

for source in "$skills_root"/{engineering,productivity,favetelinguis}/*; do
  [[ -f "$source/SKILL.md" ]] || continue
  relative="${source#"$skills_root/"}"
  target="$destination/${source##*/}"

  if [[ " ${skills[*]} " == *" $relative "* ]]; then
    if [[ -e "$target" && ! -L "$target" ]]; then
      echo "Refusing to overwrite: $target" >&2
      exit 1
    fi
    ln -sfn -- "$source" "$target"
    echo "Linked $relative"
  elif [[ -L "$target" && "$(readlink -- "$target")" == "$source" ]]; then
    # Only remove links owned by this checkout.
    unlink -- "$target"
    echo "Unlinked $relative"
  fi
done
