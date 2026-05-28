# jstack Backend-Hardening + Token-Diet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use jstack:subagent-driven-development (recommended) or jstack:executing-plans to implement this plan by executable slices. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the jstack pipeline's back end (verification gate, parallel dispatch, debugging discipline) structurally invoked, consolidate review skills, thread a context-discipline principle into I/O-heavy skills, and trim the top-4 skills net-smaller.

**Architecture:** Edit 11 skill `SKILL.md` files + 2 pointer files in the jstack repo, plus `~/.claude/CLAUDE.md` (harness config, outside the repo). Principles live in skills (tool-agnostic); the context-mode mechanism is named once in CLAUDE.md. Enforcement is skill-level hard-call (no settings.json Stop hook). Tasks are file-centric so no file is touched by two tasks.

**Tech Stack:** Markdown skills, bash test harness (`tests/jstack-static/run.sh`, `tests/skill-triggering/`).

**Plan Fidelity:** Interface-Level — new content is written verbatim (it is the deliverable); diet trims are specified by section + protected-string guard rather than full rewrites, because the implementer must read each file's current prose to compress it accurately.

**Spec:** `docs/jstack/specs/2026-05-29-jstack-backend-hardening-token-diet-design.md`

**Commit policy (user override):** Do NOT commit per task. The skill's frequent-commit default is overridden by the user's explicit "one commit at the end" instruction. All repo changes land in a single commit in Task 12.

---

## Global invariants (apply to EVERY task)

- **Never remove static-contract strings** (spec §4). After any edit, the file must still satisfy `tests/jstack-static/run.sh`.
- **KEEP verbatim:** Iron Laws, Red Flags tables, Common Rationalizations lists, hard-gate directives.
- **Diet rubric:** DELETE pure persuasion/preview; TIGHTEN behavior-signal-but-verbose; KEEP load-bearing (spec §5 ⑥).
- **Additions are terse** (one line / minimal section), so each top-4 file is net-neutral-to-smaller.
- Work happens in worktree `feat+jstack-backend-hardening` (branch `worktree-feat+jstack-backend-hardening`, based on local main `7f7f631`).

---

## Task 1: CLAUDE.md context-routing engine + debugging-entry line  (⑤ engine, ③)

**Files:**
- Modify: `~/.claude/CLAUDE.md` (harness config — OUTSIDE the jstack repo; NOT part of the Task 12 commit)

> Dependency: do this first — Tasks 5/9 reference `CLAUDE.md context_routing` by name.

- [ ] **Step 1: Insert `<context_routing>` block** immediately after the `</search_discipline>` block:

```
<context_routing>
When context-mode tools are available, route work to keep raw bytes out of context:
- Wide / unpredictable-output search (repo-wide grep, log scan, "where is X used") → `ctx_batch_execute(commands, queries)`; raw matches stay in the sandbox, only matched sections return.
- Narrow / fixed-output check (does a symbol exist, 1-2 lines, a file you will Edit) → native Grep / Glob / Read.
- Test / build / diff output → `ctx_execute(language:"shell", code:"<command>", intent:"failing tests")` (ctx_execute requires language+code; intent indexes large output) or `ctx_batch_execute`; surface only failures / relevant sections.
- Always scope from owned paths (src/, tests/, docs/) before widening.
When context-mode is unavailable, use native tools with the same narrow, owned-path discipline.
</context_routing>
```

- [ ] **Step 2: Add the debugging-entry line** to the `<core_workflow>` block (after the numbered pipeline):

```
When stuck mid-implementation, jstack:systematic-debugging is the first gate; codex:rescue is the escalation after the discipline, not the entry point.
```

- [ ] **Step 3: Verify** — Run: `grep -c "context_routing" ~/.claude/CLAUDE.md` → Expected: `2` (open+close). Run: `grep -c "first gate; codex:rescue" ~/.claude/CLAUDE.md` → Expected: `1`.

**Acceptance:** both greps return the expected counts; no other CLAUDE.md content changed.

---

## Task 2: peer-review absorb + requesting-code-review redirect  (④, ⑥)

**Files:**
- Modify: `skills/peer-review/SKILL.md`
- Modify: `skills/requesting-code-review/SKILL.md`

> Dependency: must precede Task 3 (reference sweep).

- [ ] **Step 1: Add a concise "When to Request" + "Red Flags" section to `peer-review/SKILL.md`** (absorbed from requesting-code-review — only what peer-review lacks). Insert after the `## Modes` section:

