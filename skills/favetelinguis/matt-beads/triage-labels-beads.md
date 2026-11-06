# Triage Labels (Beads)

The skills speak in terms of two canonical category roles and five canonical state roles. In Beads (`bd`), categories map to issue types and states pair a canonical label with a Beads status so `bd ready` only surfaces actionable work.

## Category roles

| Role in `mattpocock/skills` | Beads `--type` (`-t`) | Meaning                        |
| --------------------------- | --------------------- | ------------------------------ |
| `bug`                       | `bug`                 | Something is broken            |
| `enhancement`               | `feature`             | New feature or improvement     |

Untriaged issues created with `bd create` default to `--type task` until triaged into `bug` or `feature` (`bd` also accepts `enhancement` as an alias for `feature`).

## State roles

| Role in `mattpocock/skills` | Label in Beads    | Status in Beads | Meaning                                                  |
| --------------------------- | ----------------- | --------------- | -------------------------------------------------------- |
| `needs-triage`              | `needs-triage`    | `blocked`       | Maintainer needs to evaluate; hidden from `bd ready`     |
| `needs-info`                | `needs-info`      | `blocked`       | Waiting on reporter; hidden from `bd ready`              |
| `ready-for-agent`           | `ready-for-agent` | `open`          | Fully specified, ready for an AFK agent (`bd ready`)     |
| `ready-for-human`           | `ready-for-human` | `open`          | Requires human implementation                            |
| `wontfix`                   | `wontfix`         | `closed`        | Will not be actioned (`bd close --force`)                |

## Applying a transition

Beads creates labels on first use, so no label-creation step is required.

- Move an issue to an active or waiting triage state:
  `bd -C <ws> update <id> -t <bug|feature> -s <open|blocked> --remove-label <old-state-label> --add-label <new-state-label>`
  (Omit `--remove-label` when the issue has no prior state label, and never pass the same label to both `--remove-label` and `--add-label` in one command.)
- Close an issue as `wontfix`:
  1. Post the closing explanation comment (`bd -C <ws> comments add <id> "..."`).
  2. Update the category and state label: `bd -C <ws> update <id> -t <bug|feature> --remove-label <old-state-label> --add-label wontfix`.
  3. Close the issue: `bd -C <ws> close <id> --force --reason "wontfix: <summary>"`.
