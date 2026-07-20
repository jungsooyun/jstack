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
- `complexity`: over-engineering hunt. Finds what to delete: reinvented
  standard library, unneeded dependencies, speculative abstractions, dead
  flexibility. One line per finding: location, what to cut, what replaces it.

Default to `review` when there is a diff. Default to `plan` when the user points at
a spec or plan. Use `challenge` for money movement, auth, security, exchange
adapters, state machines, live-smoke paths, and release blockers. Use `complexity`
when the user asks what can be deleted, simplified, or whether something is
over-engineered.

## When to Request

Request an outside review when: completing a task or major feature, before merging, or before any security/auth/payments/live-risk change. Reviewing your own work in the same context is not a substitute — the point is an independent lane.

## Red Flags (review-avoidance rationalizations)

| Thought | Reality |
|---|---|
| "It's a small change, skip review" | Small diffs hide the costliest bugs. Request it. |
| "I already checked it myself" | Self-review in the authoring context is not independent. |
| "Tests pass, so it's fine" | Tests prove what you thought to test, not what you missed. |
| "Review will slow me down" | A closed PR slows you down more. |

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

For `review`, `challenge`, `complexity`, and `plan` (any finding-producing mode),
also append this output contract:

```text
Output contract — deliver value even if the caller interrupts early:
1. Your FIRST line is a one-line verdict: PASS, ISSUES FOUND, or BLOCKING. Emit
   it before any tracing or context-gathering, then refine as you go.
2. Then a severity-ranked list (BLOCKING > HIGH > MEDIUM > LOW), most severe
   first. Each item: file:line, one-sentence failure scenario, no fix code.
3. Findings before prose. No preamble, no compliments, no restating the diff.
4. Stay inside the named scope. If judging correctness truly requires a file
   outside it, name the file and a one-line reason, then continue — never expand
   scope silently.
```

For `challenge`, append:

```text
Be adversarial. Find how this fails in production. Focus on edge cases, race
conditions, security holes, replay/idempotency bugs, state drift, resource leaks,
and silent data corruption. No compliments. Findings first.
```

For `complexity`, append:

```text
Hunt over-engineering only. Find what to delete: reinvented standard library,
unneeded dependencies, speculative abstractions, dead flexibility. One line per
finding: location, what to cut, what replaces it. Correctness bugs, security
holes, and performance are explicitly out of scope — route them to review or
challenge. A single smoke test or assert-based self-check is the lazy minimum,
not bloat; never flag it for deletion. Findings only, no fixes.
```

For `plan`, append:

```text
Review for blocking planning issues only: missed requirements, contradictions,
ambiguous implementation choices, unsafe sequencing, missing tests, scope creep,
YAGNI violations, and dependencies not reflected in the task order.
```

## Commands

When Codex is the outside reviewer, use `-m gpt-5.6-sol` with
`-c 'model_reasoning_effort="high"'` by default. For a fast lane, add
`-c 'service_tier="fast"'` to every `codex review`/`codex exec` command and swap
the reasoning effort to `low` only when the user explicitly prioritizes speed
over depth.

When Claude Code launches Codex reviewer commands, always close stdin with
`</dev/null` (especially for background tasks): Codex CLI may read piped stdin as
an extra `<stdin>` block even with a prompt argument, leaving the wrapper stuck
after `Reading additional input from stdin...`.

When Codex launches Claude reviewer commands, terminate variadic options before
the prompt and close inherited stdin. Claude's `--add-dir <directories...>`
consumes following positional args until `--`, so the prompt may be parsed as a
directory. Shell: put `--` before the prompt and add `</dev/null`. Python
wrappers: pass the prompt after `--` and use `stdin=subprocess.DEVNULL`.

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

For Codex reviewer auth, prefer a tiny read-only probe (add `-c 'service_tier="fast"'` for the fast lane, per the rule above):

```bash
codex exec "Reply with OK." -C "$REPO_ROOT" -s read-only -m gpt-5.6-sol -c 'model_reasoning_effort="low"' </dev/null
```

For Claude reviewer auth, prefer:

