#!/usr/bin/env bash
# find-linear-issue.sh — print linear-issue IDs from docs/** frontmatter changed on this branch.
# Usage: find-linear-issue.sh [base-branch]   (default: main, fallback master)
# Output: one issue ID per line (sorted unique). Empty output + exit 0 = no match.
set -euo pipefail

BASE="${1:-}"
if [[ -z "$BASE" ]]; then
  if git rev-parse --verify -q main >/dev/null; then BASE=main
  elif git rev-parse --verify -q master >/dev/null; then BASE=master
  else echo "error: no base branch found; pass one explicitly" >&2; exit 1; fi
fi

MERGE_BASE=$(git merge-base HEAD "$BASE")
git diff --name-only --diff-filter=ACMR "$MERGE_BASE"...HEAD -- 'docs/' | while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  # Extract value only from the leading YAML frontmatter block.
  awk '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---" { exit }
    NR>1 && /^linear-issue:[[:space:]]*/ { sub(/^linear-issue:[[:space:]]*/, ""); print }
  ' "$f"
done | sort -u
