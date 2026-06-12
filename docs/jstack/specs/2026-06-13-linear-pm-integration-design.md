# Linear PM Integration — Design

**Date:** 2026-06-13
**Status:** Approved by user (conversation), peer-reviewed
**Owner:** jstack (this repo)
**Scope note:** This is a **fork-only** feature. The Linear/Jephalabs integration is personal configuration by upstream Superpowers standards (third-party tool dependency) and must never be proposed upstream. It lives in this fork's `skills/` namespace deliberately.

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
2. **Before writing the spec file**: ensure the Linear issue exists (create it if missing) so the `linear-issue:` frontmatter is part of the spec's initial commit — no amend or second commit needed. Set the spec path in the issue description right after the commit.
3. **After the user approves the spec** (User Review Gate passes): move the issue to In Progress. Linking happens at commit time; the status transition happens at approval time — a spec that fails review never shows as In Progress.
4. When "later" ideas surface during brainstorming: capture them as Backlog issues.

### 3. Touchpoint: `skills/finishing-a-development-branch/SKILL.md` (minimal edits)

**Issue discovery step (runs first):** find the linked issue by running `scripts/find-linear-issue.sh <base-branch>` — a zero-dependency bash script that scans spec/plan files touched on this branch (`git diff --name-only <base>...HEAD -- docs/`) for `linear-issue:` frontmatter and prints the matched issue ID(s), one per line (empty output = no match). Deterministic script beats per-session improvised grep. If no match or multiple matches, ask the user which issue (or none) applies. Only proceed to status updates when exactly one issue is confirmed.

**Status transitions by option (Done means merged, not submitted):**
- **Option 1 (merge locally):** after the merge succeeds and tests pass → move issue to Done + comment with the merge commit.
- **Option 2 (push & create PR):** PR creation is NOT completion. Keep the issue In Progress and comment the PR link. The issue moves to Done later — when the user confirms the PR merged (e.g., a subsequent finishing run or explicit user statement).
- **Option 3 (keep as-is):** no status change.
- **Option 4 (discard):** ask whether to move the issue back to Backlog (idea still valid) or to Canceled (dropped).

## Failure / Offline Handling

- Linear MCP unavailable or a call fails during a **touchpoint**: do not block the pipeline. Proceed and tell the user explicitly: "Linear sync skipped — manual reconciliation needed."
- Linear MCP unavailable for the **PM skill itself** (next/groom/plan-milestone): these are meaningless without Linear; state that plainly and stop instead of degrading.
- capture mode without Linear: fall back to telling the user the idea was NOT saved anywhere (do not silently write a local file — Linear is the single source of truth).

### 4. Helper script: `scripts/find-linear-issue.sh`

Zero-dependency bash (matching repo conventions in `scripts/`). Input: base branch name (default: repo default branch). Output: `linear-issue:` frontmatter values from `docs/**` files changed on the current branch, one per line; exit 0 with empty output when none found. This is the only script — Linear API access stays exclusively in MCP (no duplicate credential path), and backlog reporting is plain MCP queries (YAGNI).

## Out of Scope (YAGNI)

- Syncing plan tasks as sub-issues.
- Scripts that call the Linear API directly (js/py) — MCP is the single access path.
- Cycles, Initiatives (paid feature), multi-team support.
- Automated/scheduled backlog grooming (the user reviews periodically by asking).
- Retroactive import of existing specs or todo.md files.
- Status write-back from Linear into spec frontmatter (frontmatter records the link, not live status).

## Verification

Skills are behavior-shaping documents, not code. Following `jstack:writing-skills`, verification must meet the baseline-first / red-green bar, not just happy paths:

1. **Baseline (RED) first:** before adding any skill content, run the three scenarios below in fresh sessions WITHOUT the new skill and record the failure mode (idea evaporates, no next-work recommendation, no status transition). The plan must capture these baseline transcripts as before-evidence.
2. **Scenario runs (GREEN):** with the skill installed, rerun: (a) idea capture mid-conversation, (b) "다음 뭐 하지?" → next-mode recommendation → brainstorming handoff, (c) spec completion → issue link → branch finish (Option 1 and Option 2 separately — Option 2 must NOT produce Done).
3. **Pressure / adversarial trigger tests:** (a) a clear feature request ("build X") must NOT detour through the PM skill; (b) finishing a branch with no linked spec must ask, not guess; (c) Linear MCP disconnected must degrade per the failure-handling rules, not block or silently fake success.
4. **Live evidence:** inspect the Jephalabs workspace after each scenario — issues, states, milestones, and links must match the conventions table. Record before/after outcomes in the plan's review report.

## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Spec Review | Codex | 1 | Issues Found → Fixed | 5 blocking: fork-only scope, Done-on-merge semantics, issue discovery step, link-before-commit sequencing, verification bar | .jstack/artifacts/peer-review-codex-plan-20260613T005900Z.md |
| Plan Review | GPT/Claude | 0 | Pending | - | - |
| Peer Review | Codex | 1 | Pass (post-fix) | All 5 findings accepted and applied | .jstack/artifacts/peer-review-codex-plan-20260613T005900Z.md |
| Adversarial Review | Claude/Codex | 0 | Pending | - | - |
| Verification | Scenario runs | 1 | Pass (GREEN + 4 pressure) | 8/8 scenarios pass; no REFACTOR needed | .jstack/artifacts/linear-pm-verification/green-and-pressure.md |
| Live Evidence | Jephalabs workspace | 1 | Pass | JEP-5 Backlog/no-prio, JEP-6 In Progress→Done+comment, JEP-7 stays In Progress; `[test]` fixtures cleaned (Canceled) | .jstack/artifacts/linear-pm-verification/green-and-pressure.md |
