#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

json_name() {
  python3 - "$1" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    print(json.load(f).get("name", ""))
PY
}

[[ "$(json_name package.json)" == "jstack" ]] || fail "package.json name must be jstack"
[[ "$(json_name .claude-plugin/plugin.json)" == "jstack" ]] || fail ".claude-plugin/plugin.json name must be jstack"
[[ "$(json_name .cursor-plugin/plugin.json)" == "jstack" ]] || fail ".cursor-plugin/plugin.json name must be jstack"
[[ "$(json_name gemini-extension.json)" == "jstack" ]] || fail "gemini-extension.json name must be jstack"

[[ -f skills/peer-review/SKILL.md ]] || fail "skills/peer-review/SKILL.md is required"
grep -q 'codex -m gpt-5.6-sol review' skills/peer-review/SKILL.md || fail "Codex review must pin GPT-5.6 Sol before the review subcommand"
! rg -q 'gpt-5\.5' skills/peer-review/SKILL.md skills/writing-plans/SKILL.md || fail "active peer-review guidance must not pin GPT-5.5"
grep -q -- '--add-dir "$REPO_ROOT" -- "Reply with OK."' skills/peer-review/SKILL.md || fail "Claude reviewer preflight must terminate --add-dir before prompt"
grep -q "stdin=subprocess.DEVNULL" skills/peer-review/SKILL.md || fail "Claude subprocess reviewer guidance must close stdin"
grep -q "docs/jstack/specs" skills/brainstorming/SKILL.md || fail "brainstorming must write specs under docs/jstack/specs"
grep -q "Problem Framing Gate" skills/brainstorming/SKILL.md || fail "brainstorming must include Problem Framing Gate"
grep -q "docs/jstack/plans" skills/writing-plans/SKILL.md || fail "writing-plans must write plans under docs/jstack/plans"
grep -q "JSTACK REVIEW REPORT" skills/writing-plans/SKILL.md || fail "writing-plans must define JSTACK REVIEW REPORT"
grep -q "tracer bullet" skills/writing-plans/SKILL.md || fail "writing-plans must include tracer bullet decomposition guidance"
grep -q "horizontal slice" skills/writing-plans/SKILL.md || fail "writing-plans must guard against horizontal slice tasks"
grep -q "jstack:peer-review plan" skills/brainstorming/SKILL.md || fail "brainstorming must route specs through peer-review"
grep -q "CONTEXT.md" skills/brainstorming/SKILL.md || fail "brainstorming must include lazy domain context guidance"
grep -q "ADR" skills/brainstorming/SKILL.md || fail "brainstorming must include lazy ADR guidance"
grep -q "jstack:peer-review plan" skills/writing-plans/SKILL.md || fail "writing-plans must route plans through peer-review"
grep -q "jstack:peer-review challenge" skills/subagent-driven-development/SKILL.md || fail "subagent-driven-development must include risk-based peer-review challenge"
grep -q "jstack:peer-review challenge" skills/executing-plans/SKILL.md || fail "executing-plans must include risk-based peer-review challenge"
! rg -q "Alternating Model Review|GPT-5\\.4 review|Opus review" skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md || fail "old alternating model review loop must not remain in planning gates"

grep -q "jstack:" skills/writing-plans/SKILL.md || fail "writing-plans must reference jstack skill namespace"
grep -q "jstack:" skills/subagent-driven-development/SKILL.md || fail "subagent-driven-development must reference jstack skill namespace"
[[ ! -d skills/requesting-code-review ]] || fail "requesting-code-review stub must be deleted (consolidated into peer-review)"
grep -q "## When to Request" skills/peer-review/SKILL.md || fail "peer-review must retain When to Request section"
[[ -x skills/systematic-debugging/scripts/hitl-loop.template.sh ]] || fail "systematic-debugging must include executable HITL loop template"
grep -q "hitl-loop.template.sh" skills/systematic-debugging/SKILL.md || fail "systematic-debugging must reference HITL loop template"
[[ -f skills/brainstorming/context-format.md ]] || fail "brainstorming must include CONTEXT.md format reference"
[[ -f skills/brainstorming/adr-format.md ]] || fail "brainstorming must include ADR format reference"
[[ -f skills/architecture-deepening/SKILL.md ]] || fail "architecture-deepening skill is required"
grep -q "deletion test" skills/architecture-deepening/SKILL.md || fail "architecture-deepening must include deletion test guidance"
[[ -f skills/writing-plans/agent-brief-template.md ]] || fail "writing-plans must include long-lived agent brief template"
grep -q "Agent Brief" skills/writing-plans/agent-brief-template.md || fail "writing-plans must include long-lived agent brief template"

grep -q "## Receiving Review Feedback" skills/peer-review/SKILL.md || fail "peer-review must absorb receiving-code-review discipline"
grep -q "performatively agree" skills/peer-review/SKILL.md || fail "peer-review must retain no-performative-agreement rule"
[[ ! -d skills/receiving-code-review ]] || fail "receiving-code-review must be merged into peer-review"

[[ ! -d skills/dispatching-parallel-agents ]] || fail "dispatching-parallel-agents must be archived"
[[ -f archive/skills/dispatching-parallel-agents/SKILL.md ]] || fail "archived dispatching-parallel-agents must be preserved"
! rg -q --no-messages "dispatching-parallel-agents" skills/ commands/ hooks/ 2>/dev/null || fail "no live references to archived skill"

[[ ! -f commands/brainstorm.md && ! -f commands/write-plan.md && ! -f commands/execute-plan.md ]] || fail "deprecated commands must be removed in 6.0.0"

[[ -x scripts/sync-local-hosts.sh ]] || fail "scripts/sync-local-hosts.sh must exist and be executable"
scripts/sync-local-hosts.sh --dry-run >/tmp/jstack-sync-dry-run.out
grep -q "Codex skill link" /tmp/jstack-sync-dry-run.out || fail "sync dry-run must report Codex skill link"
grep -q "Claude" /tmp/jstack-sync-dry-run.out || fail "sync dry-run must report Claude status"

echo "[PASS] jstack static contract"