```markdown
## When to Request

Request an outside review when: completing a task or major feature, before merging, or before any security/auth/payments/live-risk change. Reviewing your own work in the same context is not a substitute — the point is an independent lane.

## Red Flags (review-avoidance rationalizations)

| Thought | Reality |
|---|---|
| "It's a small change, skip review" | Small diffs hide the costliest bugs. Request it. |
| "I already checked it myself" | Self-review in the authoring context is not independent. |
| "Tests pass, so it's fine" | Tests prove what you thought to test, not what you missed. |
| "Review will slow me down" | A closed PR slows you down more. |
```

- [ ] **Step 2: Diet `peer-review/SKILL.md`** — it has no persuasion/preview sections, so trim is minimal: only collapse any obviously duplicated sentence in the absorbed text. **Preserve verbatim** the static-contract strings: the line containing `--add-dir "$REPO_ROOT" -- "Reply with OK."` and the line containing `stdin=subprocess.DEVNULL`.

- [ ] **Step 3: Replace `requesting-code-review/SKILL.md` body with a redirect** (keep the YAML frontmatter intact so triggering still works; the body must retain a `jstack:` string for the static contract):

```markdown
# Requesting Code Review

This skill is consolidated into **jstack:peer-review**. Use `jstack:peer-review` with mode `review` (diff against base) or `plan` (spec/plan). peer-review owns reviewer routing (Codex/Claude), the prompt boundary, commands, artifacts, and finding triage. See the `## When to Request` and `## Red Flags` sections there.
```

- [ ] **Step 4: Verify** — Run: `bash tests/jstack-static/run.sh` → Expected: `[PASS] jstack static contract` (this checks `requesting-code-review` still contains `jstack:`, and peer-review still has both preflight strings). Run: `grep -c "When to Request" skills/peer-review/SKILL.md` → Expected: `1`.

**Acceptance:** static contract PASS; peer-review has the absorbed sections; requesting-code-review is a redirect retaining `jstack:peer-review`.

---

## Task 3: reference sweep  (④)

**Files:**
- Modify: `skills/using-jstack/references/codex-tools.md`
- Modify: `skills/subagent-driven-development/code-quality-reviewer-prompt.md`

> Dependency: after Task 2.

- [ ] **Step 1: Inspect each inbound reference.** Run: `grep -n "requesting-code-review" skills/using-jstack/references/codex-tools.md skills/subagent-driven-development/code-quality-reviewer-prompt.md`

- [ ] **Step 2: Repoint** each reference from `requesting-code-review` to `peer-review` (mode `review`), preserving the surrounding sentence's intent. If a reference is purely illustrative of the old name, update it to `jstack:peer-review`.

- [ ] **Step 3: Verify** — Run: `grep -rl "requesting-code-review" skills/` → Expected: only `skills/requesting-code-review/SKILL.md` (the redirect file itself). The three exempt files (README.md, RELEASE-NOTES.md, docs/plans/...) are outside `skills/` and not checked.

**Acceptance:** no `skills/**` file other than the redirect references the old skill.

---

## Task 4: writing-plans — Test-first + Parallel fields + context principle + diet  (①②⑤⑥)  [parallel-safe]

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

- [ ] **Step 1: Add two one-line fields to the `## Task Structure` task template**, in the `**Files:**` block region (after the Files bullet list, before Step 1 of the template):

```markdown
**Test-first:** [name the RED test this slice adds, or "N/A — no behavior change" + reason]
**Parallel:** [parallel-safe | sequential: needs Task N]
```

- [ ] **Step 2: Add the context principle** to the planning guidance (near `## File Structure` exploration): one line —

```markdown
When exploring the codebase to ground the plan, scope searches from owned paths and keep wide/unpredictable-output searches out of your context (see CLAUDE.md context_routing if available; otherwise narrow native search).
```

- [ ] **Step 3: Diet** — DELETE the `## Overview` preview section (~14L) if it only re-states the intro. **Preserve verbatim** static-contract strings: `docs/jstack/plans`, `JSTACK REVIEW REPORT`, `tracer bullet`, `horizontal slice`, `jstack:peer-review plan`, `jstack:`. Do NOT reintroduce `Alternating Model Review | GPT-5.4 review | Opus review`.

- [ ] **Step 4: Verify** — Run: `bash tests/jstack-static/run.sh` → `[PASS]`. Run: `grep -c "Test-first:" skills/writing-plans/SKILL.md` ≥ 1 and `grep -c "Parallel:" skills/writing-plans/SKILL.md` ≥ 1.

**Acceptance:** fields present in template; static contract PASS; file net-neutral-to-smaller.

---

## Task 4b: brainstorming — context principle + lightest-touch diet  (⑤⑥)  [parallel-safe]

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

> Lightest touch — pipeline entry point. Add one line; trim only obvious redundancy.

- [ ] **Step 1: Add the exploration principle** near the "Explore project context" / Problem Framing area:

```markdown
When exploring project context, scope searches from owned paths and keep wide/unpredictable-output searches out of context (CLAUDE.md context_routing if available; otherwise narrow native search).
```

- [ ] **Step 2: Diet (lightest)** — remove an obviously redundant restatement only if one exists; do NOT force a deletion. **Preserve verbatim** the static-contract strings: `docs/jstack/specs`, `Problem Framing Gate`, `jstack:peer-review plan`, `CONTEXT.md`, `ADR`. Do NOT reintroduce `Alternating Model Review | GPT-5.4 review | Opus review`.

- [ ] **Step 3: Verify** — Run: `bash tests/jstack-static/run.sh` → `[PASS]`. Run: `for s in "docs/jstack/specs" "Problem Framing Gate" "jstack:peer-review plan" "CONTEXT.md" "ADR"; do grep -q "$s" skills/brainstorming/SKILL.md || echo "MISSING: $s"; done` → Expected: no output.

**Acceptance:** principle line added; all 5 contract strings intact; static contract PASS.

---

## Task 5: subagent-driven-development — parallel rule + completion verify + gather line + diet  (①②⑤⑥)  [parallel-safe]

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

- [ ] **Step 1: Add parallel-dispatch rule** to `## Orchestration Strategy`:

```markdown
When consecutive plan tasks are tagged `parallel-safe` and share no files or state, dispatch them concurrently in one batch via jstack:dispatching-parallel-agents — do not run them sequentially.
```

- [ ] **Step 2: Add completion-verification hard-call** to `## Handling Implementer Status` (before marking a slice complete):

```markdown
Before marking a slice complete, invoke jstack:verification-before-completion against the slice's claims: confirm the test named in the task's `Test-first:` field actually ran and passed. No verification evidence → not complete.
```

- [ ] **Step 3: Add gather line** to `## Prompt Templates` (implementer prompt):

```markdown
Gather context with searches scoped to owned paths; route wide/unpredictable-output searches through processing tools when available (CLAUDE.md context_routing) so raw output stays out of your context.
```

- [ ] **Step 4: Diet** — DELETE the `## Advantages` section (~32L, pure persuasion). **Preserve verbatim**: `jstack:peer-review challenge`, `jstack:`.

- [ ] **Step 5: Verify** — Run: `bash tests/jstack-static/run.sh` → `[PASS]`. Run: `grep -c "Advantages" skills/subagent-driven-development/SKILL.md` → Expected: `0`. Run: `grep -c "dispatching-parallel-agents" skills/subagent-driven-development/SKILL.md` ≥ 1.

**Acceptance:** three additions present; Advantages gone; static contract PASS.

---

## Task 6: finishing-a-development-branch — verification gate  (①)  [parallel-safe]

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md`

- [ ] **Step 1: Add a hard-call to `### Step 1: Verify Tests`** (at the top of that step, before running the suite):

```markdown
Gate: invoke jstack:verification-before-completion first. Do not present integration options (Step 4) until verification evidence is collected and the suite passes.
```

- [ ] **Step 2: Verify** — Run: `grep -c "verification-before-completion" skills/finishing-a-development-branch/SKILL.md` ≥ 1. Run: `bash tests/jstack-static/run.sh` → `[PASS]`.

**Acceptance:** gate line present in Step 1; static contract PASS.

---

## Task 7: verification-before-completion — invoked-by pointer + diet  (①⑥)  [parallel-safe]

**Files:**
- Modify: `skills/verification-before-completion/SKILL.md`

- [ ] **Step 1: Add invoked-by pointer** near the top (after `## Overview` or `## The Iron Law`):

```markdown
**Invoked by:** writing-plans `Test-first:` checks · finishing-a-development-branch Step 1 · subagent-driven-development slice completion.
```

- [ ] **Step 2: Diet** — DELETE `## Why This Matters` (~9L) and `## The Bottom Line` (~8L) (pure persuasion). KEEP `## The Iron Law`, `## The Gate Function`, `## Red Flags - STOP`, `## Rationalization Prevention` verbatim.

- [ ] **Step 3: Verify** — Run: `grep -c "Invoked by:" skills/verification-before-completion/SKILL.md` → `1`. Run: `grep -c "Why This Matters\|The Bottom Line" skills/verification-before-completion/SKILL.md` → `0`. Run: `bash tests/jstack-static/run.sh` → `[PASS]`.

**Acceptance:** pointer added; two persuasion sections gone; gate/iron-law content intact.

---

## Task 8: dispatching-parallel-agents — auto-trigger note + diet  (②⑥)  [parallel-safe]

**Files:**
- Modify: `skills/dispatching-parallel-agents/SKILL.md`

- [ ] **Step 1: Add auto-trigger note** to `## When to Use`:

```markdown
Auto-triggered: when a plan tags tasks `parallel-safe`, subagent-driven-development dispatches them through this skill without a separate decision step.
```

- [ ] **Step 2: Diet** — DELETE `## Key Benefits` (~7L) and `## Real-World Impact` (~9L); DELETE `## Overview` (~8L) if it only previews. KEEP `## The Pattern`, `## Common Mistakes`, `## When NOT to Use`, `## Verification` verbatim.

- [ ] **Step 3: Verify** — Run: `grep -c "Auto-triggered" skills/dispatching-parallel-agents/SKILL.md` → `1`. Run: `bash tests/jstack-static/run.sh` → `[PASS]`.

**Acceptance:** auto-trigger note present; persuasion sections gone.

---

## Task 9: systematic-debugging — codex:rescue escalation + Phase-1 principle + diet  (③⑤⑥)  [parallel-safe]

**Files:**
- Modify: `skills/systematic-debugging/SKILL.md`

- [ ] **Step 1: Add `## Escalation to codex:rescue`** after `### Phase 3: Hypothesis and Testing`:

```markdown
## Escalation to codex:rescue

Run Phases 1-3 first — one hypothesis at a time. Escalate to `codex:rescue` ONLY when:
- a root-cause hypothesis survives repeated falsification attempts and you still cannot localize the defect, or
- the investigation is cycling (same hypotheses re-tried with no new evidence).

codex:rescue is a second pair of eyes AFTER the discipline, not a replacement for Phase 1. Bring your surviving hypothesis and the evidence that killed the others.
```

- [ ] **Step 2: Add Phase-1 context principle** inside `### Phase 1: Root Cause Investigation`:

```markdown
When reading logs/output for root cause, route large captures through processing tools (CLAUDE.md context_routing) and inspect summaries — do not dump raw logs into context.
```

- [ ] **Step 3: Diet** — DELETE `## Real-World Impact` (~8L). TIGHTEN `## your human partner's Signals You're Doing It Wrong` (~11L) to a compact bullet list — do NOT delete (it carries a behavioral signal). KEEP `## The Iron Law`, `## Red Flags - STOP and Follow Process`, `## Common Rationalizations` verbatim. **Preserve** `hitl-loop.template.sh` reference.

- [ ] **Step 4: Verify** — Run: `grep -c "Escalation to codex:rescue" skills/systematic-debugging/SKILL.md` → `1`. Run: `grep -c "hitl-loop.template.sh" skills/systematic-debugging/SKILL.md` ≥ 1. Run: `bash tests/jstack-static/run.sh` → `[PASS]`.

**Acceptance:** escalation section + Phase-1 line present; Signals tightened not deleted; hitl reference intact; static contract PASS.

---

## Task 10: test-driven-development — diet  (⑥)  [parallel-safe]

**Files:**
- Modify: `skills/test-driven-development/SKILL.md`

- [ ] **Step 1: Diet** — TIGHTEN `## Why Order Matters` (~50L) to ≤10 lines (keep the core reason, drop repetition). DELETE `## Overview` (~8L) if it only previews. KEEP `## The Iron Law`, `## Red-Green-Refactor`, `## Common Rationalizations`, `## Red Flags - STOP and Start Over` verbatim.

- [ ] **Step 2: Verify** — Run: `bash tests/jstack-static/run.sh` → `[PASS]`. Confirm file is meaningfully smaller (record line delta).

**Acceptance:** Why Order Matters compressed; iron-law/red-flags intact.

---

## Task 11: receiving-code-review — diet  (⑥)  [parallel-safe]

**Files:**
- Modify: `skills/receiving-code-review/SKILL.md`

- [ ] **Step 1: Diet** — DELETE `## Overview` (~6L, preview) and `## The Bottom Line` (~8L, persuasion). KEEP all Red Flags / rationalization / discipline content verbatim.

- [ ] **Step 2: Verify** — Run: `bash tests/jstack-static/run.sh` → `[PASS]`.

**Acceptance:** two sections gone; discipline content intact.

---

## Task 12: Verification gate + single commit

**Files:** none new — runs gates and commits the worktree.

- [ ] **Step 1: Static contract (HARD GATE)** — Run: `bash tests/jstack-static/run.sh` → Expected: `[PASS] jstack static contract`.

- [ ] **Step 2: Triggering tests (HARD GATE)** — Run: `tests/skill-triggering/run-all.sh` (and `tests/explicit-skill-requests/`, `tests/subagent-driven-dev/` if their runners exist). Expected: pass. If a `description:` frontmatter changed, confirm triggering still passes.

- [ ] **Step 3: Token before/after** — compute `chars/4` per edited top-4 skill; confirm each is ≤ its pre-change size. Record the delta table in the commit body.

- [ ] **Step 4: Reference integrity** — Run: `grep -rl "requesting-code-review" skills/` → only the redirect file.

- [ ] **Step 5: Load-bearing diff check** — Run: `git diff` and confirm no Iron Law / Red Flags / Common Rationalizations / gate directive lines were removed (only persuasion/preview/redundancy).

- [ ] **Step 5b: Edited-skill smoke (HARD GATE, spec §7)** — for each of the 11 edited skill files, confirm it loads and reads coherently: valid YAML frontmatter (`name`/`description` present) and the body parses with no dangling/broken section. Run: `for f in peer-review requesting-code-review writing-plans brainstorming subagent-driven-development finishing-a-development-branch verification-before-completion dispatching-parallel-agents systematic-debugging test-driven-development receiving-code-review; do head -1 "skills/$f/SKILL.md" | grep -q '^---' || echo "FRONTMATTER? $f"; done` → Expected: no output. Then read each edited section once to confirm coherence.

- [ ] **Step 6: Single commit** (per spec §5.0 "Committed alongside" + "Bundled pre-existing session change": the commit includes the 13 in-repo behavioral files + the 2 pointer files + spec + plan + opus 4.7→4.8 refresh. The opus refresh is logically separate but bundled per the user's one-commit instruction.) (all repo changes: opus 4.7→4.8 edits + all skill edits + spec + this plan). CLAUDE.md is outside the repo and is NOT committed here.

```bash
git add -A
git commit -m "feat: harden jstack pipeline back-end + token diet

- verification/parallel/debugging discipline now skill-level hard-called
- systematic-debugging escalates to codex:rescue after Phases 1-3
- requesting-code-review consolidated into peer-review
- context-routing principle threaded into I/O-heavy skills (mechanism in CLAUDE.md)
- top-4 skills trimmed net-smaller; load-bearing content preserved
- opus 4.7 -> 4.8 reviewer-model references

Token deltas: <fill from Step 3>"
```

- [ ] **Step 7: Report** the commit SHA, token delta table, and that CLAUDE.md was edited separately (outside repo).

**Acceptance:** all gates pass; one commit on the worktree branch; token deltas reported.

---

## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Spec Review | Codex | 2 | Pass (8 findings applied) | see spec §JSTACK REVIEW REPORT | `.jstack/artifacts/peer-review-codex-plan-20260528T222650Z.md` |
| Plan Review | Codex (fast) | 1 | Pass (3 findings applied) | opus refresh + artifact/doc commit scope documented in spec §5.0; edited-skill smoke gate added (Task 12 Step 5b) | reconciled into spec §5.0 + plan Task 12 |
| Peer Review | Codex | 0 | Deferred to post-implementation diff review | - | - |
| Adversarial Review | Codex | 0 | N/A (no live-risk surface) | - | - |
| Verification | Local tests | 1 | Pass | static contract PASS; frontmatter invariant intact (triggering preserved); top-4 each ≤ pre-change except brainstorming (spec lightest-touch exception); aggregate −1161 tok; load-bearing diff clean | inline (Task 12) |
| Live Evidence | n/a | 0 | N/A | - | - |

---

## Execution notes

- **Lane:** Tasks 4-11 are `parallel-safe` (distinct files). Tasks 1, 2→3 are sequential prerequisites. Task 12 is the final gate.
- **Diet judgment** (DELETE vs TIGHTEN) needs the orchestrator's eye on actual prose — keep the spec §4/§5⑥ rubric open while editing.
