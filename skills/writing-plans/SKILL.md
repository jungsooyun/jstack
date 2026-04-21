---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `docs/jstack/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)
- Read legacy `docs/superpowers/plans/` when continuing older work, but write new plans under `docs/jstack/plans/`.

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use jstack:subagent-driven-development (recommended) or jstack:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## JStack Review Report

Every plan should include a living review status section. Add it before Execution
Handoff and update it when peer review, adversarial review, verification, or live
evidence changes.

```markdown
## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Spec Review | GPT/Claude | 0 | Pending | - | - |
| Plan Review | GPT/Claude | 0 | Pending | - | - |
| Peer Review | Claude/Codex | 0 | Pending | - | - |
| Adversarial Review | Claude/Codex | 0 | Pending | - | - |
| Verification | Local tests | 0 | Pending | - | - |
| Live Evidence | Smoke/log/db | 0 | Pending | - | - |
```

Use `jstack:peer-review` for the outside-review rows. When running in Codex, the
outside reviewer is Claude. When running in Claude Code, the outside reviewer is Codex.

## Alternating Model Review Loop

After self-review, get two independent read-only reviews and incorporate them in order:

1. Ask GPT-5.4 to review the plan against the spec.
2. Apply accepted fixes directly to the plan.
3. Ask Opus to review the updated plan against the spec.
4. Apply accepted fixes directly to the plan.
5. Repeat from GPT-5.4 until both reviewers return no blocking issues, or a reviewer raises a product/architecture decision that requires the user.

Only treat substantive issues as blocking: missed spec requirements, task ordering
bugs, contradictions, vague or unbuildable steps, missing tests, incorrect commands,
scope creep, or decomposition that would make implementation unsafe. Ignore pure
wording preferences unless they prevent an engineer from following the plan.

Reviewers are read-only critics. They must not edit files, run implementation, spawn
subagents, or start long-running commands. If the same issue cycles twice, stop and
ask the user to decide.

Use local commands when available, adapting paths/model aliases as needed:

```bash
# GPT-5.4 review (read-only Codex)
codex exec -m gpt-5.4 -C "$PWD" -s read-only --skip-git-repo-check \
  -o /tmp/plan-gpt54-review.md \
  "Read <PLAN_FILE_PATH> and <SPEC_FILE_PATH>. Review the plan for blocking implementation issues only: missed spec requirements, wrong task order, vague/unbuildable steps, missing tests, incorrect commands, scope creep, or unsafe decomposition. Return Status: Approved or Issues Found. Do not edit files."

# Opus review (read-only Claude)
claude -p --model opus --permission-mode plan --allowedTools "Read,Grep,Glob,LS" \
  --add-dir "$PWD" \
  "Read <PLAN_FILE_PATH> and <SPEC_FILE_PATH>. Review the plan for blocking implementation issues only: missed spec requirements, wrong task order, vague/unbuildable steps, missing tests, incorrect commands, scope creep, or unsafe decomposition. Return Status: Approved or Issues Found. Do not edit files." \
  > /tmp/plan-opus-review.md
```

## Execution Handoff

After saving and reviewing the plan, decide whether to continue automatically or
ask for an execution choice.

### Choose Execution Lane

Before handing off, inspect the plan and choose the better execution lane. Do not
default to subagents just because autonomous continuation was approved.

**Recommend Subagent-Driven when:**
- The plan has 2-4 mostly independent tasks with clear file ownership.
- Each task can be implemented, tested, reviewed, and committed on its own.
- Spec compliance review is valuable because missing or extra behavior would be
  costly.
- The work touches multiple files or subsystems, but task boundaries are clean.
- The expected implementation time is more than about 30 minutes.
- The repo can tolerate isolated agents running targeted tests without requiring
  shared local state.

**Recommend Inline Execution when:**
- The plan is one small task, one or two files, or a narrow bugfix.
- Tasks are tightly coupled and require continuous local reasoning.
- The work is primarily debugging, diagnosis, or test-output interpretation.
- Subagent setup/review prompts would cost more than the implementation.
- The expected subagent workflow would exceed about 12 invocations, or review
  loops are likely to repeat because the work is ambiguous.
- The environment is resource constrained, fragile, or depends on shared local
  state, long-running services, live-smoke sessions, credentials, or external
  side effects.

**Stop for explicit confirmation before implementation when:**
- The plan involves destructive operations, live trading/live-smoke execution,
  external service changes, releases, credential changes, irreversible data
  changes, or anything that could spend funds or change live positions.

**If the choice is ambiguous:** ask the user which lane they want, and include
your recommendation in one sentence.

**Autopilot continuation:**
- If the user already approved autonomous continuation from planning into
  implementation, choose the recommended execution lane using the rules above
  and do not ask for another execution choice unless the choice is ambiguous or
  the plan hits the explicit-confirmation guard.
- If Subagent-Driven is recommended, announce: "Plan complete and saved to
  `docs/jstack/plans/<filename>.md`. Continuing with subagent-driven
  implementation because autonomous continuation was approved and the tasks are
  well isolated." Then use the REQUIRED SUB-SKILL:
  jstack:subagent-driven-development.
- If Inline Execution is recommended, announce: "Plan complete and saved to
  `docs/jstack/plans/<filename>.md`. Continuing inline because autonomous
  continuation was approved and this plan is small, tightly coupled, or
  environment-sensitive." Then use the REQUIRED SUB-SKILL:
  jstack:executing-plans.

**Manual handoff:**
If autonomous continuation was not explicitly approved, offer execution choice
with a recommendation:

**"Plan complete and saved to `docs/jstack/plans/<filename>.md`. I recommend `<Subagent-Driven|Inline Execution>` because `<one-sentence reason>`. Two execution options:**

**1. Subagent-Driven `<add "(recommended)" here only if this is the recommendation>`** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution `<add "(recommended)" here only if this is the recommendation>`** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use jstack:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use jstack:executing-plans
- Batch execution with checkpoints for review
