---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "Stay in this session?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "executing-plans" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "Stay in this session?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Stay in this session?" -> "subagent-driven-development" [label="yes"];
    "Stay in this session?" -> "executing-plans" [label="no - parallel session"];
}
```

**vs. Executing Plans (parallel session):**
- Same session (no context switch)
- Fresh subagent per task (no context pollution)
- Two-stage review after each task: spec compliance first, then code quality
- Faster iteration (no human-in-loop between tasks)

## The Process

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task";
        "Dispatch implementer subagent (./implementer-prompt.md)" [shape=box];
        "Implementer subagent asks questions?" [shape=diamond];
        "Answer questions, provide context" [shape=box];
        "Implementer subagent implements, tests, commits, self-reviews" [shape=box];
        "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [shape=box];
        "Spec reviewer subagent confirms code matches spec?" [shape=diamond];
        "Implementer subagent fixes spec gaps" [shape=box];
        "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [shape=box];
        "Code quality reviewer subagent approves?" [shape=diamond];
        "Implementer subagent fixes quality issues" [shape=box];
        "Mark task complete in TodoWrite" [shape=box];
    }

    "Read plan, extract all tasks with full text, note context, create TodoWrite" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Dispatch final code reviewer subagent for entire implementation" [shape=box];
    "Live/security/money/state risk?" [shape=diamond];
    "Use jstack:peer-review challenge" [shape=box];
    "Use jstack:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];

    "Read plan, extract all tasks with full text, note context, create TodoWrite" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, commits, self-reviews" [label="no"];
    "Implementer subagent implements, tests, commits, self-reviews" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)";
    "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" -> "Spec reviewer subagent confirms code matches spec?";
    "Spec reviewer subagent confirms code matches spec?" -> "Implementer subagent fixes spec gaps" [label="no"];
    "Implementer subagent fixes spec gaps" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [label="re-review"];
    "Spec reviewer subagent confirms code matches spec?" -> "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [label="yes"];
    "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" -> "Code quality reviewer subagent approves?";
    "Code quality reviewer subagent approves?" -> "Implementer subagent fixes quality issues" [label="no"];
    "Implementer subagent fixes quality issues" -> "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [label="re-review"];
    "Code quality reviewer subagent approves?" -> "Mark task complete in TodoWrite" [label="yes"];
    "Mark task complete in TodoWrite" -> "More tasks remain?";
    "More tasks remain?" -> "Dispatch implementer subagent (./implementer-prompt.md)" [label="yes"];
    "More tasks remain?" -> "Dispatch final code reviewer subagent for entire implementation" [label="no"];
    "Dispatch final code reviewer subagent for entire implementation" -> "Live/security/money/state risk?";
    "Live/security/money/state risk?" -> "Use jstack:peer-review challenge" [label="yes"];
    "Use jstack:peer-review challenge" -> "Use jstack:finishing-a-development-branch";
    "Live/security/money/state risk?" -> "Use jstack:finishing-a-development-branch" [label="no"];
}
```

## Model Selection

Use the least powerful model that can handle each role to conserve cost and increase speed.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.

**Architecture, design, and review tasks**: use the most capable available model.

**Task complexity signals:**
- Touches 1-2 files with a complete spec → cheap model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

## Resource Budget and Agent Cleanup

This workflow optimizes quality by creating many fresh agents. Without explicit resource
limits, complex plans can saturate CPU because multiple agents may run searches, tests,
typechecks, linters, language servers, or MCP-backed tooling at the same time.

**Default conservative budget:**
- Execute one task at a time.
- Max running subagent calls: **1**. Do not dispatch another agent while one is actively working.
- Max open subagent sessions: **2** for the current task only (the task implementer plus the current reviewer/fixer). Close/reap reviewers immediately after their result is processed.
- Keep at most one task implementer alive through the review/fix loop. Close/reap it after code quality approval or after the task is abandoned.
- Do not start the next task until the current task's implementer and reviewers are closed/reaped or explicitly known idle.
- If the runtime supports explicit agent cleanup, call it after every completed reviewer and after each completed task.

**Hard limits:**
- No nested subagents. Every implementer/reviewer prompt must say: "Do not spawn subagents or parallel agents; escalate instead."
- No parallel implementers, no parallel reviewers for the same task, and no pre-dispatching the next task while review is still open.
- Stop using this workflow as-is when expected invocations exceed ~12 (for example, more than 4 tasks with 3 agents each) or when review loops repeat twice on one task. Re-plan into smaller batches or switch to a single-owner/manual execution lane.
- If system CPU is saturated, pause dispatching new agents. Wait for current work to finish, then continue in conservative mode or reduce the workflow to one implementer plus final review.

**Command budget for all agents:**
- Prefer targeted tests for the files/behavior touched by the current task.
- Run full lint/typecheck/test only at task boundaries when necessary and at final verification; never let multiple agents run full-suite verification concurrently.
- Use non-watch commands (`CI=1` where applicable). Do not run dev servers, file watchers, or long-running background commands unless the task explicitly requires them.
- If a server/watch/background command is unavoidable, the agent must record its PID, explain why it was needed, and stop it before reporting DONE.
- Avoid broad repo scans when focused file/symbol searches are enough.

