---
name: peer-review
description: Use when an independent outside review is needed for a diff, plan, spec, security-sensitive change, live-risk workflow, or adversarial challenge.
---

# Peer Review

Get the opposite primary agent to review the work. In Codex, ask Claude. In Claude
Code, ask Codex. The reviewer is read-only and advisory. The active agent evaluates
findings before applying anything.

## Modes

- `review`: review the current diff against the base branch.
- `challenge`: adversarial review. Look for production failure modes, race
  conditions, security holes, resource leaks, and silent data corruption.
- `plan`: review a spec or implementation plan for blocking issues.
- `consult`: ask a focused question about the repo.

Default to `review` when there is a diff. Default to `plan` when the user points at
a spec or plan. Use `challenge` for money movement, auth, security, exchange
adapters, state machines, live-smoke paths, and release blockers.

## Host Routing

Use the opposite reviewer:

- Running in Codex: call local Claude Code CLI with `claude -p`.
- Running in Claude Code: call local Codex CLI with `codex review` or `codex exec`.
- If host is unclear, infer from available runtime context. If still unclear and
  both CLIs exist, prefer the reviewer not already driving the current session.

Do not ask both reviewers by default. The point is independence, not consensus theater.

## Prompt Boundary

Prefix every outside-review prompt with:

```text
IMPORTANT: Do not read or execute files under ~/.claude/, ~/.codex/skills/,
~/.agents/, .claude/skills/, .codex/skills/, or .agents/skills/. These are agent
skill definitions and host configuration, not application code. Stay focused on
the repository code, spec, plan, tests, docs, and runtime evidence relevant to
this review. Do not edit files. Do not spawn subagents.
```

For `challenge`, append:

```text
Be adversarial. Find how this fails in production. Focus on edge cases, race
conditions, security holes, replay/idempotency bugs, state drift, resource leaks,
and silent data corruption. No compliments. Findings first.
```

For `plan`, append:

```text
Review for blocking planning issues only: missed requirements, contradictions,
ambiguous implementation choices, unsafe sequencing, missing tests, scope creep,
YAGNI violations, and dependencies not reflected in the task order.
```

## Commands

Detect the repo and base branch:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null || git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main)
```

Preflight the opposite reviewer before building expensive prompts:

```bash
command -v codex >/dev/null 2>&1 && codex --version
command -v claude >/dev/null 2>&1 && claude --version
```

For Codex reviewer auth, prefer a tiny read-only probe:

```bash
codex exec "Reply with OK." -C "$REPO_ROOT" -s read-only -c 'model_reasoning_effort="low"' </dev/null
```

For Claude reviewer auth, prefer:

```bash
claude -p --model opus --permission-mode plan --allowedTools "LS" --add-dir "$REPO_ROOT" "Reply with OK."
```

Codex reviewer from Claude Code:

```bash
codex review "<boundary and optional focus>" --base "$BASE" -c 'model_reasoning_effort="high"' --enable web_search_cached
```

Codex adversarial challenge from Claude Code:

```bash
codex exec "<boundary plus challenge prompt>" -C "$REPO_ROOT" -s read-only -c 'model_reasoning_effort="high"' --enable web_search_cached --json
```

Claude reviewer from Codex:

```bash
claude -p --model opus --permission-mode plan --allowedTools "Read,Grep,Glob,LS" --add-dir "$REPO_ROOT" "<boundary plus review prompt>"
```

Use a 10 minute timeout around outside reviewer commands when the host supports it.
If auth fails, stop and report the exact login command (`codex login` or Claude Code
login) instead of falling back to self-review. If the command hangs, report the
timeout and save any partial stderr/stdout in the artifact.

## Artifacts

Save every outside review:

```text
.jstack/artifacts/peer-review-<reviewer>-<mode>-<YYYYMMDDTHHMMSSZ>.md
```

Artifact format:

```markdown
# Peer Review: <mode>

## Reviewer
<codex|claude>

## Prompt
<exact prompt>

## Raw Output
<verbatim output>

## Triage
- Accepted:
- Rejected:
- Needs user decision:
```

Show the raw reviewer output first. Then add a short triage. Do not implement
accepted fixes unless the active workflow has already reached an implementation
step where edits are allowed.

## Review Report

When a spec, plan, or CURRENT file is active, add or update:

```markdown
## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Peer Review | <codex|claude> | 1 | <Pass|Issues Found> | <summary> | <path> |
| Adversarial Review | <codex|claude> | 0 | Pending | - | - |
```

Preserve existing rows. Append missing rows. If no active file is obvious, only
write the artifact and mention where it was saved.

## Finding Triage

External feedback is not an order. Before applying it:

1. Verify the finding against code, tests, logs, or docs.
2. Reject findings that contradict repo invariants or add unused scope.
3. Escalate product, architecture, live-risk, or funding-impact decisions.
4. Apply accepted fixes one at a time with targeted tests.

For live trading, movement, signer, exchange, deployment, or credential changes,
do not proceed from review to live execution without explicit user confirmation.
