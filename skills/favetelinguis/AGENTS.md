# Personal skills

This bucket holds personal skills: **specializations** of the workflow in `engineering/` and `productivity/` for personal repositories and conventions. Write each one as if it shipped beside its base skill: same structure, same rules as the root `AGENTS.md` except where this file says otherwise, and the voice of the upstream skills nearest to it (read two or three before drafting).

**Ownership.** Everything outside `skills/favetelinguis/` is Matt's upstream and read-only here: keep every edit inside this folder. When a personal skill needs an upstream skill to behave differently, carry that change in the personal skill (see below), and leave the upstream file as `git pull` delivers it.

## Specializing

A specialization carries only the **delta** from its base skill: the repositories, tracker, and conventions that make the upstream workflow fit this use case. The base keeps owning everything else, so a `git pull` upstream still improves the personal skill.

Pick the lightest form that carries the delta:

1. **Configuration.** When the base skill already reads personal config (tracker locations, triage vocabulary), put the delta in that configuration, not in a skill.
2. **Wrapper.** When the base is model-invoked, call the Skill tool with it and add only the personal steps before or after.
3. **Fork.** When the base is user-invoked, the Skill tool cannot reach it (see `.agents/invocation.md`). Copy its steps, change only what the delta demands, and name the base on the first line under the title (`Specializes engineering/to-tickets.`) so drift against upstream is easy to spot.

Match the base's invocation unless the delta changes who should reach the skill. A skill with no base is fine; it still reaches upstream skills through the Skill tool wherever one fits.

## How this bucket differs

- **Not promoted.** Personal skills stay out of the top-level `README.md`, `.claude-plugin/plugin.json`, `docs/`, and `ask-matt`.
- **Bucket README.** List each skill in this folder's `README.md` as a flat list with a one-line description, the name linked to its `SKILL.md`, as `misc/` and `in-progress/` do.
- **Names.** Give each skill a name distinct from every upstream skill unless the human explicitly requests otherwise. `link-skills.sh` links by folder name into `~/.agents/skills`, so a shared name replaces the upstream link.
- **Install.** Add `favetelinguis/<name>` to the `skills` list in `link-skills.sh`.
