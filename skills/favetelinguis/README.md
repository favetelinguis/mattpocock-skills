# Personal

Personal skills, including specializations for personal repositories and conventions.

- **[explain-diff](./explain-diff/SKILL.md)**: Explain a diff or PR in your own words, get grilled until your model matches the code, and leave with review comments.
- **[external-integration-design](./external-integration-design/SKILL.md)**: Design resilient integrations with external systems and providers.
- **[matt-beads](./matt-beads/SKILL.md)**: Use `beads_rust` (`br`) across single or multi-repo setups with Matt's engineering skills without forcing the team to migrate.

[link-skills.sh](./link-skills.sh) links the selected engineering, productivity, and personal skills into `~/.agents/skills`.

```bash
bash skills/favetelinguis/link-skills.sh
```

Edit the `skills` list in the script to choose what is installed. All 29 selected skills are included. Remove or comment out an entry and rerun to unlink it. New skills must be added to the list explicitly.

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
