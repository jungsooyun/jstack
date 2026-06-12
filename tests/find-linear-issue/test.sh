#!/usr/bin/env bash
# tests/find-linear-issue/test.sh — self-contained: builds a temp git repo fixture.
set -euo pipefail
SCRIPT="$(cd "$(dirname "$0")/../.." && pwd)/scripts/find-linear-issue.sh"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

cd "$TMP" && git init -q -b main && git config user.email t@t && git config user.name t
git commit -q --allow-empty -m root

# Empty dirs are not tracked by git: re-mkdir after every checkout that writes specs.
# Case 1: one spec with frontmatter on branch -> prints exactly "JEP-42"
git checkout -q -b feat-a
mkdir -p docs/jstack/specs
printf -- '---\nlinear-issue: JEP-42\n---\n# Spec A\n' > docs/jstack/specs/a-design.md
git add -A && git commit -q -m a
out=$("$SCRIPT" main)
[ "$out" = "JEP-42" ] || fail "case1 got: $out"

# Case 2: no linked docs on branch -> empty output, exit 0
git checkout -q main && git checkout -q -b feat-b
echo x > note.txt && git add -A && git commit -q -m b
out=$("$SCRIPT" main) && [ -z "$out" ] || fail "case2 expected empty/exit0"

# Case 3: two specs -> two lines, sorted unique
git checkout -q main && git checkout -q -b feat-c
mkdir -p docs/jstack/specs
printf -- '---\nlinear-issue: JEP-7\n---\n' > docs/jstack/specs/c1-design.md
printf -- '---\nlinear-issue: JEP-9\n---\n' > docs/jstack/specs/c2-design.md
git add -A && git commit -q -m c
out=$("$SCRIPT" main)
[ "$out" = "$(printf 'JEP-7\nJEP-9')" ] || fail "case3 got: $out"

# Case 4: frontmatter only honored in first block (linear-issue in body ignored)
git checkout -q main && git checkout -q -b feat-d
mkdir -p docs/jstack/specs
printf -- '# Doc\n\nbody mentions linear-issue: JEP-99 but no frontmatter\n' > docs/jstack/specs/d-design.md
git add -A && git commit -q -m d
out=$("$SCRIPT" main) && [ -z "$out" ] || fail "case4 expected empty, got: $out"

echo "PASS"
