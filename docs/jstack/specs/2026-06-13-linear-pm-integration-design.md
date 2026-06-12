# Linear PM Integration — Design

**Date:** 2026-06-13
**Status:** Approved by user (conversation), pending peer review
**Owner:** jstack (this repo)

## Problem

The jstack pipeline is strong at vertical depth for a single spec (brainstorm → spec → plan → execute → verify) but has no horizontal project context:

1. **No backlog** — "later" ideas raised during brainstorming evaporate; todo.md file management proved awkward.
2. **No priorities** — a new session has no data to answer "what matters most right now?"
3. **No higher-level goals** — specs have no link to the sprint/milestone they serve.
4. **No status visibility** — `docs/jstack/specs/` accumulates files with no done/in-progress signal.

The user has adopted Linear (workspace team: **Jephalabs**, currently empty — greenfield, no retroactive migration needed) and wants jstack to use the Linear MCP for consistent project-timeline management.

## Decisions (made during brainstorming)

- **Approach B**: one new PM skill + thin sync touchpoints in existing skills. No full bidirectional sync (rejected as YAGNI), no touchpoint-only approach (rejected: leaves prioritization/sprint context unsolved).
- **Linear is the source of truth** for backlog, priorities, and goals. Repo keeps only spec/plan files.
- **PM skill triggers only when direction is unclear** or PM intent is explicit. Clear feature requests ("build X") go straight to the existing pipeline.
- **Milestones, not Cycles**, represent sprint goals (solo development; goal-based beats time-boxed).
- **Issues are created at idea time** (option 1): any "later" idea or todo becomes a Backlog issue immediately. This replaces todo.md.
- **Plan tasks are NOT synced to Linear.** Plans stay local execution detail. `writing-plans`, `executing-plans`, `subagent-driven-development` are untouched.
- **Forward-only mapping.** No retroactive import of historical specs.

## Linear Conventions (the contract)

| Item | Convention |
|---|---|
| Team | Jephalabs (fixed) |
| Project | Product/repo unit (e.g., stratops quant, quant-transfer-guard). Skill proposes creation if missing |
| Milestone | Goal bundle — the "sprint goal" role. Cycles unused |
| Issue | One spec / feature unit. Exists from idea stage |
| Issue states | Backlog (idea) → Todo (next candidate) → In Progress (spec work started) → Done (branch finished) → Canceled (dropped) |
| Priority | Linear's standard 4 levels. Unset at capture; assigned during grooming |
| Spec ↔ issue link | Spec frontmatter gets `linear-issue: JEP-123`; issue description gets the spec file path. Recorded on both sides; **status truth lives in Linear** |

## Components

### 1. New skill: `skills/project-management/SKILL.md`

**Description/triggers:** "what should I work on next", "groom/review the backlog", "plan a milestone/sprint", "add this to the backlog", or brainstorming entry where the build target itself is undecided.

**Four modes:**

- **capture** — create a Backlog issue immediately: title + one-line description + project assignment. Minimal friction; no priority, no milestone required. Used directly by the user ("backlog에 넣어줘") and by brainstorming when "later" ideas surface.
- **next** — query Backlog/Todo issues ordered by priority and milestone, recommend the next piece of work. On selection, hand off to `jstack:brainstorming` with the chosen issue as context.
- **groom** — backlog review: flag stale issues, propose duplicate merges, reorder priorities, reassign milestones. Driven by user confirmation per change (no silent bulk edits).
- **plan-milestone** — define a new goal: create a milestone, assign existing backlog issues to it.

**Tooling:** Linear MCP tools (`list_issues`, `save_issue`, `list_projects`, `save_project`, `list_milestones`, `save_milestone`, `save_comment`, etc.). The skill documents the conventions table above as its operating contract.

### 2. Touchpoint: `skills/brainstorming/SKILL.md` (minimal edits)

1. Entry branch: if the build target is undecided, invoke `jstack:project-management` (next mode) first.
2. After the spec is committed: link the Linear issue — set spec path in issue description, add `linear-issue:` frontmatter to the spec, move issue to In Progress. If no issue exists yet, create one on the spot.
3. When "later" ideas surface during brainstorming: capture them as Backlog issues.

### 3. Touchpoint: `skills/finishing-a-development-branch/SKILL.md` (minimal edits)

On merge/PR completion: move the linked issue to Done and add a comment with the commit/PR link. On discard (Option 4): ask whether to move the issue back to Backlog or to Canceled.

## Failure / Offline Handling

- Linear MCP unavailable or a call fails during a **touchpoint**: do not block the pipeline. Proceed and tell the user explicitly: "Linear sync skipped — manual reconciliation needed."
- Linear MCP unavailable for the **PM skill itself** (next/groom/plan-milestone): these are meaningless without Linear; state that plainly and stop instead of degrading.
- capture mode without Linear: fall back to telling the user the idea was NOT saved anywhere (do not silently write a local file — Linear is the single source of truth).

## Out of Scope (YAGNI)

- Syncing plan tasks as sub-issues.
- Cycles, Initiatives (paid feature), multi-team support.
- Automated/scheduled backlog grooming (the user reviews periodically by asking).
- Retroactive import of existing specs or todo.md files.
- Status write-back from Linear into spec frontmatter (frontmatter records the link, not live status).

## Verification

Skills are behavior-shaping documents, not code. Following `jstack:writing-skills`:

1. Run three real scenarios in fresh sessions: (a) idea capture mid-conversation, (b) "다음 뭐 하지?" → next-mode recommendation → brainstorming handoff, (c) spec completion → issue link → branch finish → Done transition.
2. Inspect the Jephalabs workspace after each scenario: issues, states, milestones, and links must match the conventions table.
3. Pressure-test trigger boundaries: a clear feature request ("build X") must NOT detour through the PM skill.

## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Spec Review | Codex | 0 | Pending | - | - |
| Plan Review | GPT/Claude | 0 | Pending | - | - |
| Peer Review | Codex | 0 | Pending | - | - |
| Adversarial Review | Claude/Codex | 0 | Pending | - | - |
| Verification | Scenario runs | 0 | Pending | - | - |
| Live Evidence | Linear workspace inspection | 0 | Pending | - | - |