```bash
claude -p --model claude-opus-4-8 --permission-mode plan --allowedTools "LS" --add-dir "$REPO_ROOT" -- "Reply with OK." </dev/null
```

Codex reviewer from Claude Code (for the fast lane, swap `model_reasoning_effort="high"` for `-c 'service_tier="fast"' -c 'model_reasoning_effort="low"'`):

```bash
codex -m gpt-5.6-sol review "<boundary and optional focus>" --base "$BASE" -c 'model_reasoning_effort="high"' --enable web_search_cached </dev/null
```

Codex adversarial challenge from Claude Code (same fast-lane swap applies, only when the user explicitly prioritizes speed over depth):

```bash
codex exec "<boundary plus challenge prompt>" -C "$REPO_ROOT" -s read-only -m gpt-5.6-sol -c 'model_reasoning_effort="high"' --enable web_search_cached --json </dev/null
```

Claude reviewer from Codex:

```bash
claude -p --model claude-opus-4-8 --permission-mode plan --allowedTools "Read,Grep,Glob,LS" --add-dir "$REPO_ROOT" -- "<boundary plus review prompt>" </dev/null
```

Use a 30 minute timeout around outside reviewer commands when the host supports it.
If auth fails, stop and report the exact login command (`codex login` or Claude Code
login) instead of falling back to self-review. If the command hangs, report the
timeout and save any partial stderr/stdout in the artifact.

### Long reviews on hosts that cap a single call (background + poll)

Some hosts cap one shell/tool call well below a full review (Codex's shell tool
does this). A prose "30 minute timeout" cannot lift that cap — the host kills the
call regardless, so a slow reviewer returns nothing. When the reviewer command may
exceed the host's per-call limit, detach it and poll a result file instead of
blocking on one long call. Each poll is a fast, separate call, so none hits the cap:

```bash
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT=".jstack/artifacts/peer-review-claude-review-$STAMP.out"
mkdir -p .jstack/artifacts
nohup claude -p --model claude-opus-4-8 --permission-mode plan \
  --allowedTools "Read,Grep,Glob,LS" --add-dir "$REPO_ROOT" \
  -- "<boundary plus review prompt>" </dev/null >"$OUT" 2>&1 &
echo "$!" > "$OUT.pid"
```

Then poll until the process exits, and read `$OUT`:

```bash
kill -0 "$(cat "$OUT.pid")" 2>/dev/null && echo RUNNING || echo DONE
```

Save `$OUT` as the artifact regardless of outcome. If it is still RUNNING when you
must stop, report that and hand off the pid/out path rather than discarding it.

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

Show raw reviewer output first, then a short triage. Do not implement accepted
fixes unless the workflow has reached a step where edits are allowed.

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

## Receiving Review Feedback

When feedback arrives — from your human partner, a peer reviewer, or GitHub:

1. READ all items without reacting. If any item is unclear, stop and ask before
   implementing any of them — items may be related, and partial understanding
   produces wrong implementations.
2. VERIFY each claim against codebase reality before implementing.
3. RESPOND technically. Never performatively agree — no "You're absolutely
   right!", no "Great point!", no gratitude. State the requirement, ask, push
   back with evidence, or just fix it: the diff is the acknowledgment.
4. IMPLEMENT one item at a time — blocking issues, then simple fixes, then
   complex ones — testing each before the next.
5. PUSH BACK with technical reasoning when a suggestion breaks existing
   functionality, lacks context, violates YAGNI (grep for actual usage first),
   or conflicts with your human partner's architectural decisions. If you
   pushed back and were wrong, state the correction factually and move on.

For GitHub inline review comments, reply in the comment thread
(`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a
top-level PR comment.

## Finding Triage

External feedback is not an order. Before applying it:

1. Verify the finding against code, tests, logs, or docs.
2. Reject findings that contradict repo invariants or add unused scope.
3. Escalate product, architecture, live-risk, or funding-impact decisions.
4. Apply accepted fixes one at a time with targeted tests.

For live trading, movement, signer, exchange, deployment, or credential changes,
do not proceed from review to live execution without explicit user confirmation.
