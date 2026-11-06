# Issue tracker: beads_rust (`br`)

Issues and specs for this project live in [`beads_rust`](https://github.com/Dicklesworthstone/beads_rust) (`br`) at `<ws>/.beads`. `br` discovers `.beads/` automatically from the working directory, from subdirectories, from linked `git worktree` checkouts, and across `.beads/redirect` or `.beads/routes.jsonl`. When running from a directory outside the workspace or its worktrees, pass `--db <ws>/.beads/beads.db` (or set `BEADS_DIR=<ws>/.beads`). Prefix commands with `RUST_LOG=error` when parsing `--json` output so internal logs never mix with stderr.

## Conventions

- **Create an issue**: `br create "<title>" -t <type> -d "..." --json` (or `--silent` when scripting to output only the new `<id>`). For multi-line markdown bodies, pass `--description-file - <<'EOF' ... EOF` (mutually exclusive with `-d`). Types via `-t`: `task` (default), `bug`, `feature` (`enhancement` is also accepted), `epic`, `chore`, `decision`, `spike`, `story`, `milestone`, `question`, `docs`. Priority via `-p` (`0` to `4`, `0` highest, default `2`).
- **Read an issue**: `br show <id>` for rich terminal output, or `br show <id> --json` (or `--format toon`) for structured output. `br show <id> --json` returns a JSON array `[{...}]` that includes `description`, `design`, `acceptance_criteria`, `notes`, `labels`, `parent`, `dependencies`, `dependents`, and `comments`.
- **List issues**: `br list --json` returns `{"issues": [...], "total": N, "limit": L, "offset": O, "has_more": bool}` and includes all non-closed issues (`open`, `in_progress`, `blocked`) by default. Pass `--deferred` to include deferred issues or `-a` (`--all`) to include closed issues. Repeat flags instead of comma-separating when filtering multiple statuses or excluded labels: `-s open -s in_progress -s blocked`, `-l <label>`, `--label-any <label>`, `--exclude-label <label>` (repeatable), `-t <type>`, `--assignee <user>`, `--unassigned`, `-p <priority>`. Sort via `--sort <priority|created_at|updated_at|title>`; `created_at` and `updated_at` sort newest-first by default, so pass `-r` (`--reverse`) for oldest-first (`--sort created_at -r`).
- **Find ready work**: `br ready -l ready-for-agent --json` returns a JSON array `[...]` of `open`, unblocked, non-deferred issues carrying `ready-for-agent`. Use `br ready --brief --json` to omit long description/notes fields while selecting work. `br blocked --json` returns `{"issues": [...], "total": ...}` listing dependency-blocked issues and their open `.blocked_by` IDs.
- **Make an issue a child of a parent**: `br create "<title>" --parent <parent-id> ...` (mints hierarchical ID `<parent-id>.1`, `<parent-id>.2`, ... without inheriting parent labels), or `br update <child-id> --parent <parent-id>`, or `br dep add <child-id> <parent-id> --type parent-child`. List all children of a parent (including closed) with `br dep list <parent-id> --direction up -t parent-child --json` (or `br show <parent-id> --json | jq '.[0].dependents'`).
- **Blocking**: `br`'s **native issue dependencies**, the canonical representation. Add an edge at creation with `br create ... --deps blocks:<blocker-id>` (or `blocked-by:<blocker-id>`, comma-separated for multiple blockers) or afterwards with `br dep add <blocked-id> <blocker-id>` (first argument depends on second argument). `br dep tree <id>` and `br graph <id>` render the dependency graph; `br dep cycles --json` checks for cycles (must be empty). A ticket is unblocked when every blocker is closed.
- **Count open blockers**: `br show <id> --json | jq '[.[0].dependencies[]? | select(.dependency_type == "blocks" and .status != "closed")] | length'` (`0` means startable locally).
- **Comment on an issue**: `br comments add <id> "..."` (or `-m "..."`, or `-f <file>`). List comments with `br comments list <id> --json`.
- **Apply / remove labels and update fields**: `br update <id> -t <type> -s <status> --remove-label <old-label> --add-label <new-label>`. Never pass the same label to both `--add-label` and `--remove-label` in one `br update` call (`--remove-label` runs after `--add-label`). Replacing a non-empty description, design, acceptance criteria, or notes field with an empty value or content shorter than half its previous length requires `--force`. Check or append acceptance criteria in place with `--check-acceptance`, `--uncheck-acceptance`, `--add-acceptance`, and `--append-notes`.
- **Claim and unclaim**: `br update <id> --claim --json` (atomically sets `assignee` to actor and `status=in_progress`). Release an abandoned claim with `br update <id> -s open --assignee "" --json`.
- **Close**: `br close <id> --reason "..." --json` (or pass `--transition-comment "..."` to commit a closing comment atomically with the close transition, and `--suggest-next` to return newly unblocked issues). When closing an issue that still has open blockers (such as a `wontfix` or out-of-scope ticket), pass `--force`: `br close <id> --force --reason "..."`.
- **Out-of-scope records**: read `.out-of-scope/*.md` from both the repository (if present) and `<ws>/.out-of-scope/*.md`. Write new or updated `.out-of-scope/<concept>.md` files to `<ws>/.out-of-scope/<concept>.md`.
- **Sync and git**: `br` is non-invasive and never runs git commands automatically; mutations auto-flush `<ws>/.beads/issues.jsonl`. When `<ws>/.beads/` is excluded via `.git/info/exclude` (personal local mode, where `br vcs-status --json | jq .tracked` is `false`), never `git add -f .beads/` or commit `.beads/`, `docs/agents/`, or `.out-of-scope/` to the repository. Only run `br sync --flush-only` and `git add .beads/issues.jsonl` when `.beads/issues.jsonl` is tracked in git and the user asks to commit issue updates.

## Multi-repo operations

- **Cross-repo routing (`.beads/routes.jsonl`)**: when `.beads/routes.jsonl` maps prefixes to sibling repositories (`{"prefix":"api-","path":"../api"}`), route-aware commands (`br show`, `br update`, `br close`, `br reopen`, `br delete`, `br defer`, `br comments`, `br label`, `br dep`, `br graph`, `br audit`, `br lint`) resolve any `<prefix>-<hash>` issue ID against the target repository's `.beads/` directly.
- **Cross-repo blocking dependencies (`external_projects.<name>`)**: when `external_projects.<repo>` is configured (`br config set external_projects.api=../api`), block a local issue on an issue in `<repo>` by labeling the blocker in `<repo>` with `provides:<blocker-id>` (`br label add <blocker-id> provides:<blocker-id>`) and adding the dependency in the dependent repo with `br dep add <local-id> external:<repo>:<blocker-id>`. `br ready` and `br blocked` automatically check whether a closed issue in `<repo>` carries `provides:<blocker-id>`.
- **Umbrella workspace (`redirect`)**: when a parent workspace `<ws>/.beads` is shared across child repositories via `<repo>/.beads/redirect`, tag or scope repo-specific issues with `-l repo:<repo>` or `--source-repo <repo>` so work across repositories stays distinguishable on the shared board.

## Pull requests as a triage surface

**PRs as a request surface: no.**

## Triage queries and transitions

Every comment or issue posted during `/triage` must start with `> *This was generated by AI during triage.*`.

Query the three "Show what needs attention" buckets (oldest first) with:

1. **Unlabeled** (never triaged):
   `br list --deferred --exclude-label needs-triage --exclude-label needs-info --exclude-label ready-for-agent --exclude-label ready-for-human --exclude-label wontfix --exclude-label wayfinder:map --exclude-label wayfinder:research --exclude-label wayfinder:prototype --exclude-label wayfinder:grilling --exclude-label wayfinder:task --sort created_at -r --json`
2. **`needs-triage`**:
   `br list --deferred -l needs-triage --sort created_at -r --json`
3. **`needs-info` with reporter activity since the last triage notes**:
   `br list --deferred -l needs-info --sort created_at -r --json`, then check `br show <id> --json` for `.comments` posted after the latest `## Triage Notes` comment.

See `triage-labels.md` in `<ws>/docs/agents/triage-labels.md` for the category and state role mappings.

## When a skill says "publish to the issue tracker"

Create a `br` issue with `br create`:

- For `/to-spec`: `br create "<spec title>" -t epic -s open -l ready-for-agent --description-file - <<'EOF' ... EOF`.
- For `/to-tickets`: create tickets in dependency order (blockers first) with `--silent` to capture each `<id>`, passing `--parent <spec-id> -l ready-for-agent` when breaking down a parent spec and `--deps blocks:<blocker-id>` for native blocking edges (or `external:<repo>:<blocker-id>` with `provides:<blocker-id>` on the blocker for cross-repo slices). Omit the `## Blocked by` body section when blockers are wired as native dependencies.

## When a skill says "fetch the relevant ticket"

Run `br show <id> --json` (or `br show <id>`).

## Wayfinding operations

Used by `/wayfinder`. The **map** is an `epic` issue with **child** issues as tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Destination / Notes / Decisions-so-far / Not-yet-specified / Out-of-scope body: `br create "<map title>" -t epic -l wayfinder:map --description-file - <<'EOF' ... EOF`. Update the map body with `br update <map-id> --force --description-file - <<'EOF' ... EOF` (`--force` allows updates even when the map has open child blockers or a shorter body).
- **Child ticket**: an issue linked to the map with `--parent <map-id>` (giving hierarchical IDs `<map-id>.1`, `<map-id>.2`, ...) and label `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Never apply a triage label to map tickets.
- **Blocking**: see **Blocking** under Conventions (`br dep add <child-id> <blocker-id>`).
- **Frontier query**: `br ready --parent <map-id> --unassigned --sort oldest --json`; first in map order wins.
- **Claim**: `br update <ticket-id> --claim --json`, the session's first write.
- **Resolve**: `br close <ticket-id> --transition-comment "<answer>" --reason "<one-line gist>" --json`, then update `<map-id>`'s body to append `- [<closed ticket title>](<ticket-id>): <one-line gist>` under `## Decisions so far`.
- **Rule out of scope**: `br close <ticket-id> --force --reason "Out of scope: <why>" --json`, then add one line under `## Out of scope` in `<map-id>`'s body.
