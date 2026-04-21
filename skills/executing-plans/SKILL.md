---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that JStack works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use jstack:subagent-driven-development instead of this skill.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Risk-Based Peer Review Challenge

Before completing development, decide whether the implementation touched
live/security/money/state-risk surfaces. Use `jstack:peer-review challenge` when
the work affects:

- Live trading, live-smoke, transfers, deposits, withdrawals, bridge execution, or signer paths
- Authentication, callback signing, nonce/replay handling, permissions, secrets, or allowlists
- Exchange adapter state mapping, order/account state machines, idempotency, recovery, or reconciliation
- Deployment, migrations, irreversible data changes, or release blockers

The challenge reviewer is read-only. Apply accepted fixes only after verifying each
finding against code/tests/logs, then re-run targeted verification. Do not run live
execution, spend funds, or change live positions without explicit user confirmation.

### Step 4: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use jstack:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **jstack:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **jstack:writing-plans** - Creates the plan this skill executes
- **jstack:peer-review** - REQUIRED for final adversarial challenge when live/security/money/state-risk surfaces changed
- **jstack:finishing-a-development-branch** - Complete development after all tasks
