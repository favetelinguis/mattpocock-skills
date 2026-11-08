---
name: setup-matt-skills-with-beads
description: "Configure this repo for the engineering skills with a personal beads_rust (br) issue tracker that never touches the repo. Run once per repo before first use of the other engineering skills."
disable-model-invocation: true
---

# Setup Matt Pocock's Skills with beads

Specializes `engineering/setup-matt-pocock-skills`.

The upstream setup writes `docs/agents/*.md` and an `## Agent skills` block into the repo. Here every piece of configuration lives outside the repo instead:

- **Issue tracker**: [`issue-tracker-beads.md`](./issue-tracker-beads.md), read straight from this skill folder.
- **Triage labels**: [`triage-labels.md`](./triage-labels.md), a symlink to upstream's canonical defaults.
- **Domain docs**: [`domain.md`](./domain.md), a symlink to upstream's consumer rules.
- **The pointer**: [`agent-skills-block.md`](./agent-skills-block.md), the `## Agent skills` block that lives once in the user's global context file and points at the three files above.

The repo itself receives exactly two things: a `.beads/` workspace at the main worktree root, and a `/.beads/` line in the shared `.git/info/exclude`. Both are invisible to git and to every teammate, and both serve every linked worktree.

## Process

### 1. Explore

Run [`setup.sh check`](./setup.sh) from the repo. It reports the main worktree root, the default prefix, whether a `.beads/` workspace and the exclude line already exist, and which global context files (`~/.pi/agent/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`) carry the block. If it stops with an error, relay it to the user and stop.

Done when you hold the script's full report.

### 2. Present findings and ask

Summarise the report. Upstream's three sections need no questions: the tracker is `br`, the triage labels are the canonical defaults, and the domain layout comes from upstream's `domain.md`. Ask only what the report leaves open, each led by its recommended answer:

- **Prefix**, when no workspace exists yet: "Use `<default prefix>` as the issue id prefix?" (recommended: **yes**).
- **Global block**, when no global context file carries it: show [`agent-skills-block.md`](./agent-skills-block.md) and ask which file to add it to (recommended: the file for the harness the user is in now). When a file already holds an `## Agent skills` block, offer to replace that block in place.

If the report says `.beads/` is committed in this repo, tell the user this skill only sets up a personal workspace and stop.

Done when the user has confirmed the prefix (or a workspace already exists) and the global block is either present or approved for one file.

### 3. Write

1. Run `setup.sh apply <prefix>`. It initialises `br`, adds the exclude line, and verifies the result; it is safe to re-run.
2. If approved, add the block from `agent-skills-block.md` to the chosen global context file, verbatim, leaving every other section of that file untouched.

Done when `setup.sh apply` prints its `verified:` line and `setup.sh check` reports the block present in at least one global context file.

### 4. Done

Tell the user the repo is ready: `triage`, `to-spec`, `to-tickets`, `implement`, `implement-spec`, `wayfinder`, and `code-review` now read the tracker through the global block, and `bv` opens the same board. The tracker rules live in `issue-tracker-beads.md` in this skill folder, so editing that file changes every repo at once. Re-running this skill is only needed for a new repo or a new computer's global context file.
