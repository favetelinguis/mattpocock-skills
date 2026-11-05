# Personal

Personal skills, including specializations for personal repositories and conventions.

- **[explain-diff](./explain-diff/SKILL.md)**: Explain a diff or PR in your own words, get grilled until your model matches the code, and leave with review comments.
- **[external-integration-design](./external-integration-design/SKILL.md)**: Design resilient integrations with external systems and providers.

[link-skills.sh](./link-skills.sh) links the selected engineering, productivity, and personal skills into `~/.agents/skills`.

```bash
bash skills/favetelinguis/link-skills.sh
```

Edit the `skills` list in the script to choose what is installed. All 29 selected skills are included. Remove or comment out an entry and rerun to unlink it. New skills must be added to the list explicitly.

Running the script repeatedly is safe. It replaces selected symlinks, refuses to overwrite real files or directories, and only removes deselected links pointing to this checkout. Unrelated skills stay installed.
