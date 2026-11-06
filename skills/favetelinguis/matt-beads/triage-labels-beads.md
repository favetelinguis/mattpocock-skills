# Triage Labels (`beads_rust` / `br`)

The skills speak in terms of two canonical category roles and five canonical state roles. In `beads_rust` (`br`), categories map to issue types and states pair a canonical label with a `br` status so `br ready` only surfaces actionable work.

## Category roles

| Role in `mattpocock/skills` | `br` `--type` (`-t`) | Meaning                    |
| --------------------------- | -------------------- | -------------------------- |
| `bug`                       | `bug`                | Something is broken        |
| `enhancement`               | `feature`            | New feature or improvement |

Untriaged issues created with `br create` default to `--type task` until triaged into `bug` or `feature` (`br` also accepts `enhancement`).

## State roles

| Role in `mattpocock/skills` | Label in `br`     | Status in `br` | Meaning                                              |
| --------------------------- | ----------------- | -------------- | ---------------------------------------------------- |
| `needs-triage`              | `needs-triage`    | `blocked`      | Maintainer needs to evaluate; hidden from `br ready` |
| `needs-info`                | `needs-info`      | `blocked`      | Waiting on reporter; hidden from `br ready`          |
| `ready-for-agent`           | `ready-for-agent` | `open`         | Fully specified, ready for an AFK agent (`br ready`) |
| `ready-for-human`           | `ready-for-human` | `open`         | Requires human implementation                        |
| `wontfix`                   | `wontfix`         | `closed`       | Will not be actioned (`br close --force`)            |

## Applying a transition

`br` creates labels on first use, so no label-creation step is required.

- Move an issue to an active or waiting triage state:
  `br update <id> -t <bug|feature> -s <open|blocked> --remove-label <old-state-label> --add-label <new-state-label> --json`
  (Omit `--remove-label` when the issue has no prior state label, and never pass the same label to both `--remove-label` and `--add-label` in one command.)
- Close an issue as `wontfix`:
  1. Update the category and state label: `br update <id> -t <bug|feature> --remove-label <old-state-label> --add-label wontfix --json`.
  2. Close the issue with the explanation comment bound atomically: `br close <id> --force --transition-comment "<closing explanation>" --reason "wontfix: <summary>" --json`.
