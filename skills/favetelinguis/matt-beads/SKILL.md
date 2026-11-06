---
name: matt-beads
description: "beads_rust (br) issue-tracker, local-only git exclusion, and multi-repo specialization for Matt Pocock's engineering skills. Use when running /setup-matt-pocock-skills, when any engineering skill (triage, to-spec, to-tickets, implement, implement-spec, wayfinder, code-review) needs the issue tracker, triage labels, or domain docs, or when tracking issues across one or more repositories with br."
---

# Setup Matt Pocock's Skills for beads_rust (`br`)

Specializes `engineering/setup-matt-pocock-skills`.

Run Matt Pocock's upstream engineering skills (`triage`, `to-spec`, `to-tickets`, `implement`, `implement-spec`, `wayfinder`, `code-review`) on [`beads_rust`](https://github.com/Dicklesworthstone/beads_rust) (`br`) using the official in-place `.beads/` layout while keeping unmigrated team repositories untouched through `.git/info/exclude`.

## Why in-place `.beads/` with `.git/info/exclude`

- **Official `br` discovery**: `br` has no `-C` flag. It discovers `.beads/` by walking up from the working directory, resolves linked `git worktree` checkouts back to the primary checkout's `.beads/` automatically, and follows `.beads/redirect` and `.beads/routes.jsonl`.
- **`abacus` compatibility**: `abacus` (opened in the active folder via Herdr `prefix+f`) walks up from the working directory looking for `.beads/beads.db`.
- **Zero forced team migration**: in any repository where `.beads/issues.jsonl` is not already tracked by git, adding `/.beads/`, `/.abacus/`, `/.out-of-scope/`, `/docs/agents/`, `/docs/adr/`, `/GLOSSARY.md`, and `/GLOSSARY-MAP.md` to `$(git rev-parse --git-common-dir)/info/exclude` hides your personal setup from `git status`, `git diff`, and `git add` without touching `.gitignore`, `AGENTS.md`, or `CLAUDE.md`.

## Workspace resolution

From any directory or linked `git worktree`, resolve the active workspace root `<ws>` from `br`:

```bash
ws="$(dirname "$(RUST_LOG=error br where --json | jq -r .path)")"
```

Layout inside `<ws>`:

```
<ws>/
├── .beads/                      # beads.db, issues.jsonl, config.yaml, metadata.json, optional routes.jsonl
├── .out-of-scope/               # Rejected enhancement records from /triage
├── GLOSSARY.md                  # Domain glossary written by /domain-modeling
└── docs/
    ├── adr/                     # ADRs written by /domain-modeling
    └── agents/
        ├── domain.md
        ├── issue-tracker.md
        └── triage-labels.md
```

## When reached from an engineering skill

When `triage`, `to-spec`, `to-tickets`, `implement`, `implement-spec`, `wayfinder`, or `code-review` needs the issue tracker, triage label vocabulary, or domain doc rules:

1. Check `RUST_LOG=error br where --json`. If the workspace is not initialized yet, initialize it with Step 3 below.
2. Set `ws="$(dirname "$(RUST_LOG=error br where --json | jq -r .path)")"`.
3. Read `$ws/docs/agents/issue-tracker.md`, `$ws/docs/agents/triage-labels.md`, and `$ws/docs/agents/domain.md`, and follow them as the project configuration.

Done when the calling skill has loaded `$ws/docs/agents/*.md` and runs issue operations through `br`.

## Setup process (`/setup-matt-pocock-skills` or `/matt-beads`)

### 1. Explore

Inspect the current directory, git state, and surrounding repositories:

- **Current `br` state**: run `br --version` and `RUST_LOG=error br where --json 2>/dev/null`.
- **Git tracking state**: is this a git repository (`git rev-parse --git-common-dir`), and are `.beads/issues.jsonl`, `docs/agents/`, `GLOSSARY.md`, or `docs/adr/` already tracked (`git ls-files`)?
- **Legacy `bd` artifacts**: does `.beads/` contain classic `bd` / Dolt files (`embeddeddolt`, `dolt.gate.lock`, `.beads.gate.lock`, or `"backend": "dolt"` in `.beads/metadata.json`), or is there an older `~/.beads/workspaces/<slug>` directory?
- **Multi-repo context**: are there sibling or child git repositories that belong to the same project or workflow?
- **Triage skill**: is `triage` installed?

Done when the git tracking status, existing `.beads/` state, any legacy `bd` files, and the single-repo vs multi-repo layout are known.

### 2. Present findings and confirm

Propose **`beads_rust` (`br`)** for Section A of `/setup-matt-pocock-skills`, [`triage-labels-beads.md`](./triage-labels-beads.md) for Section B, and [`domain-beads.md`](./domain-beads.md) for Section C. Confirm three choices with the user, leading each with the recommended default:

1. **Team visibility mode**:
   - **Personal local mode (default when `.beads/issues.jsonl` is not tracked in git)**: keep `.beads/` and `docs/agents/` in place and exclude untracked setup paths in `$(git rev-parse --git-common-dir)/info/exclude`. Do not edit `.gitignore`, `AGENTS.md`, or `CLAUDE.md`, and never commit `.beads/` to git.
   - **Shared git mode (only when `.beads/issues.jsonl` is already tracked or the user explicitly wants the team to share `br`)**: commit `.beads/issues.jsonl`, `.beads/config.yaml`, `.beads/metadata.json`, and `docs/agents/*.md`.

