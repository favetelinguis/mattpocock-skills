# Issue tracker: beads_rust (`br`)

Issues and specs for this repo live in [beads_rust](https://github.com/Dicklesworthstone/beads_rust) (`br`), in `.beads/` at the main worktree root. `br` finds it from any subdirectory and from every linked worktree. `.beads/` is personal: it is excluded through `.git/info/exclude`, and it stays out of every commit.

Prefix commands with `RUST_LOG=error` and pass `--json` whenever you parse the output.

## Conventions

- **Create an issue**: `br create "<title>" -t <type> -p <priority> -l <label>,<label> --silent --description-file - <<'EOF' ... EOF`. `--silent` prints only the new id. Pick the type from **Issue types** below.
- **Read an issue**: `br show <id> --json`. It returns a one-element array carrying `description`, `acceptance_criteria`, `labels`, `external_ref`, `dependencies`, `dependents`, and `comments`.
- **List issues**: `br list --json` lists every open, in-progress, and blocked issue. Add `-a` for closed ones and `--deferred` for deferred ones. Filter with `-l <label>`, `-t <type>`, and `--exclude-label <label>` (repeat the flag once per label; it takes no wildcards). `--sort created_at -r` lists oldest first.
- **Make an issue a child of a parent**: `br create ... --parent <parent>` (the child gets the id `<parent>.N`), or `br update <child> --parent <parent>` afterwards. A parent counts as blocked by every open child, so it never shows in `br ready`.
- **Blocking**: `br`'s native dependencies. `br create ... --deps blocks:<blocker>,blocks:<blocker>` makes the new issue blocked by each blocker; `br dep add <blocked> <blocker>` adds an edge afterwards. A ticket is unblocked when every blocker is closed. `br dep cycles --json` must return an empty list.
- **Count open blockers**: `br show <id> --json | jq '[.[0].dependencies[] | select(.dependency_type == "blocks" and .status != "closed")] | length'` (0 means startable).
- **Comment on an issue**: `br comments add <id> -m "..."`, or `-f <file>` for multi-line text.
- **Apply / remove labels**: `br update <id> --add-label <label> --remove-label <label>`. `br` creates a label on first use.
- **Claim**: `br update <id> --claim` sets you as assignee and the status to `in_progress` in one write. Release an abandoned claim with `br update <id> -s open --assignee ""`.
- **Close**: `br close <id> --transition-comment "<explanation>" --reason "<one-line gist>" --suggest-next`. The comment lands atomically with the close, and `--suggest-next` lists what the close unblocked. Pass `--force` only to close an issue that still has open blockers.

Work closes through `br close` alone: a PR or merge never closes a `br` issue, so close each ticket once its change lands.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(`br` holds no PRs; `/triage` reads this flag.)_

## When a skill says "publish to the issue tracker"

Create a `br` issue:

- **A spec** (`/to-spec`): `br create "<spec title>" -t epic -l ready-for-agent --silent --description-file -` with the spec as the description. When the spec comes out of a wayfinder map, add `--deps discovered-from:<map>`.
- **Tickets** (`/to-tickets`): create them in dependency order, blockers first, capturing each id from `--silent`. Wire blocking natively with `--deps blocks:<blocker>` and leave the body's `## Blocked by` section out. Put the `## Acceptance criteria` checklist in `--acceptance-criteria` rather than the description. When the source was an existing issue, pass `--parent <source>` and `-p <source's priority>`. Type each ticket per **Issue types**.

## When a skill says "fetch the relevant ticket"

Run `br show <id> --json`, then read its acceptance criteria and comments alongside the description.

## Wayfinding operations

Used by `/wayfinder`. The **map** is an epic with **child** issues as tickets.

- **Map**: `br create "<map title>" -t epic -l wayfinder:map --silent --description-file -`, holding the Destination / Notes / Decisions so far / Not yet specified / Out of scope body. Rewrite the body with `br update <map> --description-file -`, adding `--force` when the new body is under half the old length.
- **Child ticket**: `br create "<question title>" -t task -l wayfinder:<type> --parent <map> --silent --description-file -`, where `<type>` is `research`, `prototype`, `grilling`, or `task`. A ticket surfaced while resolving ticket T also gets `--deps discovered-from:T`.
- **Blocking**: see **Blocking** under Conventions. Wire edges in the second pass with `br dep add <blocked> <blocker>`.
- **Frontier query**: `br ready --parent <map> --unassigned --sort oldest --json`. It already drops blocked, claimed, and deferred tickets; first in the list wins.
- **Claim**: `br update <ticket> --claim`, the session's first write.
- **Resolve**: `br close <ticket> --transition-comment "<answer>" --reason "<one-line gist>" --suggest-next`, then append `- [<ticket title>](<ticket id>): <one-line gist>` under the map's `## Decisions so far`. Set the ticket's primary asset (research findings, prototype) as its `--external-ref` (see **Artifacts**).
- **Rule out of scope**: `br close <ticket> --reason "Out of scope: <why>"`, then add one line under the map's `## Out of scope`.

## Triage

Used by `/triage`. Role names map to label strings through `triage-labels.md`.

- **Category**: `bug` is type `bug`; `enhancement` is type `feature`. Set it with `br update <id> -t <bug|feature>`.
- **State**: swap the role label with `br update <id> --remove-label <old role> --add-label <new role>`, naming two different labels. Status stays native (`open`, `in_progress`, `deferred`, `closed`): every role lives in a label.
- **Priority**: set `-p` on each issue you triage, per **Priority**.
- **`wontfix`**: `br update <id> --add-label wontfix`, then `br close <id> --transition-comment "<explanation>" --reason "wontfix: <gist>"`. A rejected enhancement's `.out-of-scope/<concept>.md` becomes its `--external-ref`.
- **Duplicate**: `br dep add <duplicate> <original> -t duplicates`, then close it as `wontfix` with the reason `wontfix: duplicate of <original>`.

The three "needs attention" buckets, oldest first:

1. **Unlabeled**: `br list --sort created_at -r --json` with one `--exclude-label` for each of `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`, `wayfinder:map`, `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, `wayfinder:task`.
2. **`needs-triage`**: `br list -l needs-triage --sort created_at -r --json`.
3. **`needs-info` with activity since the last triage notes**: `br list -l needs-info --sort created_at -r --json`, then compare each issue's comments against its latest `## Triage Notes` comment.

## Beads specializations

### Issue types

Use exactly these five types. `br` accepts any string for `-t`, so this list is the guard.

| Type      | Use it for                                                                                             |
| --------- | ------------------------------------------------------------------------------------------------------ |
| `bug`     | Something broken: triage's `bug` category, or a defect found while working                             |
| `feature` | Triage's `enhancement` category                                                                        |
| `task`    | A `/to-tickets` vertical slice; every wayfinder ticket (its `wayfinder:<type>` label carries the kind) |
| `chore`   | Expand-contract and mechanical refactor tickets; upkeep that changes no behaviour                      |
| `epic`    | A spec, or a wayfinder map (label `wayfinder:map`)                                                     |

### Links

Use these six dependency types and leave the rest unused:

| Type              | Meaning: `br dep add <A> <B> -t <type>`    | Blocks `br ready`?                   |
| ----------------- | ------------------------------------------ | ------------------------------------ |
| `blocks`          | A waits on B                               | yes                                  |
| `parent-child`    | A is a child of B (set through `--parent`) | the parent, until its children close |
| `discovered-from` | A was found while working B                | no                                   |
| `duplicates`      | A duplicates B                             | no                                   |
| `supersedes`      | A's decision overturns closed B's          | no                                   |
| `caused-by`       | Bug A was introduced by B's change         | no                                   |

- **`supersedes`**: when a wayfinder resolution overturns an earlier decision, link the new ticket to the old one.
- **`caused-by`**: when `/diagnosing-bugs` traces a bug to the change a specific closed ticket shipped, link the bug to that ticket.

### Discovered work

When you find work outside the issue you are working on (call it X), file it and stay on X:

- **While implementing, testing, diagnosing, or reviewing X**: `br create "<title>" -t <bug|task|chore> -l needs-triage --deps discovered-from:X --silent --description-file -`. Tell the user the new issue's title and id.
- **While resolving wayfinder ticket X**: file it as a child ticket per **Wayfinding operations**, with `--parent <map> --deps discovered-from:X`. Fog that X's answer graduates into tickets gets the same link.

### Artifacts

`--external-ref` holds one locator: the issue's **primary artifact**. Set it with `br update <id> --external-ref "<locator>"` whenever you produce, for an issue, a research findings file, a prototype, a wizard script, a lesson, or an `.out-of-scope/` record, or when the issue mirrors one on a team tracker.

- A URL stays as-is (a team Jira or GitHub issue, a hosted doc).
- A file on the current branch is a repo-relative path.
- A file on another branch is `<branch>:<path>`, readable with `git show <branch>:<path>` (wayfinder research lives on `research/<name>`).

Each further asset goes in a comment: `br comments add <id> -m "Asset: <locator>"`.

### Acceptance criteria

`/to-tickets` writes each ticket's checklist to the native acceptance field. While implementing, tick each criterion as it passes with `br update <id> --check-acceptance "<unique text of the item>"` (or `--check-acceptance 1,3` by position). A ticket closes once every criterion is ticked.

### Priority

`-p` runs 0 to 4, default 2:

- **0**: broken in production or blocking the user. Set only when the user says so.
- **1**: next up.
- **2**: normal.
- **3**: nice to have.
- **4**: someday.

Triage sets it, `/to-tickets` copies the spec's priority onto each ticket, and wayfinder ignores it in favour of map order.

### Pausing

Defer only when the user asks to park work. Deferring an epic leaves its children in `br ready`, so defer the epic together with every open descendant: walk the tree with `br dep list <id> --direction up -t parent-child --json` from the epic down, then run `br defer <epic> <descendant> ... --transition-comment "<why>"`. Resume with `br undefer` on the same ids. A `needs-info` wait stays a label, never a defer.
