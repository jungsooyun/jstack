---
name: project-management
description: Use when deciding what to work on next, capturing ideas or todos into the backlog, grooming/reviewing the backlog, or planning milestones - manages project context in Linear (source of truth for backlog, priorities, goals). NOT for clear feature requests, which go straight to brainstorming.
---

# Project Management (Linear-backed)

## Overview

Linear is the **source of truth** for backlog, priorities, and goals. The repo
keeps only spec/plan files; what to work on, how important it is, and which goal
it serves all live in Linear. This skill owns the project-management intents that
the vertical brainstorm → spec → plan → execute pipeline does not cover.

**Announce at start:** "I'm using the project-management skill to manage project context in Linear."

This skill triggers only when **direction is unclear** ("what should I work on
next?", "groom the backlog", "plan a milestone") or PM intent is **explicit**
("add this to the backlog"). A clear feature request ("build X") is NOT a PM
task — it goes straight to `jstack:brainstorming`. See the Red Flags table.

All Linear access goes through the Linear MCP tools (`mcp__plugin_linear_linear__*`).
There is no direct Linear API path.

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

## Modes

### capture — file a "later" idea or todo into the backlog

**Trigger phrases:** "backlog에 넣어줘", "add this to the backlog", "remember this
for later", "나중에 ... 하면 좋겠어 / 기억해놔줘", or a "later" idea surfacing
mid-brainstorm.

**MCP tools:** `list_projects` (only when project assignment is ambiguous),
`save_issue`, and — only with user confirmation — `save_project`.

**Steps:**
1. Create a Backlog issue immediately with `save_issue`: `team` = Jephalabs,
   `state` = Backlog, a concise `title`, and a one-line `description`.
2. Assign a `project`. Ask which project ONLY if it is genuinely ambiguous;
   if the active repo/product clearly maps to a project, use it without asking.
3. Confirm back to the user with the created issue ID and project.

**Missing-project branch:** if no obviously matching project exists, run
`list_projects` to check. If there is still no match, **propose** creating one
(`save_project` with `addTeams: ["Jephalabs"]`) and get explicit user
confirmation before creating it. Never create a project silently, and never
file the issue project-less without telling the user.

**Do NOT:** set a priority or milestone at capture (those come during grooming);
create a project without confirmation; write a local todo file instead of a
Linear issue.

### next — recommend what to work on next

**Trigger phrases:** "다음에 뭘 작업하면 좋을까", "what should I work on next",
"우선순위 높은 것부터 추천해줘", or a brainstorming entry where the build target
itself is undecided.

**MCP tools:** `list_issues` (states Backlog and Todo, ordered by priority then
milestone).

**Steps:**
1. Query `list_issues` for Backlog and Todo issues in Jephalabs.
2. Order by priority, then by milestone.
3. Recommend **≤3** candidates, each with a one-line reason (priority,
   milestone, staleness).
4. On the user's selection, hand off to `jstack:brainstorming` with the chosen
   issue as context and carry the **issue ID** so brainstorming can link the
   spec later.

**Do NOT:** guess priorities from git log, plan files, or repo artifacts —
Linear is the source of truth; recommend more than 3 candidates; start
implementing — the next step is brainstorming, not code.

### groom — review and tidy the backlog

**Trigger phrases:** "groom the backlog", "review the backlog", "backlog 정리하자",
"우선순위 다시 매기자".

**MCP tools:** `list_issues`, `save_issue`, `save_comment`.

**Steps:**
1. List the backlog (`list_issues`).
2. Flag stale issues (>30 days untouched — compare `updatedAt`).
3. Propose duplicate merges, priority changes, and milestone reassignments.
4. Apply each mutation only after the user confirms it **individually**.

**Do NOT:** make silent bulk edits; merge/cancel/reprioritize without per-change
user confirmation.

### plan-milestone — define a goal bundle

**Trigger phrases:** "plan a milestone", "plan a sprint", "마일스톤 만들자",
"이번 스프린트 목표 정하자".

**MCP tools:** `save_milestone`, `save_issue` (to assign issues to the milestone).

**Steps:**
1. Create the milestone with `save_milestone` under the relevant project
   (a milestone is the **goal bundle** — the sprint-goal role).
2. Assign existing backlog issues to it.

**Do NOT:** use Cycles (Cycles are unused in this workspace — milestones carry
the goal role); time-box instead of goal-bundle.

## Failure Handling (Linear MCP unavailable)

- **next / groom / plan-milestone:** these are meaningless without Linear. State
  plainly that they cannot run without the Linear MCP, and **stop** — do not
  improvise a degraded version from repo artifacts.
- **capture:** tell the user the idea was **NOT saved anywhere**. Do not silently
  write a local todo file — Linear is the single source of truth, and a silent
  local file creates a false sense of durability.

## Red Flags

| Red flag | What to do instead |
|---|---|
| The feature request is already clear ("build X", "X 기능 만들어줘") | Don't detour here — go straight to `jstack:brainstorming` |
| Tempted to sync plan tasks into Linear as issues/sub-issues | Never — plans stay local execution detail; only spec/feature units become issues |
| Guessing which project an issue belongs to | Ask the user (or `list_projects`); never guess |
| About to create a project silently | Propose it and wait for explicit confirmation |
| Recommending next work from git log / plan files | Query Linear — it is the source of truth for priority |
| Linear MCP is down so I'll write a local todo file | Don't — tell the user the idea was NOT saved |
| Bulk-editing the backlog during grooming | Confirm every mutation individually |

## Integration

- **next** hands off to `jstack:brainstorming` with the chosen issue.
- `jstack:brainstorming` calls **capture** conventions to create the spec's
  linked issue and to capture "later" ideas.
- `jstack:finishing-a-development-branch` reads the linked issue (via
  `scripts/find-linear-issue.sh`) and applies the status transitions.
