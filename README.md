# JStack

JStack is a local skills workflow for Claude Code and OpenAI Codex. It is inspired
by Garry Tan's [gstack](https://github.com/garrytan/gstack) and Jesse Vincent's
[Superpowers](https://github.com/obra/superpowers): gstack's product/strategy and
cross-model review ideas, plus Superpowers' disciplined planning, TDD, debugging,
and subagent workflows.

This is a personal fork and working system, not an upstream Superpowers release.

## What It Does

JStack turns vague coding requests into an evidence-driven workflow:

1. `brainstorming` frames the real problem, scope, owner boundary, smallest useful
   wedge, and success evidence before implementation.
2. `peer-review` sends specs and plans to the opposite primary agent for read-only
   review: Codex asks Claude, Claude asks Codex.
3. `writing-plans` creates concrete TDD implementation plans under
   `docs/jstack/plans/`.
4. `subagent-driven-development` or `executing-plans` implements the plan with
   review gates.
5. `peer-review challenge` runs an adversarial final review only for
   live/security/money/state-risk changes.
6. `verification-before-completion` keeps completion claims tied to fresh evidence.

The intended high-level flow is:

```text
brainstorming
-> peer-review plan/spec
-> writing-plans
-> peer-review plan
-> implementation
-> risk-based peer-review challenge
-> verification
```

## Key Additions Over The Base

- **Problem Framing Gate**: early office-hours-style check for bottleneck, scope,
  repo ownership, assumptions, smallest evidence-producing wedge, and success evidence.
- **Host-aware peer review**: Codex sessions use Claude as reviewer; Claude sessions
  use Codex as reviewer.
- **Adversarial challenge mode**: production-failure review for live trading,
  transfers, signers, callbacks, exchange state, migrations, and release blockers.
- **JSTACK REVIEW REPORT**: specs/plans/CURRENT files can track review status,
  findings, artifacts, verification, and live evidence.
- **Claude/Codex sync**: both primary hosts point at the same local skills source.

## Current Local Install

Canonical checkout:

```bash
~/.codex/jstack
```

Compatibility alias:

```bash
~/.codex/superpowers -> ~/.codex/jstack
```

Codex skill discovery:

```bash
~/.codex/skills/jstack -> ~/.codex/jstack/skills
~/.agents/skills/jstack -> ~/.codex/jstack/skills
```

Claude Code plugin:

```text
jstack@jstack-dev enabled
superpowers@claude-plugins-official disabled
```

Check local sync status:

```bash
scripts/sync-local-hosts.sh --dry-run
```

Apply Codex/Agents symlinks:

```bash
scripts/sync-local-hosts.sh --apply
```

## Fresh Install

Clone:

```bash
git clone https://github.com/jungsooyun/jstack.git ~/.codex/jstack
```

Codex:

```bash
mkdir -p ~/.codex/skills ~/.agents/skills
ln -s ~/.codex/jstack/skills ~/.codex/skills/jstack
ln -s ~/.codex/jstack/skills ~/.agents/skills/jstack
```

Claude Code:

```bash
claude plugin marketplace add ~/.codex/jstack --scope user
claude plugin install jstack@jstack-dev --scope user
claude plugin disable superpowers@claude-plugins-official
```

Validate:

```bash
claude plugin validate ~/.codex/jstack
claude plugin validate ~/.codex/jstack/.claude-plugin/plugin.json
tests/jstack-static/run.sh
```

Restart Claude Code and Codex after installation so their skill/plugin discovery
refreshes.

## Main Skills

**Workflow**
- `using-superpowers` - startup discipline and skill routing. Name retained for
  compatibility with the upstream skill.
- `brainstorming` - design/spec workflow with Problem Framing Gate and peer-review
  spec gate.
- `writing-plans` - concrete implementation plans with peer-review plan gate.
- `subagent-driven-development` - one task at a time with implementer, spec review,
  code-quality review, and risk-based final challenge.
- `executing-plans` - inline/batch execution for smaller or tightly coupled work.
- `peer-review` - opposite-agent review, adversarial challenge, artifacts, and triage.

**Engineering discipline**
- `test-driven-development` - red/green/refactor discipline.
- `systematic-debugging` - root-cause debugging before fixes.
- `verification-before-completion` - evidence before completion claims.
- `using-git-worktrees` - isolated workspaces.
- `finishing-a-development-branch` - final branch/PR/merge/cleanup choices.

**Review handling**
- `requesting-code-review`
- `receiving-code-review`
- `ask-claude` remains available as a legacy direct-Claude helper in the wider
  local skills set, but `peer-review` is the preferred cross-agent path.

## Peer Review Behavior

Use:

```text
Use jstack:peer-review plan on docs/jstack/plans/<file>.md.
Use jstack:peer-review review for the current diff.
Use jstack:peer-review challenge focusing on replay/idempotency bugs.
```

Routing:

- In Codex: reviewer is Claude Code CLI.
- In Claude Code: reviewer is Codex CLI.

Review output should be saved under:

```text
.jstack/artifacts/peer-review-<reviewer>-<mode>-<timestamp>.md
```

External findings are not orders. The active agent verifies each finding against
code, tests, docs, logs, or live evidence before accepting it.

## Verification

Run local contract checks:

```bash
tests/jstack-static/run.sh
git diff --check
```

Validate Claude manifests:

```bash
claude plugin validate ~/.codex/jstack
claude plugin validate ~/.codex/jstack/.claude-plugin/plugin.json
```

Check plugin state:

```bash
claude plugin list
```

## Updating

```bash
cd ~/.codex/jstack
git pull
scripts/sync-local-hosts.sh --apply
```

Restart Claude Code and Codex after updates that change plugin manifests or skill
metadata.

## Lineage

JStack is built from a local fork of Superpowers and borrows workflow ideas from
gstack. Attribution:

- gstack: https://github.com/garrytan/gstack
- Superpowers: https://github.com/obra/superpowers

## License

MIT License. See `LICENSE`.
