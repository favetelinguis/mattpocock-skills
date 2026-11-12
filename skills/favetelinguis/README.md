# Personal

Personal skills that complement or customize Matt's `engineering/` and `productivity/` skills.

Matt's upstream skills own the core development loop (`grill-with-docs` -> `to-spec` -> `to-tickets` -> `implement` / `tdd` -> `code-review` -> `retro`). Most skills in this folder fill in personal tooling, production operations, and infrastructure gaps. `production-readiness-check` is an independent copy of upstream `code-review` with Production and Integration axes, used only by `explain-diff`:

- **[production-readiness-check](./production-readiness-check/SKILL.md)**: The blind review `explain-diff` runs, on parallel axes: documented standards, the originating spec, production readiness (via `infra-and-deploy` and `observability`), and, when the diff touches an external integration, integration resilience (via `external-integration-design`).
- **[explain-diff](./explain-diff/SKILL.md)**: Explain a diff or PR in your own words, get grilled until your model matches the code, and leave with review comments (complements `code-review` and `grilling`).
- **[external-integration-design](./external-integration-design/SKILL.md)**: Design resilient integrations with external systems and providers (called by `production-readiness-check`).
- **[infra-and-deploy](./infra-and-deploy/SKILL.md)**: Trace app-to-infrastructure chains across Helm, Kubernetes, AWS, Azure, Terraform, Bicep, Docker, and CI/CD, and surface what only a live deploy can verify (called by `production-readiness-check`).
- **[observability](./observability/SKILL.md)**: Instrument production code with structured logging, RED and USE metrics, OpenTelemetry tracing, symptom-based alerts, and runbooks (called by `production-readiness-check`).
- **[setup-matt-skills-with-beads](./setup-matt-skills-with-beads/SKILL.md)**: Configure a repo for the engineering skills with a personal beads_rust (`br`) tracker kept out of git, wired through one block in the global `AGENTS.md` (replaces `setup-matt-pocock-skills`).

## How they fit into Matt's flow

| Upstream stage | Matt's skills | How `favetelinguis` complements it |
|---|---|---|
| **Setup & Tracker** | `setup-matt-pocock-skills`, `triage`, `wayfinder` | `setup-matt-skills-with-beads` replaces upstream setup: a personal `.beads/` excluded through `.git/info/exclude`, and a beads tracker doc adding `discovered-from`, `--external-ref`, native acceptance criteria, priority, and defer |
| **Spec & Slices** | `grill-with-docs`, `to-spec`, `to-tickets` | Unchanged: specs and tickets stay focused on behaviour |
| **Build** | `implement`, `tdd`, `codebase-design`, `wizard` | Unchanged: the implementer stays lean and focused on code |
| **Review & Diagnose** | `code-review`, `diagnosing-bugs` | `code-review` stays the per-change code review; `explain-diff` runs `production-readiness-check` as the final check once every change is in place, and that check calls `infra-and-deploy`, `observability`, and `external-integration-design` |

## Lean build, wide final check

The implementer and its per-change review (`implement`, `tdd`, `code-review`) should stay lean and focused on code: does it do what the ticket asks, and does it follow the repo's standards. Production concerns (infrastructure and deployment parity, observability, external-integration resilience) only make sense against the whole change, so they wait until every change is in place. Then `explain-diff` runs `production-readiness-check` as the final check over all the new commits, and that is the only place `infra-and-deploy`, `observability`, and `external-integration-design` are called. Their descriptions are kept minimal so they do not fire during the build.

## Linking skills

[link-skills.sh](./link-skills.sh) links the selected engineering, productivity, and personal skills into `~/.agents/skills`.

```bash
bash skills/favetelinguis/link-skills.sh
```

Edit the `skills` list in the script to choose what is installed. All 30 selected skills are included. Remove or comment out an entry and rerun to unlink it. New skills must be added to the list explicitly.

Running the script repeatedly is safe. It replaces selected symlinks, refuses to overwrite real files or directories, and only removes deselected links pointing to this checkout. Unrelated skills stay installed.

The same script links the executables listed in its `scripts` array from [scripts/](./scripts) into `~/.local/bin`. On macOS, add `~/.local/bin` to `PATH`; the script prints a note when it is missing.

- **[wt-review](./scripts/wt-review)**: `wt review <pr-number|branch>` opens a throwaway worktree where the whole change shows as unstaged edits, so any editor's gutter and diff view drive the review. Needs `wt` and, for PR numbers, `gh`. Finish with `wt remove --force review/<target>`.

## Mise install setup

Tools are installed with [mise](https://mise.jdx.dev). The personal config lives at `~/.config/mise/config.toml`, outside this repository. Every tool is set to `"latest"`, so `mise install` fetches the newest release.

Two tools in that config come from GitHub releases:

- **[beads_rust](https://github.com/Dicklesworthstone/beads_rust)** (`"github:Dicklesworthstone/beads_rust"`) installs the `br` binary. It is the Rust port of Beads, and it is the Beads backend these skills use in place of `bd`.
- **[abacus](https://github.com/chrisedwards/abacus)** (`"github:chrisedwards/abacus"`) installs the `abacus` terminal UI. It shows a Beads database as a tree. It reads both `bd` and `br` projects.

Common commands:

```bash
mise install   # install every tool in the config that is missing
mise ls        # show installed versions and where each one is set
mise prune     # remove installed versions that the config no longer uses
```

`mise prune` removes every installed tool that is not in the config. Run `mise prune --dry-run` first to see what it would remove.

The Herdr shortcut `prefix+f` (cmd 9) opens an `abacus` tab in the active pane's folder. If the tab already exists, it focuses that tab instead.
