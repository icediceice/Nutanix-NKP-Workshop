# Claude Code — Project Directives

These rules apply to every Claude session working in this repository.

## 1. Smart-Index (MANDATORY)

Before reading any file whose path is not already in context, you **MUST** use the smart-index skill:

```
/smart-index
```

- Run `index_summarize` at session start and after every compaction event
- Use `index_batch` when you have 2+ unknowns (never loop index_query)
- Use `index_query` before any single unknown file read
- Never use bash `find`, `grep`, or `ls` to locate code — use index tools

## 2. Implementation Tracking (MANDATORY)

Whenever you begin implementing a multi-step task:

1. Read `IMPLEMENTATION.md` first to understand current state
2. Mark the task `[WIP]` in `IMPLEMENTATION.md` before starting
3. When complete, mark it `[x]` and update Architecture Notes if the schema/flow changed
4. On any context handoff, ensure `IMPLEMENTATION.md` reflects true current state

## 3. No Real Names

Never use real company or person names in code, comments, or examples.
Use generic placeholders: `Alex Chen`, `alex.chen@example.com`, `Acme Corp`, `Partner Workshop`.

## 4. Python 3.9 Compatibility

This project targets Python 3.9. Do NOT use:
- `str | None` union syntax (use `Optional[str]` from `typing`)
- `list[str]` subscripts (use `List[str]` from `typing`)
- `from __future__ import annotations` with Pydantic v2

## 5. Schema Changes

If you change the SQLAlchemy models (add/remove columns), you must also:
1. Delete `registration-app/backend/data/lab-manager.db` (SQLite auto-recreates)
2. Note the change in `IMPLEMENTATION.md` under Architecture Notes

## 6. Dry-Run Mode

All local development and testing uses `DRY_RUN=true` (set in `.env`).
Never make live Educates API calls unless explicitly instructed by the user.
