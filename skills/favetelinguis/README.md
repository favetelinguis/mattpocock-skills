# Personal

Personal skills that **complement** Matt's `engineering/` and `productivity/` skills rather than replacing them.

Matt's upstream skills own the core development loop (`grill-with-docs` -> `to-spec` -> `to-tickets` -> `implement` / `tdd` -> `code-review` -> `retro`). The skills in this folder stay strictly additive so every `git pull` from upstream continues to sharpen the base workflow while filling in personal tooling, production operations, and infrastructure gaps:

- **[explain-diff](./explain-diff/SKILL.md)**: Explain a diff or PR in your own words, get grilled until your model matches the code, and leave with review comments (complements `code-review` and `grilling`).
- **[external-integration-design](./external-integration-design/SKILL.md)**: Design resilient integrations with external systems and providers (complements `codebase-design` and `tdd` at third-party boundaries).
- **[infra-and-deploy](./infra-and-deploy/SKILL.md)**: Trace app-to-infrastructure chains across Helm, Kubernetes, AWS, Azure, Terraform, Bicep, Docker, and CI/CD, and surface what only a live deploy can verify (complements `implement`, `tdd`, and `wizard`).
- **[observability](./observability/SKILL.md)**: Instrument production code with structured logging, RED and USE metrics, OpenTelemetry tracing, symptom-based alerts, and runbooks (complements `diagnosing-bugs` and `implement`).
- **[ship-pr](./ship-pr/SKILL.md)**: Write a PR body with a visual summary, local vs deploy-only verification evidence, infrastructure chain trace, and rollback plan.

## How they fit into Matt's flow

| Upstream stage | Matt's skills | How `favetelinguis` complements it |
|---|---|---|
| **Setup & Tracker** | `setup-matt-pocock-skills`, `triage`, `wayfinder` | No personal add-on; upstream tracker setup applies as-is |
| **Spec & Slices** | `grill-with-docs`, `to-spec`, `to-tickets` | `infra-and-deploy` and `observability` separate locally testable seams from deploy-only seams and enforce expand-contract ticket ordering |
| **Build** | `implement`, `tdd`, `codebase-design`, `wizard` | `external-integration-design`, `observability`, and `infra-and-deploy` guide adapter resilience, permanent telemetry, and full `App -> Container -> Helm/K8s -> Cloud IaC -> CI/CD` parity |
| **Review & Diagnose** | `code-review`, `diagnosing-bugs` | `explain-diff` aligns the human reviewer's mental model with the diff; `observability` turns temporary debug probes into permanent signals |
| **Ship** | `implement`, `code-review` | `ship-pr` formats the visual PR summary and adds the `Unverified Until Deploy` warning, live plan/what-if commands, post-deploy telemetry checks, and rollback plan |

## Linking skills

[link-skills.sh](./link-skills.sh) links the selected engineering, productivity, and personal skills into `~/.agents/skills`.

```bash
bash skills/favetelinguis/link-skills.sh
```

Edit the `skills` list in the script to choose what is installed. All 30 selected skills are included. Remove or comment out an entry and rerun to unlink it. New skills must be added to the list explicitly.

Running the script repeatedly is safe. It replaces selected symlinks, refuses to overwrite real files or directories, and only removes deselected links pointing to this checkout. Unrelated skills stay installed.

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