2. **Topology (when working across multiple repositories)**:
   - **Federated per-repo workspaces (recommended when each repo has its own backlog)**: run `br init --prefix <repo-slug>` in each repo, wire `.beads/routes.jsonl` (or a parent `mayor/town.json` + `.beads/routes.jsonl`) so `br show`/`update`/`close`/`comments`/`label`/`dep` route across repos by prefix, and set `br config set external_projects.<name>=<path>` for cross-repo blockers (`external:<name>:<cap>` satisfied by closed `provides:<cap>` issues).
   - **Umbrella workspace (recommended when one spec or wayfinder map spans multiple child repos under a parent folder)**: run `br init --prefix <umbrella-slug>` once in the parent folder `<ws>`, and write `<repo>/.beads/redirect` pointing to `<ws>/.beads` in each child repo (with no `beads.db` inside `<repo>/.beads/`). Both `br` (including from external linked worktrees) and `abacus` (walking up from `<repo>` to `<ws>/.beads/beads.db`) resolve the shared board.
   - **Single repo**: run `br init --prefix <repo-slug>` in the repo root.

3. **Triage mapping**:
   - **Categories** map to `br` issue types: `bug` -> `-t bug`, `enhancement` -> `-t feature` (untriaged issues default to `task`).
   - **States** pair each canonical label (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`) with a `br` status:
     - `needs-triage` and `needs-info`: `-s blocked` + label, keeping untriaged and waiting issues out of `br ready` while `br blocked` stays reserved for dependency blockers.
     - `ready-for-agent` and `ready-for-human`: `-s open` + label (`br ready -l ready-for-agent --json` surfaces only triaged agent-ready work).
     - `wontfix`: label `wontfix` + `br close <id> --force --reason "..."`.

If Step 1 found legacy `bd` (Dolt) files or an old `~/.beads/workspaces/<slug>` folder, offer to migrate `issues.jsonl` and `docs/agents/` into the official `br` workspace.

Done when the user confirms the visibility mode, topology, and any migration from `bd`.

### 3. Initialize and write configuration

1. **Migrate legacy `bd` artifacts if confirmed**:
   - If migrating from `~/.beads/workspaces/<slug>`, copy its `.beads/issues.jsonl`, `.out-of-scope/`, `GLOSSARY.md`, and `docs/adr/` into `<ws>/`.
   - If `.beads/` contains Dolt/classic `bd` files (`embeddeddolt*`, `dolt*`, `.beads.gate.lock`, `export-state.json`, `.local_version`, `hooks`, or `bd`-specific `config.yaml`), remove those files while keeping `.beads/issues.jsonl`, then run `br init --prefix <prefix> --force` and `br sync --import-only`.

2. **Initialize `br` in `<ws>` (and any federated sibling repos)**:

   ```bash
   mkdir -p "$ws/docs/agents" "$ws/docs/adr" "$ws/.out-of-scope"
   if [ ! -f "$ws/.beads/beads.db" ]; then
     (cd "$ws" && br init --prefix "$prefix" --json)
   fi
   ```

   - **For federated multi-repo setups**: initialize each repo with its own prefix, write `.beads/routes.jsonl` with `{"prefix":"<other-prefix>-","path":"<rel-or-abs-path>"}` entries, and run `br config set external_projects.<other>=<path>` in each linked repo.
   - **For umbrella multi-repo setups**: in each child git repo `<repo>`, create `<repo>/.beads/redirect` containing the path to `$ws/.beads` (for example `../../.beads` or `$ws/.beads`).

3. **Write the three config files under `$ws/docs/agents/`** from the seed templates in this skill folder, substituting the concrete absolute path of `$ws` for `<ws>`:
   - [`issue-tracker-beads.md`](./issue-tracker-beads.md) -> `$ws/docs/agents/issue-tracker.md`
   - [`triage-labels-beads.md`](./triage-labels-beads.md) -> `$ws/docs/agents/triage-labels.md` (when `triage` is installed)
   - [`domain-beads.md`](./domain-beads.md) -> `$ws/docs/agents/domain.md`

4. **Apply local git exclusions in personal mode**:
   For each git repository in scope where `.beads/issues.jsonl` is not tracked by git, append any untracked setup paths to `exclude_file="$(git -C "$repo" rev-parse --git-common-dir)/info/exclude"` if not already present:

   ```gitignore
   # Local beads_rust (br) and agent skills (personal, uncommitted)
   /.beads/
   /.abacus/
   /.out-of-scope/
   /docs/agents/
   /docs/adr/
   /GLOSSARY.md
   /GLOSSARY-MAP.md
   ```

   Skip any path (`docs/adr/`, `GLOSSARY.md`, `GLOSSARY-MAP.md`) that the repository already tracks in git (`git -C "$repo" ls-files --error-unmatch <path>`).

5. **Verify**:
   - `RUST_LOG=error br where --json` resolves `$ws/.beads`
   - `br doctor health` exits `0` (`healthy`)
   - In personal mode, `git status --porcelain` in every repository shows no untracked or modified setup files

Done when `br where --json` and `br doctor health` succeed, `$ws/docs/agents/*.md` exist, and `git status --porcelain` in personal-mode repositories is clean.
