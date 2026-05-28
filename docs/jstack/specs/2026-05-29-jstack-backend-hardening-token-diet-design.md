# jstack Backend-Hardening + Token-Diet — Design Spec

- **Date:** 2026-05-29
- **Status:** Draft (pending peer-review gate + user approval)
- **Owner harness:** Personal fork of jstack/superpowers (`/Users/kakao1/.codex/jstack`). Push to the user's own jstack remote. **No upstream PR.**
- **Scope:** 14 files — `~/.claude/CLAUDE.md` + 11 skill `SKILL.md` + 2 pointer files (authoritative list in §5.0).

## 1. Problem

Behavioral telemetry across 2,492 sessions / 122,920 tool calls (2026-01-09 → 2026-05-28) shows the jstack pipeline's **front end is used heavily but the back end leaks**, and exploration floods context with raw output.

Skill-invocation counts:

| skill | invocations | signal |
|---|---|---|
| brainstorming | 121 | strong |
| writing-plans | 109 | strong |
| peer-review | 88 | strong |
| subagent-driven-development | 67 | ok |
| executing-plans | 26 | — |
| test-driven-development | **3** | mandatory by rule, effectively unused |
| verification-before-completion | **0** | pipeline terminal step, never invoked as a skill |
| systematic-debugging | **0** | replaced by `codex:rescue` (292 agent dispatches) |
| dispatching-parallel-agents | **0** | CLAUDE.md mandates parallelism; 0 parallel agent batches observed |

Other evidence:
- **Parallelism:** 1,300 `Agent` dispatches, **0** turns with ≥2 concurrent agent dispatches.
- **Debugging outsourced:** `codex:codex-rescue` agent invoked 292× vs `systematic-debugging` 0×.
- **Exploration floods context:** `Bash` = 58,736 calls (48% of all tool use); `grep` alone = 10,898, plus `cat`/`find`/`tail`/`sed`. `rg` only 1,142. Raw matches land directly in context.
- **context-mode works but is barely used:** kept 26.4 MB out of context in ~5 days (auto-capture + processing), yet `ctx_*` tools are only 0.8% of Bash volume — installed 2026-05-24, vast headroom untapped.

**Skills are loaded into context on every invocation**, so verbose high-frequency skills are a per-session token tax. Token weight × frequency:

| skill | ~tokens | freq | tok×freq |
|---|---|---|---|
| brainstorming | 3,967 | 121 | 480k |
| writing-plans | 3,938 | 109 | 429k |
| subagent-driven-development | 5,924 | 67 | 397k |
| peer-review | 1,911 | 88 | 168k |

The top 4 dominate the cumulative token cost.

## 2. Goals / Non-Goals

**Goals**
- Strengthen the pipeline's back end. Two distinct mechanisms, not one:
  - **Hard-call gate** (actually enforced): `verification-before-completion` is invoked by other skills at completion points; `dispatching-parallel-agents` is invoked when a plan tags parallel-safe tasks.
  - **Structural nudge** (not a gate): a `Test-first:` field in the plan task template makes test-first the default shape of every task. This is a prompt, not enforcement — the enforcement of "a test actually ran" happens at the verification gate, which checks the slice's test evidence. The spec does not claim TDD is hard-enforced.
- Connect `systematic-debugging` to `codex:rescue` so debugging discipline runs *before* escalation.
- Consolidate review skills: absorb the unique parts of `requesting-code-review` into `peer-review`.
- Thread a tool-agnostic "context discipline" principle into I/O-heavy skills; name the context-mode mechanism once in CLAUDE.md.
- Trim the top-4 skills so they come out **net smaller** despite additions.

**Non-Goals**
- No upstream PR; no `settings.json` Stop-hook gate (deferred — skill-level enforcement only).
- Do not edit the external `codex` plugin (`~/.claude/plugins/.../codex/`); the connection lives on the jstack side.
- Do not rewrite the project's voice or restructure for "compliance."
- No aggressive trim of 0-frequency skills beyond the safe-delete rubric (they cost ~0/session today).

## 3. Confirmed Decisions

1. **Principle in skill, mechanism in CLAUDE.md.** jstack skills carry only tool-agnostic principles so they don't break in sessions without context-mode (subagents/headless/CI). The context-mode mechanism (`ctx_batch_execute`/`ctx_execute`) is named once in CLAUDE.md.
2. **Skill-level hard-call enforcement only.** No `settings.json` Stop hook. Enforcement = one skill explicitly invoking another at a gate.
3. **Token-diet level = (a) safe deletions + (b) density trim of the top-4 skills.** Not the conservative-only nor the all-skills-aggressive option.

## 4. Constraints / Invariants

