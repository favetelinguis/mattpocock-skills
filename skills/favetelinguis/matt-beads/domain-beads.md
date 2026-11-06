# Domain Docs (external workspace)

How the engineering skills consume and write domain documentation while keeping the target repository untouched.

## Before exploring, read these

Check both the repository root (for any existing committed domain docs) and the external workspace `<ws>`:

- **`<ws>/GLOSSARY.md`**, plus **`GLOSSARY.md`** or **`GLOSSARY-MAP.md`** at the repo root if present.
- **`<ws>/docs/adr/`**, plus **`docs/adr/`** (and `src/<context>/docs/adr/`) in the repo if present.

If any of these files do not exist, **proceed silently**. Do not flag their absence or suggest creating them upfront.

## Where `/domain-modeling` writes

To keep the target repository clean, write all new or updated domain artifacts to the external workspace `<ws>` unless the user explicitly asks to commit them to the repository:

```
<ws>/
├── GLOSSARY.md
└── docs/
    └── adr/
        ├── 0001-event-sourced-orders.md
        └── 0002-postgres-for-write-model.md
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `GLOSSARY.md`. Do not drift to synonyms the glossary avoids.

## Flag ADR conflicts

If your output contradicts an existing ADR in `<ws>/docs/adr/` or the repo's `docs/adr/`, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because..._
