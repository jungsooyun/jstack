# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (general-purpose):
  Use template at code-reviewer.md (this skill's local template)

  DESCRIPTION: [task summary, from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
```

Specify the reviewer model lane explicitly when dispatching (Claude: `--model claude-opus-4-8` or `--model claude-sonnet-4-6`; Codex: `-m gpt-5.4` with appropriate `-c 'model_reasoning_effort=...'`).

**Resource boundaries:**
- Do not spawn subagents or parallel agents; escalate instead.
- Prefer focused diff/file inspection over broad repo scans.
- Do not run full-suite lint/typecheck/test unless targeted checks are insufficient for review.
- Do not start watch modes, dev servers, or long-running background commands.

**In addition to standard code quality concerns, the reviewer should check:**
- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
