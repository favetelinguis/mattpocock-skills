# Domain Docs (`beads_rust` / `br` workspace)

How the engineering skills consume and write domain documentation across single-repo and multi-repo `br` setups without forcing team repositories to commit personal files.

## Before exploring, read these

Check both the active `br` workspace root `<ws>` and the current repository root (when `<ws>` is a parent umbrella folder or a federated sibling repository):

- **`<ws>/GLOSSARY.md`** and **`<ws>/GLOSSARY-MAP.md`**, plus **`GLOSSARY.md`** or **`GLOSSARY-MAP.md`** in the current repository if present.
- **`<ws>/docs/adr/`**, plus **`docs/adr/`** (and `src/<context>/docs/adr/`) in the current repository if present.

If any of these files do not exist, **proceed silently**. Do not flag their absence or suggest creating them upfront.

## Where `/domain-modeling` writes

Write new or updated domain artifacts to `<ws>` (`<ws>/GLOSSARY.md`, `<ws>/GLOSSARY-MAP.md`, and `<ws>/docs/adr/`):

```
<ws>/
├── GLOSSARY.md
└── docs/
    └── adr/
        ├── 0001-event-sourced-orders.md
        └── 0002-postgres-for-write-model.md
```

In personal local mode, `/GLOSSARY.md`, `/GLOSSARY-MAP.md`, and `/docs/adr/` are excluded via `.git/info/exclude` (unless already tracked by the repository), so domain modeling never dirties `git status` or forces the team to adopt the files unless the user explicitly asks to commit them.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `GLOSSARY.md`. Do not drift to synonyms the glossary avoids.

## Flag ADR conflicts

If your output contradicts an existing ADR in `<ws>/docs/adr/` or a repository's `docs/adr/`, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because..._
