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

## `!!` — Engage

**STOP.** Whatever you were doing, halt it now.

Read `.claude/active-plan.md`. Then acknowledge out loud:
- Active step and its goal
- Tier
- File boundary
- What you were doing when `!!` fired
- Whether that matches the plan

**If there is no active plan** → fire `Skill("session-start")`.
**If there is an active plan** → state what you were doing, state what the plan says the current step is, and explicitly call out any mismatch before resuming. Do not silently self-correct.

Resync `active-plan.md` if anything is stale or wrong. Then state the next action and which skills will fire. Wait for confirmation if a mismatch was found.

---

## RULES — ABSOLUTE. VIOLATION IS FAILURE.

**0. Session start — `Skill("session-start")` FIRST.**
Run session initialization before any work. Not later. NOW.

**1. `Skill("smart-index")` FIRST — before any code related action.**
`index_query` (1 unknown) or `index_batch` (2+). NEVER grep, find, ls, Glob, Grep, Read, or Search. No exceptions unless skip condition is met.  ALWAYS call Bash with timeout: 600000 (10 min).
Smart-index save your context and returns a focused summary USE IT.
No efficiency argument exists for skipping it.
Knowing the file path alone is not enough to skip.
Allow to Skip ONLY when path AND exact function/section are confirmed.

**2. External docs → `Skill("nlm")` FIRST.**
`nlm ask` BEFORE any web search. Fallback: `docs/reference/` only.

**3. PROGRESS.md — historical record.**
Update on: task complete, blocker, direction change, session start/end.
Every entry MUST have "Known issues" (or "No known issues").

**4. File boundary is law.**

**5. Skills are atomic. Skills are not one-time.**
Complete IN FULL before returning. No interleaving. No "later."
Per-step skills (active-plan, commit-and-log) fire EVERY step.
This is not redundant — this is how your work survives compaction.
Without it, your next context has no record and the task fails.

**6. active-plan first — no other skill substitutes for it.**
Design, interface, brainstorm, or any other skill produces INPUT to the plan. Not a replacement.

**7. ALL work is protocol work.**
Troubleshooting, debugging, investigation, research, refactoring — no category of work bypasses this protocol. If you're touching code or reading logs, you're in EDCR.

**8. No speculative fixes.**
NEVER change code to "see if it helps." Every edit must follow from a confirmed hypothesis or an approved plan. Undo anything that doesn't pass verification.

**9. Tier selection is the effort lever.**
Start at Tier 2 (Sonnet). Tier IS effort in Claude — no separate parameter exists. Do not escalate preemptively. Escalate only when Sonnet cannot resolve the problem. Check `.claude/references/tiering.md` when the choice is unclear.

**10. Escalation is a context switch.**
When blocked: snapshot state → switch from Tier 2 (Sonnet) to Tier 1 (Opus) for deeper reasoning, or delegate bounded work to Tier 3 (Haiku) → reintegrate summary into active plan before continuing.

**11. Drift guard every step.**
Before reading, editing, committing, or delegating, confirm the action still matches the active step goal, file boundary, tier, and current hypothesis. If any of those changed, stop and resync `active-plan.md` before continuing.

**12. Active plan is mandatory working memory.**
No substantive work without an up-to-date `.claude/active-plan.md`. On task start, after discovery, before first edit, after verification, before delegation, and before commit/pause/end, update the plan. Keep updates compact: modify only the fields that changed.

---

## PROGRESS.md Format

Append-only log. ~2–5 entries per session. Every entry MUST have "Known issues" (or "No known issues").
Compact when >60 lines: preserve last 10 entries verbatim, summarize earlier into `### Session Context` at top.

**Purpose:** After compaction, `!!` must be sufficient to re-engage with full rule compliance.

---

## SESSION START
`Skill("session-start")` — complete every step.

## TASK RECEIVED
Active plan `in-progress` → ask user: pause or finish first.

**Classify first:**
- **Implementation** — new feature, refactor, migration → SIZE → PLANNING → EXECUTION.
- **Troubleshooting** — bug, error, regression, "fix", "debug", "broken", performance issue → SIZE → DIAGNOSIS → PLANNING → EXECUTION.

**Size:** S (single file, obvious, implementation only) → approval → EXECUTION. M/L → next phase.
**Debug/troubleshooting tasks are NEVER Size S.** Minimum M.
**Tier override:** Check PROGRESS.md `### Tier Overrides`.

