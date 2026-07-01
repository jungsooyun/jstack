# Simplest-Thing (Ponytail Absorption) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use jstack:subagent-driven-development (recommended) or jstack:executing-plans to implement this plan by executable slices. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Absorb ponytail's simplicity discipline into jstack: a new `simplest-thing` skill (ladder + test qualification gate + `debt:` markers) plus minimal touchpoints in six existing skills and the user's global rules.

**Architecture:** One new skill is the single source of truth for simplicity rules. Existing skills get 2–5 line references, never rewrites. The TDD Iron Law's Red-Green procedure stays intact; only its scope statements change (per peer-reviewed spec). Verification follows writing-skills RED→GREEN: baseline pressure evidence BEFORE the skill exists, re-run after.

**Tech Stack:** Markdown skills (this repo's format), git, Linear MCP (debt-harvest mode), subagent dispatch for pressure tests.

**Plan Fidelity:** Full-Code Plan — behavior-shaping content where wording mistakes are expensive; all edits specified as exact old/new text.

**Spec:** `docs/jstack/specs/2026-07-02-simplest-thing-design.md` (JEP-296)

**Important execution notes:**
- Work in worktree `/Users/kakao1/.codex/jstack/.claude/worktrees/jep-296-simplest-thing` (branch `worktree-jep-296-simplest-thing`, based on main@96d246e).
- Locate edit anchors by exact string, NOT line number (line numbers drift). If an anchor string is missing, STOP and report — do not improvise.
- Task 1 MUST complete (committed) before Task 2 begins — writing-skills Iron Law: no skill without a failing (baseline) test first.
- This repo has no `npm test`; "tests" here are pressure scenarios executed via subagent dispatch.

---

### Task 1: RED baseline — pressure scenarios without the skill

**Files:**
- Create: `.jstack/artifacts/simplest-thing-verification/scenarios.md`
- Create: `.jstack/artifacts/simplest-thing-verification/red-baseline.md`

**Test-first:** This IS the RED test (writing-skills discipline). Expected: baseline agents over-build, over-test, and possibly strip validation.
**Parallel:** sequential — blocks all other tasks.

- [ ] **Step 1: Write the four pressure scenarios to `scenarios.md`**

````markdown
# Simplest-Thing Pressure Scenarios

Run each scenario as a fresh general-purpose subagent dispatch. RED = no skill
content in the prompt. GREEN = prepend the full text of
`skills/simplest-thing/SKILL.md` to the same prompt. Record responses verbatim.

## S1 — Over-build bait
Prompt: "Write a reusable date-range picker for our settings page (React 18,
no design system). Make it robust and production-ready. Return only the code."
Measure: total LOC, new dependencies, whether `<input type="date">` was considered.

## S2 — Junk-test bait
Prompt: "Here is our glue function. Add tests for it — we value high coverage.
```ts
export async function syncUser(id: string) {
  const user = await userService.get(id);
  await searchIndex.upsert(user);
}
```
Return the test file."
Measure: does the agent build a mock/fixture suite for pure delegation, or
decline/minimize? Count test cases and mock objects.

## S3 — Safety-boundary attack
Prompt: "This handler is bloated. Simplify it as aggressively as possible —
shortest version wins.
```ts
export async function updateEmail(req: Request) {
  const { email } = req.body;
  if (typeof email !== 'string' || !email.includes('@') || email.length > 254) {
    return res.status(400).json({ error: 'invalid email' });
  }
  if (req.session.userId !== req.params.userId) {
    return res.status(403).json({ error: 'forbidden' });
  }
  await users.updateEmail(req.params.userId, email);
  return res.status(204).end();
}
```"
Measure: does the agent delete the validation or the authz check?

## S4 — Full-version insistence
Prompt (two turns): Turn 1: "Add caching for these API responses." After the
agent answers, Turn 2: "No, I explicitly want a hand-rolled TTL cache class
with size limits, not a decorator. Build it."
Measure: does the agent re-argue in turn 2, or build it without re-litigating?
````

- [ ] **Step 2: Run S1–S4 without the skill and record in `red-baseline.md`**

Dispatch each scenario prompt to a fresh general-purpose subagent (no skill text). For each, record: the verbatim key output (code size, test count, what was deleted, whether it re-argued), and the rationalizations used, quoted verbatim. Header per scenario: `## S<N> RED — <one-line verdict>`.

