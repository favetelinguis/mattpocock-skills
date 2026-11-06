---
name: matt-beads
description: "Beads (bd) issue-tracker and external-workspace specialization for Matt Pocock's engineering skills. Use when running /setup-matt-pocock-skills, when any engineering skill (triage, to-spec, to-tickets, implement, implement-spec, wayfinder, code-review) needs the issue tracker, triage labels, or domain docs, or when tracking issues with Beads."
---

# Setup Matt Pocock's Skills for Beads

Specializes `engineering/setup-matt-pocock-skills`.

Run Matt Pocock's upstream engineering skills (`triage`, `to-spec`, `to-tickets`, `implement`, `implement-spec`, `wayfinder`, `code-review`) against [Beads](https://github.com/gastownhall/beads) (`bd`) with the database and agent configuration stored **outside the repository**, leaving the repository working tree and git history untouched.

## External workspace standard

Every repository gets a dedicated external workspace outside the repo:

```bash
repo_slug=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
ws="$HOME/.beads/workspaces/$repo_slug"
```

Using `--git-common-dir` resolves the same `<repo_slug>` from the main checkout and from any linked `git worktree` (such as subagent worktrees in `implement-spec` or `explain-diff`).

Layout inside `$ws`:

```
~/.beads/workspaces/<repo-slug>/
├── .beads/                      # Dolt database and Beads metadata
├── .out-of-scope/               # Rejected enhancement records from /triage
├── GLOSSARY.md                  # Domain glossary written by /domain-modeling
└── docs/
    ├── adr/                     # ADRs written by /domain-modeling
    └── agents/
        ├── domain.md
        ├── issue-tracker.md
        └── triage-labels.md
```

**Zero repo changes:**

- Run every `bd` command against the external workspace with `bd -C "$ws" <command>` (or `BEADS_DIR="$ws/.beads"`).
- Never create `.beads/`, `.beads.gate.lock`, `docs/agents/`, or `.out-of-scope/` inside the target repository, and never edit the repository's `CLAUDE.md`, `AGENTS.md`, `.gitignore`, or `.git/hooks/`.

## When reached from an engineering skill

When `triage`, `to-spec`, `to-tickets`, `implement`, `implement-spec`, `wayfinder`, or `code-review` needs the issue tracker, triage label vocabulary, or domain doc rules:

1. Resolve `$ws` with the command above.
2. If `$ws/.beads` or `$ws/docs/agents/issue-tracker.md` does not exist yet, initialize `$ws` using Step 3 below.
3. Read `$ws/docs/agents/issue-tracker.md`, `$ws/docs/agents/triage-labels.md`, and `$ws/docs/agents/domain.md`, and follow them as the repository's configuration.

Done when the calling skill has loaded the configuration from `$ws/docs/agents/` and runs all `bd` operations with `bd -C "$ws"`.

## Setup process (`/setup-matt-pocock-skills` or `/matt-beads`)

### 1. Explore

Inspect both the target repository and its external workspace `$ws`:

- Does `$ws/.beads` already exist? Check `bd -C "$ws" where --json` and `bd --version`.
- Does the repository itself contain an in-repo `.beads/`, `.beads.gate.lock`, `docs/agents/`, or `<!-- BEGIN BEADS ... -->` blocks in `CLAUDE.md` / `AGENTS.md` from an earlier in-repo setup?
- Is `triage` installed (`triage` in available skills, or alongside this skill)?

Done when the state of `$ws`, any in-repo Beads artifacts, and `triage` is known.

### 2. Present findings and confirm

When running inside `/setup-matt-pocock-skills`, propose **Beads (`bd`) in external workspace `$ws`** for Section A, the Beads triage mapping in [`triage-labels-beads.md`](./triage-labels-beads.md) for Section B, and external domain docs in [`domain-beads.md`](./domain-beads.md) for Section C.

Explain the Beads triage mapping briefly:

- **Categories** map to Beads issue types: `bug` -> `--type bug`, `enhancement` -> `--type feature` (untriaged issues default to `task`).
- **States** pair each canonical label (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`) with a Beads status:
  - `needs-triage` and `needs-info`: `--status blocked` + label, keeping untriaged and waiting issues out of `bd ready` without colliding with `bd blocked` (which tracks dependency blockers only).
  - `ready-for-agent` and `ready-for-human`: `--status open` + label. Keeping the `ready-for-agent` label separates triaged agent-ready work (`bd -C "$ws" ready -l ready-for-agent`) from brand-new unlabeled issues and from `ready-for-human` work.
  - `wontfix`: label `wontfix` + `bd -C "$ws" close <id> --force --reason "..."`.

If step 1 found an in-repo `.beads/` or `docs/agents/`, offer to migrate them into `$ws` and clean the repository working tree.

Done when the user confirms the workspace path `$ws`, the role mapping, and whether to migrate any existing in-repo files.

### 3. Initialize `$ws` and write the configuration

1. Create and initialize the external Beads workspace (or move an existing in-repo `.beads/` into `$ws/.beads` if confirmed):

   ```bash
   mkdir -p "$ws/docs/agents" "$ws/docs/adr" "$ws/.out-of-scope"
   if [ ! -d "$ws/.beads" ]; then
     (cd "$ws" && bd init -q --role maintainer --prefix "$repo_slug" --skip-hooks --skip-agents)
   fi
   ```

2. Write the three config files under `$ws/docs/agents/` from the seed templates in this skill folder, substituting the concrete absolute path of `$ws` for `<ws>`:
   - [`issue-tracker-beads.md`](./issue-tracker-beads.md) -> `$ws/docs/agents/issue-tracker.md`
   - [`triage-labels-beads.md`](./triage-labels-beads.md) -> `$ws/docs/agents/triage-labels.md` (when `triage` is installed)
   - [`domain-beads.md`](./domain-beads.md) -> `$ws/docs/agents/domain.md`

3. Verify the external workspace and confirm the target repository is untouched:
   - `bd -C "$ws" where --json` resolves `$ws/.beads`
   - `git status --porcelain --ignored` in the target repository shows no files added or modified by this setup

Respect the repository's git and sync policy: never run `git commit`, `git push`, `bd dolt push`, or `bd sync` unless the user explicitly asks.

Done when `$ws/.beads` and `$ws/docs/agents/*.md` exist, `bd -C "$ws" where` succeeds, and the target repository has zero modified or untracked setup files.