## DIAGNOSIS (troubleshooting only)
**Mandatory before PLANNING. No code changes during diagnosis.**
**Smart-index gathers context. Claude reasons about cause. Never delegate diagnosis reasoning to a lower tier.**

1. **Reproduce** — confirm the failure. Exact error, stack trace, or behavioral description.
   Cannot reproduce → reproducing IS the first task. Stop until reproduced.
2. **Gather context** — site unclear → `index_trace` to map call chain and blast radius.
   Site known → `index_analyze` to pull related code. Read directly.
   Smart-index finds the *where*. Claude figures out the *why*.
3. **Hypothesize** — ONE root-cause hypothesis in `active-plan.md` BEFORE any fix.
   Format: `Symptom: X | Hypothesis: Y causes X because Z | Verify by: [specific check]`
4. **Verify hypothesis** — read code, add temporary logging, inspect state. NO fix code changes.
   Wrong → back to step 2 with new info. **Max 3 cycles → ESCALATION.**
5. **Confirmed** → proceed to PLANNING with root cause established.

## PLANNING

2. Check `.claude/references/tiering.md` if escalation/delegation needed
3. Write plan per `Skill("active-plan")` format → `.claude/active-plan.md`
   Troubleshooting plans MUST include: root cause, fix strategy, verification criteria, rollback step.
4. Present to user → on approval: Status `in-progress`

Size M → inline pre-execute (paths confirmed? git clean? correct branch?).
Size L → PRE-EXECUTE separately.

## PRE-EXECUTE
Size L only. Paths confirmed via index, git clean, correct branch. Fail → stash/commit first.

## EXECUTION

**Implementation:**
Drift check → `[>]` → Build/Edit → Verify (lint→test→build) → `Skill("commit-and-log")` → `[x]`.

**Troubleshooting:**
Drift check → `[>]` → Apply fix → Verify (original failure resolved + no regressions) →
  Pass → `Skill("commit-and-log")` → `[x]`
  Fail → `git restore` → update hypothesis in `active-plan.md` → return to DIAGNOSIS step 3. Do NOT stack fixes.

**Both:**
Unknown location → `Skill("smart-index")`.
Blocked → diagnose → revert → if stuck → ESCALATION.
Unrelated issues → PROGRESS.md Task Queue. No context-switch.
Step scope drift (new goal, more than a few primary files, or changed verification target) → update active plan before continuing.
Discovery changes boundary or verify target → update active plan before reading further.

## DELEGATION
`Skill("delegation")` — complete the protocol.

## ESCALATION
All work committed. Alternative tried at current tier. Report via `.claude/templates/escalation-report.md`. Expected output is specific and verifiable.

After: `- [area] → minimum [Tier] — escalated from [tier] on [YYYY-MM-DD], reason: [one-line]`

## SESSION END
Stage + commit all work (even `wip:`) → push. PROGRESS.md entry. `active-plan.md`: done → clear; paused → keep state. Brief developer summary.
Compact PROGRESS.md if >60 lines.

## COMPACTION RECOVERY
Fire `!!` to re-engage. The `!!` block above is the complete protocol — follow it exactly.

---

## SKILL TRIGGERS

Every trigger fires. No rationalization. Uncertain whether it applies → it applies.

| Skill | Invoke | Trigger | Skip |
|-------|--------|---------|------|
| Session Start | `Skill("session-start")` | New session. `!!` routes here when no active plan exists. ALWAYS first. | NEVER |
| Active Plan | `Skill("active-plan")` | Creating plan. EVERY `[x]`. Pausing or completing plan. Per-step — survives compaction. | NEVER |
| Commit & Log | `Skill("commit-and-log")` | After ANY verified change. EVERY step boundary. Session end. | NEVER |
| Smart Index | `Skill("smart-index")` | ANY unknown path. ANY unknown failure cause. Architecture mapping. After compaction. | ONLY when path AND cause confirmed in context |
| NLM | `Skill("nlm")` | ANY external doc query. BEFORE any web search. | ONLY when notebook not configured |
| Delegation | `Skill("delegation")` | Spawning ANY sub-agent. Reviewing ANY agent return. | NEVER |

**Reference:** `.claude/references/tiering.md` — load only when choosing model tier.