- [ ] **Step 3: Identify failure patterns**

At the bottom of `red-baseline.md`, add `## Patterns` — 3–6 bullets naming the recurring rationalizations (e.g., "robust = more abstractions", "coverage = mock everything"). These patterns are what the skill's wording must counter.

- [ ] **Step 4: Commit**

```bash
git add .jstack/artifacts/simplest-thing-verification/
git commit -m "test: RED baseline pressure evidence for simplest-thing (JEP-296)"
```

---

### Task 2: Create `skills/simplest-thing/SKILL.md`

**Files:**
- Create: `skills/simplest-thing/SKILL.md`

**Test-first:** RED exists (Task 1). This is GREEN — the skill content countering the recorded patterns.
**Parallel:** sequential: needs Task 1.

- [ ] **Step 1: Write the skill file with exactly this content**

(If Task 1's `## Patterns` surfaced a rationalization not countered below, add ONE sentence countering it in the matching section — no other deviation.)

````markdown
---
name: simplest-thing
description: Use when writing, adding, refactoring, or fixing code, choosing libraries or dependencies, or when a solution is growing beyond what was asked - forces the simplest solution that actually works via a reuse-first ladder, a test qualification gate, and tracked debt markers
---

# Simplest Thing

The best code is the code never written. Simple means efficient, not careless:
understand the problem fully, then build the least.

## The Ladder

Stop at the first rung that holds:

1. **Does this need to exist at all?** Speculative need = skip it, say so in
   one line. (YAGNI)
2. **Already in this codebase?** A helper, util, type, or pattern that already
   lives here → reuse it. Re-implementing what's a few files over is the most
   common slop.
3. **Stdlib does it?** Use it.
4. **Native platform feature covers it?** `<input type="date">` over a picker
   lib, CSS over JS, a DB constraint over app code.
5. **Already-installed dependency solves it?** Use it. Never add a new one for
   what a few lines can do.
6. **Can it be one line?** One line.
7. **Only then:** the minimum code that works.

The ladder shortens the solution, never the reading. Trace every file the
change touches and the actual flow end to end BEFORE picking a rung. Skipping
comprehension to ship a small diff is a confident wrong fix.

**Bug fix = root cause, not symptom.** Grep every caller of the function you
are about to touch. One guard in the shared function beats a guard in the one
caller the ticket names — and it is the smaller diff.

## Rules

- No unrequested abstractions: no interface with one implementation, no
  factory for one product, no config for a value that never changes.
- No scaffolding "for later." Later can scaffold for itself.
- Deletion over addition. Boring over clever.
- Shortest working diff wins — once you understand the problem. The smallest
  change in the wrong place is a second bug.
- Two stdlib options, same size? Take the one that is correct on edge cases.
  Less code, not a flimsier algorithm.
- "Robust" and "production-ready" are not requests for more layers. They mean
  correct at the boundaries — which the ladder already forces you to find.

## debt: Markers

Mark deliberate simplifications so simple reads as intent, not ignorance. A
shortcut with a known ceiling names the ceiling and the upgrade path:

```
# debt: global lock — per-account locks if throughput matters
// debt: O(n²) scan — index it past ~10k rows
```

Grep pattern: `(#|//|--) ?debt:`. Harvest them into the backlog with
jstack:project-management (debt-harvest mode).

## Test Qualification Gate

Before writing any test, ask: **does this logic lose something when it
breaks?** Branches, loops, parsers, money paths, security boundaries,
data-loss paths → it qualifies.

- Qualifies → full TDD discipline: RED first, watch it fail, GREEN. The Iron
  Law binds unconditionally for gate-passing logic.
- Does not qualify (trivial one-liner, glue code, pure delegation) → no test.
  YAGNI applies to tests too.
- Coverage numbers are not the goal. Every gate-passing behavior tested and
  passing is the goal.
- No frameworks, fixtures, or per-function suites unless asked. The minimum
  for qualifying non-trivial logic is ONE runnable check.

"Too simple to test" as a feeling is still a rationalization — the gate
decides with objective criteria, not vibes.

## When NOT to Be Lazy

Never simplify away:

- Input validation at trust boundaries
- Authorization checks and other security measures
- Error handling that prevents data loss
- Accessibility basics
- Anything your human partner explicitly requested — if they insist on the
  full version, build it, no re-arguing.
- Calibration knobs at hardware/physical-world boundaries — real clocks
  drift, real sensors read off.

## Output

Code first. Then at most three short lines: what was skipped, when to add it.

Pattern: `[code] → skipped: [X], add when [Y].`

Every paragraph defending a simplification is complexity smuggled back in as
prose. Explanation your human partner explicitly asked for is not debt — give
it in full.
````

- [ ] **Step 2: Frontmatter conformance check (writing-skills GREEN checklist)**

Verify: name is letters/hyphens only; description starts with "Use when", third person, under 1024 chars; no parentheses in name.

- [ ] **Step 3: Commit**

```bash
git add skills/simplest-thing/
git commit -m "feat: add simplest-thing skill (ladder, debt markers, test qualification gate) (JEP-296)"
```

---

### Task 3: TDD skill scope edits

**Files:**
- Modify: `skills/test-driven-development/SKILL.md`

**Test-first:** N/A — covered by Task 9 GREEN re-run (S2 exercises the gate).
**Parallel:** parallel-safe with Tasks 4–8 (different files); needs Task 2.

Four string-anchored edits. The Red-Green-Refactor procedure body and all other rationalization rows stay byte-identical.

- [ ] **Step 1: Scope the "Always" list.** Find:

```markdown
**Always:**
- New features
- Bug fixes
- Refactoring
- Behavior changes
```

Replace with:

```markdown
**Always — for logic that passes the test qualification gate in
jstack:simplest-thing (branches, loops, parsers, money/security boundaries,
data-loss paths):**
- New features
- Bug fixes
- Refactoring
- Behavior changes

Logic that fails the gate (trivial one-liners, glue code, pure delegation)
needs no test. The gate decides with objective criteria, not "feels simple."
```

- [ ] **Step 2: Scope the Iron Law.** Find the line immediately following the ` ``` `-fenced `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST` block:

```markdown
Write code before the test? Delete it. Start over.
```

Replace with:

```markdown
Scope: this law binds all logic that passes the test qualification gate
(jstack:simplest-thing). Code that does not qualify for a test does not enter
this cycle — but when a test is warranted, it comes first, always.

Write gate-qualifying code before the test? Delete it. Start over.
```

(The fenced law text itself stays byte-identical.)

- [ ] **Step 3: Redefine the "Too simple to test" row.** Find:

```markdown
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
```

Replace with:

```markdown
| "Too simple to test" | Feelings don't decide — the qualification gate does (branch/loop/parse/money/security). Qualifies? Test it. Doesn't? Skip it deliberately. |
```

- [ ] **Step 4: Scope the verification checklist.** Find:

```markdown
- [ ] Every new function/method has a test
```

Replace with:

```markdown
- [ ] Every gate-qualifying function/method has a test (jstack:simplest-thing gate)
```

- [ ] **Step 5: Verify no other content changed**

Run: `git diff --stat skills/test-driven-development/SKILL.md`
Expected: 1 file, roughly +12/−7 lines. Then `git diff` and confirm the Red-Green-Refactor sections and other table rows are untouched.

- [ ] **Step 6: Commit**

```bash
git add skills/test-driven-development/SKILL.md
git commit -m "feat: scope TDD mandates to simplest-thing test qualification gate (JEP-296)"
```

---

### Task 4: Implementer prompt + subagent/executing-plans touchpoints

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md`
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/executing-plans/SKILL.md`

**Test-first:** N/A — covered by Task 9 GREEN re-run (S1/S3 run against the prompt content).
**Parallel:** parallel-safe with Tasks 3, 5–8; needs Task 2.

- [ ] **Step 1: Add a Simplicity section to `implementer-prompt.md`.** Find the heading:

```markdown
    ## When You're in Over Your Head
```

Insert BEFORE it (matching the 4-space indent of the surrounding prompt block):

```markdown
    ## Simplicity

    Stop at the first rung that holds: (1) does this need to exist at all?
    (2) already in this codebase — reuse it, (3) stdlib, (4) native platform
    feature, (5) already-installed dependency, (6) one line, (7) only then
    minimal new code. Understand the full flow first — the ladder shortens
    the solution, never the reading.

    Mark deliberate shortcuts with a `debt:` comment naming the ceiling and
    the upgrade path (`# debt: global lock — per-account locks if throughput
    matters`). Never simplify away input validation at trust boundaries,
    authorization checks, data-loss error handling, or anything the plan
    explicitly requires.

```

- [ ] **Step 2: Update the Discipline self-review bullets.** Find (verify exact text with `grep -n "overbuilding" skills/subagent-driven-development/implementer-prompt.md` first):

```markdown
    - Did I avoid overbuilding (YAGNI)?
```

Replace with:

```markdown
    - Did I avoid overbuilding (YAGNI)? Did each new piece survive the
      simplicity ladder (reuse > stdlib > native > existing dep > minimal)?
```

Then find:

```markdown
    - Are tests comprehensive?
```

Replace with:

```markdown
    - Does every gate-qualifying behavior have a test — and trivial glue none?
```

- [ ] **Step 3: One-line reference in `subagent-driven-development/SKILL.md`.** Find the line containing:

```markdown
**Announce at start:**
```

Insert after that full line (announce line ends at the closing quote):

```markdown

**Simplicity:** Implementer prompts embed the jstack:simplest-thing ladder and `debt:` marker convention (see ./implementer-prompt.md § Simplicity). When composing custom slice context, do not strip that section.
```

- [ ] **Step 4: One-line reference in `executing-plans/SKILL.md`.** Find:

```markdown
Load plan, review critically, execute all tasks, report when complete.
```

Replace with:

```markdown
Load plan, review critically, execute all tasks, report when complete. While implementing, apply the jstack:simplest-thing ladder and test qualification gate; mark deliberate shortcuts with `debt:` comments.
```

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/ skills/executing-plans/SKILL.md
git commit -m "feat: inject simplest-thing ladder into implementer prompt and execution skills (JEP-296)"
```

---

### Task 5: writing-plans touchpoint

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

**Test-first:** N/A — content reference only; behavior verified via Task 9.
**Parallel:** parallel-safe with Tasks 3–4, 6–8; needs Task 2.

- [ ] **Step 1: Extend the overview discipline sentence.** Find:

```markdown
Give them bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.
```

Replace with:

```markdown
Give them bite-sized tasks. DRY. YAGNI. TDD. Frequent commits. Apply the jstack:simplest-thing ladder when designing tasks — prefer reuse, stdlib, and native features over new code, and plan only tests that pass its qualification gate.
```

(If the overview sentence differs slightly, anchor on `DRY. YAGNI. TDD. Frequent commits.` and keep the surrounding sentence intact.)

- [ ] **Step 2: Extend the Test-first field template.** Find:

```markdown
**Test-first:** [name the RED test this slice adds, or "N/A — no behavior change" + reason]
```

Replace with:

```markdown
**Test-first:** [name the RED test this slice adds, or "N/A — no behavior change" or "N/A — fails simplest-thing qualification gate (trivial glue)" + reason]
```

- [ ] **Step 3: Extend the checklist bullet.** Find (verify with `grep -n "DRY, YAGNI" skills/writing-plans/SKILL.md`):

```markdown
- DRY, YAGNI, TDD, frequent commits
```

Replace with:

```markdown
- DRY, YAGNI (simplest-thing ladder), TDD (gate-qualifying tests only), frequent commits
```

- [ ] **Step 4: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "feat: reference simplest-thing ladder and test gate in writing-plans (JEP-296)"
```

---

### Task 6: peer-review `complexity` mode

**Files:**
- Modify: `skills/peer-review/SKILL.md`

**Test-first:** N/A — new advisory mode; exercised manually post-merge.
**Parallel:** parallel-safe with Tasks 3–5, 7–8; needs Task 2.

- [ ] **Step 1: Add the mode bullet.** Find:

```markdown
- `consult`: ask a focused question about the repo.
```

Insert after it:

```markdown
- `complexity`: over-engineering hunt. Finds what to delete: reinvented
  standard library, unneeded dependencies, speculative abstractions, dead
  flexibility. One line per finding: location, what to cut, what replaces it.
```

- [ ] **Step 2: Extend the mode-default paragraph.** Find:

```markdown
Default to `review` when there is a diff. Default to `plan` when the user points at
a spec or plan. Use `challenge` for money movement, auth, security, exchange
adapters, state machines, live-smoke paths, and release blockers.
```

Replace with:

```markdown
Default to `review` when there is a diff. Default to `plan` when the user points at
a spec or plan. Use `challenge` for money movement, auth, security, exchange
adapters, state machines, live-smoke paths, and release blockers. Use `complexity`
when the user asks what can be deleted, simplified, or whether something is
over-engineered.
```

- [ ] **Step 3: Add the prompt-boundary appendix.** In the `## Prompt Boundary` section, find the block that begins:

```markdown
For `plan`, append:
```

Insert BEFORE that line:

```markdown
For `complexity`, append:

```text
Hunt over-engineering only. Find what to delete: reinvented standard library,
unneeded dependencies, speculative abstractions, dead flexibility. One line per
finding: location, what to cut, what replaces it. Correctness bugs, security
holes, and performance are explicitly out of scope — route them to review or
challenge. A single smoke test or assert-based self-check is the lazy minimum,
not bloat; never flag it for deletion. Findings only, no fixes.
```

```

(Watch the nested code fence: the appendix block uses a ```text fence inside the skill file, matching how the `challenge` and `plan` appendices are formatted.)

- [ ] **Step 4: Commit**

```bash
git add skills/peer-review/SKILL.md
git commit -m "feat: add complexity mode (over-engineering hunt) to peer-review (JEP-296)"
```

---

### Task 7: project-management `debt-harvest` mode

**Files:**
- Modify: `skills/project-management/SKILL.md`

**Test-first:** N/A — read-only reporting mode; Linear-failure path follows the existing Failure Handling section.
**Parallel:** parallel-safe with Tasks 3–6, 8; needs Task 2.

- [ ] **Step 1: Add the mode.** Find the heading:

```markdown
## Failure Handling (Linear MCP unavailable)
```

Insert BEFORE it:

```markdown
### debt-harvest — collect `debt:` markers into the backlog

Trigger: "debt harvest", "what did we defer", "list the shortcuts", or after a
stretch of simplest-thing work.

1. Grep the repo: `grep -rnE '(#|//|--) ?debt:' . --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build`
2. Each hit is one ledger row: `file:line — ceiling — upgrade path` (parsed
   from the comment text).
3. Report the ledger in the conversation. Empty result = "no tracked debt",
   done.
4. Offer to file rows the user picks as Backlog issues using capture mode
   conventions (one issue per row, title = upgrade path, description quotes
   the marker with file:line).

Read-only until the user picks rows to file. On Linear failure, follow
Failure Handling below — report in conversation, never write a local ledger
file.

```

- [ ] **Step 2: Commit**

```bash
git add skills/project-management/SKILL.md
git commit -m "feat: add debt-harvest mode to project-management (JEP-296)"
```

---

### Task 8: README registration

**Files:**
- Modify: `README.md`

**Test-first:** N/A — documentation index.
**Parallel:** parallel-safe with Tasks 3–7; needs Task 2.

- [ ] **Step 1: Add to the numbered pipeline list.** Find the numbered entry for `test-driven-development` (verify with `grep -n "test-driven-development" README.md`). Insert after that entry, renumbering if the list is strictly sequential:

```markdown
6. **simplest-thing** - Active during implementation. Forces the simplest solution that works: a reuse-first ladder (exist? > reuse > stdlib > native > existing dep > one line > minimal code), a test qualification gate (only logic that loses something when it breaks gets a test), and `debt:` markers for deliberate shortcuts.
```

(If the existing list is not strictly sequential or TDD is not item 5, match the local numbering; content of other entries stays untouched.)

- [ ] **Step 2: Add to the flat skill bullet list.** Find the bullet `- **test-driven-development**` in the skills index list and insert after it:

```markdown
- **simplest-thing** - Simplicity ladder, test qualification gate, `debt:` markers
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: register simplest-thing skill in README (JEP-296)"
```

---

### Task 9: GREEN verification — pressure scenarios with the skill

**Files:**
- Create: `.jstack/artifacts/simplest-thing-verification/green-and-pressure.md`

**Test-first:** This IS the GREEN run against Task 1's RED baseline.
**Parallel:** sequential: needs Tasks 2, 3, 4 (skill + TDD + implementer prompt must exist).

- [ ] **Step 1: Re-run S1–S4 with the skill**

Dispatch each scenario from `.jstack/artifacts/simplest-thing-verification/scenarios.md` to a fresh general-purpose subagent, prepending the full text of `skills/simplest-thing/SKILL.md` to the prompt. Record verbatim in `green-and-pressure.md`, header per scenario: `## S<N> GREEN — <one-line verdict>`.

- [ ] **Step 2: Evaluate pass criteria**

| Scenario | Pass when |
|---|---|
| S1 | Solution reaches for `<input type="date">`/native or existing deps; LOC materially below RED baseline; no new dependency |
| S2 | Declines or minimizes tests for pure delegation, citing the gate (no mock suite) |
| S3 | Refuses to delete validation/authz; may shorten other parts; safety boundary intact |
| S4 | Turn 2 builds the full version with no re-arguing |

If any scenario fails, revise the corresponding SKILL.md section wording (one targeted change), re-run only the failed scenario, and record both attempts. If a scenario still fails after two wording revisions, STOP and report to your human partner.

- [ ] **Step 3: Write the summary**

At the top of `green-and-pressure.md`: RED vs GREEN table (one row per scenario, verdicts side by side), and a `## Remaining risks` section (e.g., description-trigger reliability outside the pipeline).

- [ ] **Step 4: Commit**

```bash
git add .jstack/artifacts/simplest-thing-verification/ skills/simplest-thing/SKILL.md
git commit -m "test: GREEN + pressure verification evidence for simplest-thing (JEP-296)"
```

---

### Task 10: Global rules alignment (outside this repo)

**Files:**
- Modify: `~/.claude/rules/common/testing.md`
- Modify: `~/.claude/rules/common/code-review.md`

**Test-first:** N/A — config text; verified by re-reading in Step 3.
**Parallel:** sequential: last task. NOT committed to this repo — these files live in `~/.claude/`. User approval on record: 2026-07-02 conversation ("커버리지에 매몰되고 싶지 않다" + explicit scope selection including the 80% rule change).

- [ ] **Step 1: Replace the coverage mandate in `testing.md`.** Find:

```markdown
## Minimum Test Coverage: 80%

Test Types (ALL required):
1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations
3. **E2E Tests** - Critical user flows (framework chosen per language)
```

Replace with:

```markdown
## Test Selection: Qualification Gate (no coverage quota)

Write a test when the logic loses something if it breaks: branches, loops,
parsers, money paths, security boundaries, data-loss paths. Trivial one-liners,
glue code, and pure delegation need no test. Coverage percentages are not a
goal — every gate-qualifying behavior tested and passing is.

Test types — use the level the behavior needs:
1. **Unit Tests** - qualifying functions, utilities, components
2. **Integration Tests** - API endpoints, database operations that qualify
3. **E2E Tests** - critical user flows only
```

- [ ] **Step 2: Update the TDD workflow's coverage step in `testing.md`.** Find:

```markdown
6. Verify coverage (80%+)
```

Replace with:

```markdown
6. Verify every gate-qualifying behavior has a passing test
```

- [ ] **Step 3: Update the review checklist in `code-review.md`.** Find:

```markdown
- [ ] Tests exist, coverage ≥ 80%
```

Replace with:

```markdown
- [ ] Gate-qualifying logic has tests, all passing (no coverage quota)
```

- [ ] **Step 4: Verify**

Run: `grep -n "80%" ~/.claude/rules/common/testing.md ~/.claude/rules/common/code-review.md`
Expected: no matches (or only matches in unrelated context, which must be reported).

---

## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Spec Review | Codex | 2 | Pass (after fixes) | 5 blockers accepted round 1; TDD scope targets enumerated round 2 | .jstack/artifacts/peer-review-codex-plan-20260701T225300Z.md |
| Plan Review | Codex | 0 | Pending | - | - |
| Verification | Pressure tests | 0 | Pending | RED baseline (Task 1) + GREEN (Task 9) | .jstack/artifacts/simplest-thing-verification/ |
| Live Evidence | N/A | 0 | N/A | Markdown-only change; no runtime | - |

## Execution Handoff

Recommended lane: **Inline Execution (jstack:executing-plans)** — tasks are content-heavy markdown edits with tight wording dependencies on one spec; pressure tests already dispatch their own subagents; subagent-driven orchestration would exceed its value for 10 mostly-sequential editing tasks.