- **Load-bearing content is never cut:** Iron Laws, Red Flags tables, Common Rationalizations lists, hard-gate directives. These prevent the model from rationalizing away discipline — the telemetry (TDD 3, verification 0) shows discipline is fragile, so this core stays.
- **Additions are terse:** new fields are one line, not paragraphs; new sections are minimal. Each addition to a top-4 skill is offset by trimming nearby padding so the file is net-neutral-to-smaller.
- **References stay valid:** when `requesting-code-review` is slimmed to a redirect, every inbound reference must be updated in the same change.
- **brainstorming gets the lightest touch:** it is the pipeline entry point; trim only obvious redundancy.
- **The static contract is a hard invariant.** `tests/jstack-static/run.sh` greps for required strings; edits (especially the ⑥ diet and ④ slim) must not remove them. Protected strings include, per file:
  - `requesting-code-review`: must still contain `jstack:` (the redirect's `jstack:peer-review` satisfies this).
  - `peer-review`: `--add-dir "$REPO_ROOT" -- "Reply with OK."` and `stdin=subprocess.DEVNULL`.
  - `brainstorming`: `docs/jstack/specs`, `Problem Framing Gate`, `jstack:peer-review plan`, `CONTEXT.md`, `ADR`; and must NOT reintroduce `Alternating Model Review|GPT-5.4 review|Opus review`.
  - `writing-plans`: `docs/jstack/plans`, `JSTACK REVIEW REPORT`, `tracer bullet`, `horizontal slice`, `jstack:peer-review plan`, `jstack:`.
  - `subagent-driven-development`: `jstack:peer-review challenge`, `jstack:`.
  - `systematic-debugging`: `hitl-loop.template.sh`.
  - `architecture-deepening`: `deletion test` (not edited, but the test runs repo-wide — do not disturb).

## 5. Workstreams

### 5.0 Authoritative file list (edited surface)

This table is the **complete behavioral edit surface** — the files whose *content/behavior* this change modifies. 14 files: 1 config + 11 skill `SKILL.md` + 2 pointer files. No behavioral file outside it is modified.

Committed alongside but NOT behavioral edits (project documentation / session artifacts, expected in the commit): this spec, the implementation plan under `docs/jstack/plans/`, and peer-review artifacts under `.jstack/artifacts/`.

Bundled pre-existing session change (committed in the same branch per the user's one-commit instruction, logically separate from the hardening): the `claude-opus-4-7 → claude-opus-4-8` reviewer-model refresh across `skills/peer-review`, `skills/writing-plans`, `skills/requesting-code-review`, `skills/subagent-driven-development/code-quality-reviewer-prompt.md`. These edits already existed in the working tree before this spec and are reapplied in the worktree (see plan Task 12).

| # | file | type | workstreams |
|---|---|---|---|
| 1 | `~/.claude/CLAUDE.md` | config | ⑤ engine, ③ |
| 2 | `skills/writing-plans/SKILL.md` | skill | ①, ②, ⑤, ⑥ |
| 3 | `skills/subagent-driven-development/SKILL.md` | skill | ①, ②, ⑤, ⑥ |
| 4 | `skills/finishing-a-development-branch/SKILL.md` | skill | ① |
| 5 | `skills/verification-before-completion/SKILL.md` | skill | ①, ⑥ |
| 6 | `skills/dispatching-parallel-agents/SKILL.md` | skill | ②, ⑥ |
| 7 | `skills/systematic-debugging/SKILL.md` | skill | ③, ⑤, ⑥ |
| 8 | `skills/requesting-code-review/SKILL.md` | skill | ④ (slim to redirect) |
| 9 | `skills/peer-review/SKILL.md` | skill | ④ (absorb), ⑥ |
| 10 | `skills/brainstorming/SKILL.md` | skill | ⑤, ⑥ (lightest touch) |
| 11 | `skills/test-driven-development/SKILL.md` | skill | ⑥ |
| 12 | `skills/receiving-code-review/SKILL.md` | skill | ⑥ |
| 13 | `skills/using-jstack/references/codex-tools.md` | pointer | ④ reference repoint |
| 14 | `skills/subagent-driven-development/code-quality-reviewer-prompt.md` | pointer | ④ reference repoint |

**Explicitly NOT edited** (left as historical references): `README.md`, `RELEASE-NOTES.md`, `docs/plans/2025-11-28-skills-improvements-from-user-feedback.md`. The ④ reference sweep and the §7 grep gate apply to `skills/**` only; these three files are exempt by name.

### ⑤/engine — CLAUDE.md context-routing rule (do first; ⑤ depends on it)
Add to `~/.claude/CLAUDE.md` (near `<search_discipline>`) a `<context_routing>` block naming the mechanism:

> When context-mode tools are available:
> - **Wide / unpredictable-output search** (repo-wide grep, log scan, "where is X used") → `ctx_batch_execute(commands, queries)` so raw matches stay out of context.
> - **Narrow / fixed-output check** (does symbol exist, 1–2 lines, a file you will Edit) → native Grep / Glob / Read.
> - **Test / build / diff output** → run the command through `ctx_batch_execute(commands, queries)`, or `ctx_execute(language: "shell", code: "<command>", intent: "failing tests")` — `ctx_execute` requires `language` + `code`, and `intent` indexes the large output so only matching sections return. Surface only failures / relevant sections.
> - Always scope from owned paths (`src/`, `tests/`, `docs/`) before widening.
> When context-mode is unavailable, use native tools with the same narrow, owned-path discipline.

Also add one line to `<core_workflow>`: when stuck mid-implementation, `systematic-debugging` is the first gate; `codex:rescue` is the escalation, not the entry point.

### ① Back-end enforcement (skill-level hard-call)
- **writing-plans** `## Task Structure` (~L107): add a one-line `Test-first:` field to the task template — names the RED test for the slice. TDD becomes plan structure, not a separate skill call.
- **finishing-a-development-branch** `### Step 1: Verify Tests` (~L18): add a hard-call to `jstack:verification-before-completion` as a gate *before* the test run / option presentation.
- **subagent-driven-development** `## Handling Implementer Status` (~L236): before marking a task complete, hard-call `verification-before-completion` against the slice's claims.
- **verification-before-completion**: add a one-line "Invoked by: writing-plans tasks, finishing-a-development-branch Step 1, subagent-driven-development completion" pointer (discoverability). Offset by trimming this file's `Why This Matters` + `The Bottom Line` (see ⑥).

### ② Parallel-dispatch auto-trigger
- **writing-plans** `## Task Structure`: add a one-line `Parallel:` field (`parallel-safe` | `sequential: needs Task N`).
- **subagent-driven-development** `## Orchestration Strategy` (~L42): add a rule — when consecutive tasks are tagged `parallel-safe` and share no state, dispatch them concurrently in one batch via `jstack:dispatching-parallel-agents`.
- **dispatching-parallel-agents** `## When to Use`: add "auto-triggered when a plan tags tasks `parallel-safe`" to lower the activation threshold.

### ③ systematic-debugging ↔ codex:rescue (jstack side only)
- **systematic-debugging**: add an `## Escalation to codex:rescue` section after Phase 3 — run Phases 1–3 (one hypothesis at a time) first; escalate to `codex:rescue` only when a hypothesis survives repeated falsification or the investigation cycles. `codex:rescue` is second-eyes *after* discipline, not the entry point.
- (CLAUDE.md core_workflow line covered in the engine workstream.)

### ④ requesting-code-review → peer-review absorption (token-tight)
- Identify what `requesting-code-review` has that `peer-review` lacks: `When to Request` (trigger conditions) and `Red Flags` (review-avoidance rationalizations).
- Absorb only those into `peer-review`, concisely (no duplication of peer-review's existing Modes/Routing/Commands/Triage).
- Slim `requesting-code-review` to a thin redirect ("→ use `jstack:peer-review`"; must retain a `jstack:` string for the static contract) **and repoint inbound references under `skills/**`** (files 13–14 in §5.0) to `peer-review`. README / RELEASE-NOTES / docs/plans references are exempt (§5.0).

### ⑥ Token diet (level a + b)
**Per-section rubric** — every candidate section is classified into exactly one of:
- **DELETE** (pure persuasion / preview, no behavioral signal): `Advantages` (SDD ~32L), `Overview` preview sections that only re-list headings (8–14L each), `Why This Matters` + `The Bottom Line` (verification ~17L), `Real-World Impact` / `Key Benefits` (systematic-debugging, dispatching, receiving-code-review).
- **TIGHTEN, do not delete** (carries a behavioral signal but is verbose): `Why Order Matters` (TDD ~50L → a few lines) and `Signals You're Doing It Wrong` (systematic-debugging) — these shape behavior (they help the model notice it is rationalizing), so they are compressed, not removed. This resolves the §4 load-bearing tension: when in doubt, tighten not delete.
- **KEEP verbatim** (load-bearing, §4): Iron Laws, Red Flags tables, Common Rationalizations lists, hard-gate directives, and every static-contract string (§4).

**(a) Safe deletions** = apply the DELETE class above.

**(b) Density trim of top-4** (brainstorming, writing-plans, subagent-driven-development, peer-review): compress verbose process prose to imperative lines, collapse duplicate examples to one. Target: each top-4 file is net-neutral-to-smaller after its ① ② ④ ⑤ additions. brainstorming = lightest touch (obvious redundancy only).

**Keep:** all load-bearing content (§4).

## 6. Ordering / Dependencies

**Tasks are file-centric, not workstream-centric.** Each file is edited by exactly one task that applies *all* of its workstreams (additions + diet) in a single pass, so a file is never touched by two concurrent tasks. Parallel-safe means *different files*, never the same file.

Sequence:

1. **Task A (must be first):** `~/.claude/CLAUDE.md` — engine routing block (⑤) + core_workflow line (③). Everything else references this principle.
2. **Task B (must precede C-references):** `requesting-code-review` slim-to-redirect + `peer-review` absorb (④) + peer-review diet (⑥). Changes the peer-review surface that other skills link to; keep all static-contract strings.
3. **Task C — reference sweep:** repoint inbound references found in `using-jstack/references/codex-tools.md` and `subagent-driven-development/code-quality-reviewer-prompt.md` to `peer-review`. Depends on B.
4. **Parallel-safe batch (different files, dispatch together):**
   - `writing-plans` — ① `Test-first:` + ② `Parallel:` fields + ⑤ principle + ⑥ diet.
   - `subagent-driven-development` — ① completion verification call + ② parallel-dispatch rule + ⑤ subagent-gather line + ⑥ diet. (Note: C also edits a sibling file `code-quality-reviewer-prompt.md`, not `SKILL.md` — no conflict, but run C first to be safe.)
   - `finishing-a-development-branch` — ① verification hard-call.
   - `verification-before-completion` — ① invoked-by pointer + ⑥ diet.
   - `dispatching-parallel-agents` — ② auto-trigger note + ⑥ diet.
   - `systematic-debugging` — ③ escalation section + ⑤ Phase-1 principle + ⑥ tighten.
   - `test-driven-development` — ⑥ diet (tighten `Why Order Matters`).
   - `receiving-code-review` — ⑥ diet.
5. **Verification gate (§7)** after all tasks.

## 7. Verification / Success Evidence

- **Static contract (HARD GATE — must pass):** run `bash tests/jstack-static/run.sh`; it must print `[PASS] jstack static contract`. This is the regression guard for the protected strings in §4.
- **Triggering tests (HARD GATE):** run `tests/skill-triggering/run-all.sh` (and `tests/explicit-skill-requests/`, `tests/subagent-driven-dev/` if affected). Diet edits change skill bodies but must not change `description:` frontmatter in a way that breaks triggering; if a description must change, re-run and confirm.
- **Token check (objective):** re-run the token-count script (chars/4) before/after. Each top-4 skill must be ≤ its current size; report the delta table.
- **Reference integrity:** `grep -rl requesting-code-review skills/` — every hit must be either the redirect file itself (`skills/requesting-code-review/SKILL.md`) or already repointed to `peer-review`. The three exempt files (§5.0) are outside `skills/` (README, RELEASE-NOTES) or under `docs/plans/` and are not checked.
- **No load-bearing loss:** diff confirms no Iron Law / Red Flags / Rationalization / gate content removed.
- **Behavioral (prospective, not gating this change):** future telemetry should show non-zero `verification-before-completion`, `dispatching-parallel-agents`, and `systematic-debugging` invocations, and a lower raw-grep share. Noted as the real-world signal to check later, not a merge gate.
- **Smoke:** invoke each edited skill once and confirm it loads and reads coherently.

## 8. Risks

- **Behavior regression from trimming behavior-shaping skills.** Mitigation: the §4 load-bearing invariant + brainstorming lightest-touch. Tradeoff accepted by the owner (an orchestrating engineer who supplies the omitted reasoning).
- **Reference breakage from ④.** Mitigation: same-change reference sweep in §7.
- **context-mode-absent sessions.** Mitigation: decision #1 — skills stay tool-agnostic, mechanism only in CLAUDE.md.

## 9. Out of Scope

- `settings.json` Stop-hook gate (deferred).
- Editing the external codex plugin.
- Upstream PR / fork-sync.
- Aggressive trim of 0-frequency skills beyond safe deletions.

## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Peer Review | codex | 1 | Issues Found (all 6 accepted & applied) | scope count, false-parallel sequencing, TDD overclaim, diet vs load-bearing, weak verification, ctx_execute syntax | `.jstack/artifacts/peer-review-codex-plan-20260528T222650Z.md` |
| Peer Review (re-run) | codex | 1 | Issues Found (both applied) | non-authoritative file list (now 14-file table §5.0), contradictory reference-update rules (now scoped to `skills/**`, 3 files exempt) | round-2 findings folded into §5.0/④/§7 |
| Adversarial Review | codex | 0 | Not run (planning artifact; not a live-risk change) | - | - |

Round-3 review intentionally skipped: round-2 findings were mechanical consistency fixes (file-list completeness, grep-gate scoping), not scope/architecture changes — re-looping would be review theater.
