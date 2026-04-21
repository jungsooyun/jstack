#!/usr/bin/env bash
set -euo pipefail

MODE="dry-run"

usage() {
  cat <<'EOF'
Usage: scripts/sync-local-hosts.sh [--dry-run|--apply]

Synchronize this local JStack checkout with Codex and Claude host configuration.
The script keeps Superpowers compatibility aliases unless you remove them manually.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOME_DIR="${HOME:?HOME is required}"
CODEX_SKILLS="$HOME_DIR/.codex/skills"
AGENTS_SKILLS="$HOME_DIR/.agents/skills"
CLAUDE_SETTINGS="$HOME_DIR/.claude/settings.json"
CLAUDE_MD="$HOME_DIR/.claude/CLAUDE.md"

run() {
  if [[ "$MODE" == "apply" ]]; then
    "$@"
  else
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  fi
}

link_dir() {
  local target="$1"
  local link="$2"
  local label="$3"

  echo "$label: $link -> $target"
  if [[ -L "$link" ]]; then
    local current
    current="$(readlink "$link")"
    if [[ "$current" == "$target" ]]; then
      echo "  ok"
      return
    fi
    echo "  would replace stale symlink currently pointing to $current"
    run rm "$link"
  elif [[ -e "$link" ]]; then
    echo "  exists and is not a symlink; leaving untouched"
    return
  fi

  run mkdir -p "$(dirname "$link")"
  run ln -s "$target" "$link"
}

echo "JStack root: $ROOT"
echo "Mode: $MODE"
echo

link_dir "$ROOT/skills" "$CODEX_SKILLS/jstack" "Codex skill link"
link_dir "$ROOT/skills" "$AGENTS_SKILLS/jstack" "Agents skill link"

echo
echo "Compatibility aliases:"
link_dir "$ROOT" "$HOME_DIR/.codex/superpowers" "Legacy repo alias"
link_dir "$ROOT/skills" "$CODEX_SKILLS/superpowers" "Legacy Codex skill alias"

echo
echo "Claude status:"
if [[ -f "$CLAUDE_SETTINGS" ]]; then
  echo "  settings: $CLAUDE_SETTINGS"
  if grep -q '"superpowers@claude-plugins-official"[[:space:]]*:[[:space:]]*true' "$CLAUDE_SETTINGS"; then
    echo "  warning: official Superpowers plugin is enabled; disable it after local JStack plugin registration is verified"
  else
    echo "  official Superpowers plugin not enabled"
  fi
else
  echo "  settings file missing: $CLAUDE_SETTINGS"
fi

if [[ -f "$CLAUDE_MD" ]]; then
  echo "  guidance: $CLAUDE_MD"
  if grep -q 'superpowers:' "$CLAUDE_MD"; then
    echo "  warning: CLAUDE.md still references superpowers:*; replace with jstack:* after plugin registration"
  else
    echo "  CLAUDE.md does not reference superpowers:*"
  fi
else
  echo "  guidance file missing: $CLAUDE_MD"
fi

echo
echo "Next manual Claude step:"
echo "  Register this checkout as a local Claude plugin, then update enabledPlugins to jstack."
