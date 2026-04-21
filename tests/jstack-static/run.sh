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
grep -q "docs/jstack/specs" skills/brainstorming/SKILL.md || fail "brainstorming must write specs under docs/jstack/specs"
grep -q "Problem Framing Gate" skills/brainstorming/SKILL.md || fail "brainstorming must include Problem Framing Gate"
grep -q "docs/jstack/plans" skills/writing-plans/SKILL.md || fail "writing-plans must write plans under docs/jstack/plans"
grep -q "JSTACK REVIEW REPORT" skills/writing-plans/SKILL.md || fail "writing-plans must define JSTACK REVIEW REPORT"

grep -q "jstack:" skills/writing-plans/SKILL.md || fail "writing-plans must reference jstack skill namespace"
grep -q "jstack:" skills/subagent-driven-development/SKILL.md || fail "subagent-driven-development must reference jstack skill namespace"
grep -q "jstack:" skills/requesting-code-review/SKILL.md || fail "requesting-code-review must reference jstack skill namespace"

[[ -x scripts/sync-local-hosts.sh ]] || fail "scripts/sync-local-hosts.sh must exist and be executable"
scripts/sync-local-hosts.sh --dry-run >/tmp/jstack-sync-dry-run.out
grep -q "Codex skill link" /tmp/jstack-sync-dry-run.out || fail "sync dry-run must report Codex skill link"
grep -q "Claude" /tmp/jstack-sync-dry-run.out || fail "sync dry-run must report Claude status"

echo "[PASS] jstack static contract"