**Interruption and cleanup protocol:**
- Maintain a small ledger while running this workflow: task, role, agent id/session id if available, status, started time, cleanup status, and any background PIDs the agent reports.
- On user interruption, stop dispatching new agents immediately.
- Do not kill processes by broad names like `codex`, `node`, `tmux`, or `omx`. Only close/terminate agents or PIDs that are recorded in the ledger and belong to this workflow/session/worktree.
- If ownership is uncertain, report the suspected leftover agents/processes and leave them running rather than risking another user's or another session's work.
- Before final completion, verify the ledger has no running agents, no unclosed reviewers, and no known background commands.

## Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Proceed to spec compliance review.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, escalate to the human

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## Prompt Templates

- `./implementer-prompt.md` - Dispatch implementer subagent
- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer subagent
- `./code-quality-reviewer-prompt.md` - Dispatch code quality reviewer subagent

## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Read plan file once: docs/jstack/plans/feature-plan.md]
[Extract all 5 tasks with full text and context]
[Create TodoWrite with all tasks]

Task 1: Hook installation script

[Get Task 1 text and context (already extracted)]
[Dispatch implementation subagent with full task text + context]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.config/jstack/hooks/)"

Implementer: "Got it. Implementing now..."
[Later] Implementer:
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Committed

[Dispatch spec compliance reviewer]
Spec reviewer: ✅ Spec compliant - all requirements met, nothing extra

[Get git SHAs, dispatch code quality reviewer]
Code reviewer: Strengths: Good test coverage, clean. Issues: None. Approved.

[Mark Task 1 complete]

Task 2: Recovery modes

[Get Task 2 text and context (already extracted)]
[Dispatch implementation subagent with full task text + context]

Implementer: [No questions, proceeds]
Implementer:
  - Added verify/repair modes
  - 8/8 tests passing
  - Self-review: All good
  - Committed

[Dispatch spec compliance reviewer]
Spec reviewer: ❌ Issues:
  - Missing: Progress reporting (spec says "report every 100 items")
  - Extra: Added --json flag (not requested)

[Implementer fixes issues]
Implementer: Removed --json flag, added progress reporting

[Spec reviewer reviews again]
Spec reviewer: ✅ Spec compliant now

[Dispatch code quality reviewer]
Code reviewer: Strengths: Solid. Issues (Important): Magic number (100)

[Implementer fixes]
Implementer: Extracted PROGRESS_INTERVAL constant

[Code reviewer reviews again]
Code reviewer: ✅ Approved

[Mark Task 2 complete]

...

[After all tasks]
[Dispatch final code-reviewer]
Final reviewer: All requirements met, ready to merge

Done!
```

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Parallel-safe (subagents don't interfere)
- Subagent can ask questions (before AND during work)

**vs. Executing Plans:**
- Same session (no handoff)
- Continuous progress (no waiting)
- Review checkpoints automatic

**Efficiency gains:**
- No file reading overhead (controller provides full text)
- Controller curates exactly what context is needed
- Subagent gets complete information upfront
- Questions surfaced before work begins (not after)

**Quality gates:**
- Self-review catches issues before handoff
- Two-stage review: spec compliance, then code quality
- Review loops ensure fixes actually work
- Spec compliance prevents over/under-building
- Code quality ensures implementation is well-built

**Cost:**
- More subagent invocations (implementer + 2 reviewers per task)
- Controller does more prep work (extracting all tasks upfront)
- Review loops add iterations
- But catches issues early (cheaper than debugging later)

## Red Flags

**Never:**
- Start implementation on main/master branch without explicit user consent
- Skip reviews (spec compliance OR code quality)
- Proceed with unfixed issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Dispatch new agents while a previous subagent is still actively running
- Leave completed reviewer agents open after their result is processed
- Let subagents spawn their own subagents or parallel agents
- Let multiple agents run full-suite tests/typechecks/lints concurrently
- Kill broad process classes (`codex`, `node`, `tmux`, `omx`) instead of only recorded workflow-owned PIDs/agents
- Make subagent read plan file (provide full text instead)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance (spec reviewer found issues = not done)
- Skip review loops (reviewer found issues = implementer fixes = review again)
- Let implementer self-review replace actual review (both are needed)
- **Start code quality review before spec compliance is ✅** (wrong order)
- Move to next task while either review has open issues

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

**If reviewer finds issues:**
- Implementer (same subagent) fixes them
- Reviewer reviews again
- Repeat until approved
- Don't skip the re-review

**If subagent fails task:**
- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

## Final Peer Review Challenge

After final code review and before finishing the branch, decide whether the
implementation touched live/security/money/state-risk surfaces. Use
`jstack:peer-review challenge` when the work affects:

- Live trading, live-smoke, transfers, deposits, withdrawals, bridge execution, or signer paths
- Authentication, callback signing, nonce/replay handling, permissions, secrets, or allowlists
- Exchange adapter state mapping, order/account state machines, idempotency, recovery, or reconciliation
- Deployment, migrations, irreversible data changes, or release blockers

The challenge reviewer is read-only. Apply accepted fixes only after verifying each
finding against code/tests/logs, then re-run targeted verification. Do not run live
execution, spend funds, or change live positions without explicit user confirmation.

## Integration

**Required workflow skills:**
- **jstack:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **jstack:writing-plans** - Creates the plan this skill executes
- **jstack:requesting-code-review** - Code review template for reviewer subagents
- **jstack:finishing-a-development-branch** - Complete development after all tasks
- **jstack:peer-review** - REQUIRED for final adversarial challenge when live/security/money/state-risk surfaces changed

**Subagents should use:**
- **jstack:test-driven-development** - Subagents follow TDD for each task

**Alternative workflow:**
- **jstack:executing-plans** - Use for parallel session instead of same-session execution
