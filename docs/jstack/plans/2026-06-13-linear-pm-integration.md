# Linear PM Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use jstack:subagent-driven-development (recommended) or jstack:executing-plans to implement this plan by executable slices. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `jstack:project-management` skill (Linear MCP backed: capture/next/groom/plan-milestone) plus minimal Linear sync touchpoints in `brainstorming` and `finishing-a-development-branch`, with a deterministic issue-discovery script.

**Architecture:** Linear is the source of truth for backlog/priority/goals. One new skill owns PM intents; two existing skills get small touchpoint sections; one zero-dependency bash script resolves branch → linked issue. Plan tasks are never synced to Linear.

**Tech Stack:** Markdown skills (behavior-shaping docs), Linear MCP tools (`mcp__plugin_linear_linear__*`), bash (script + test).

**Plan Fidelity:** Interface-Level Plan for skill documents (prose is authored at implementation against the spec's exact contract tables), Full-Code for `find-linear-issue.sh` and its test (greenfield executable).

**Spec:** `docs/jstack/specs/2026-06-13-linear-pm-integration-design.md` — the conventions table there is the contract; copy it into the new skill verbatim, do not paraphrase.

**Scope note:** Fork-only. Never propose upstream.

---

### Task 1: Baseline (RED) scenario evidence

Per `jstack:writing-skills`: run pressure scenarios BEFORE the skill exists and record the failure modes.

**Files:**
- Create: `.jstack/artifacts/linear-pm-verification/baseline.md`

**Test-first:** This task IS the RED phase for Tasks 3-5.
**Parallel:** parallel-safe

- [x] **Step 1: Run three baseline scenarios in fresh sessions (no new skill installed)**

Use `claude -p` (or fresh interactive sessions) against this repo with prompts:
1. Capture: "아까 생각났는데, 나중에 spec 검색 캐시도 만들면 좋겠어. 일단 기억해놔줘." — expected failure: idea acknowledged in conversation only; nothing durable created.
2. Next: "다음에 뭘 작업하면 좋을까?" — expected failure: agent guesses from git log; no priority/backlog data consulted.
3. Finish: complete a trivial branch and ask to finish it — expected failure: no issue status transition anywhere.

- [x] **Step 2: Record each transcript excerpt + observed failure mode in `baseline.md`** (scenario prompt, what the agent did, why it fails the PM requirement). No fabrication: paste real output.

- [x] **Step 3: Commit**

```bash
git add .jstack/artifacts/linear-pm-verification/baseline.md
git commit -m "test: record baseline (RED) evidence for Linear PM skill scenarios"
```

---

### Task 2: `scripts/find-linear-issue.sh` + test

**Files:**
- Create: `scripts/find-linear-issue.sh`
- Test: `tests/find-linear-issue/test.sh`

**Test-first:** `test.sh` written and failing (script missing) before implementation.
**Parallel:** parallel-safe

- [x] **Step 1: Write the failing test**

```bash
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
```

- [x] **Step 2: Run test to verify it fails** — `bash tests/find-linear-issue/test.sh` → expected: exit 127 with shell error `.../scripts/find-linear-issue.sh: No such file or directory` (the script doesn't exist yet — this IS the RED; no `PASS` output).

- [x] **Step 3: Implement the script**

```bash
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
```

`chmod +x scripts/find-linear-issue.sh`

- [x] **Step 4: Run test to verify it passes** — `bash tests/find-linear-issue/test.sh` → expected: `PASS`.

- [x] **Step 5: Commit**

```bash
git add scripts/find-linear-issue.sh tests/find-linear-issue/test.sh
git commit -m "feat: add find-linear-issue.sh for branch->Linear issue discovery"
```

---

### Task 3: New skill `skills/project-management/SKILL.md`

**Files:**
- Create: `skills/project-management/SKILL.md`

**Test-first:** RED evidence from Task 1; GREEN verified in Task 6.
**Parallel:** sequential: needs Task 1 (baseline recorded before skill exists)

- [x] **Step 1: Write SKILL.md** with this exact structure:

Frontmatter (triggers are the critical surface):

```yaml
---
name: project-management
description: Use when deciding what to work on next, capturing ideas or todos into the backlog, grooming/reviewing the backlog, or planning milestones - manages project context in Linear (source of truth for backlog, priorities, goals). NOT for clear feature requests, which go straight to brainstorming.
---
```

Required sections, in order:
1. **Overview** — Linear is the source of truth; announce-at-start line ("I'm using the project-management skill...").
2. **Linear Conventions** — copy the spec's conventions table VERBATIM (Team Jephalabs / Project=product / Milestone=goal / Issue=spec unit / states Backlog→Todo→In Progress→Done→Canceled / priority unset at capture / `linear-issue:` frontmatter contract).
3. **Modes** — four subsections, each: trigger phrases, exact MCP tools used, step list, what NOT to do:
   - **capture**: `save_issue` (team Jephalabs, state Backlog, title + 1-line description, project assignment; ask which project ONLY if genuinely ambiguous). No priority, no milestone at capture. **Missing project branch:** check via `list_projects`; if no matching project exists, propose creating one (`save_project`) and get user confirmation before creating — never create a project silently, and never file the issue project-less without telling the user.
   - **next**: `list_issues` (states Backlog/Todo, order by priority then milestone) → recommend ≤3 candidates with one-line reasons → on selection, hand off to `jstack:brainstorming` with the issue as context and the issue ID for later linking.
   - **groom**: `list_issues` + `save_issue` + `save_comment`; flag stale (>30d untouched), propose duplicate merges and priority changes — every mutation individually confirmed by the user, no silent bulk edits.
   - **plan-milestone**: `save_milestone` + assign issues; milestone = goal bundle, Cycles unused.
4. **Failure Handling** — Linear MCP unavailable: next/groom/plan-milestone state plainly they cannot run and stop; capture must tell the user the idea was NOT saved (never silently write a local file).
5. **Red Flags table** — at minimum: "feature request is clear → don't detour here", "syncing plan tasks to Linear → never", "guessing project assignment → ask".

- [x] **Step 2: Static sanity check** — `ls skills/project-management/SKILL.md && head -5 skills/project-management/SKILL.md` shows valid frontmatter matching other skills.

- [x] **Step 3: Commit**

```bash
git add skills/project-management/SKILL.md
git commit -m "feat: add project-management skill (Linear-backed PM layer)"
```

---

### Task 4: Brainstorming touchpoints

**Files:**
- Modify: `skills/brainstorming/SKILL.md` (checklist ~line 34-50, "After the Design" ~line 140-160)

**Test-first:** covered by Task 6 scenario (c) and pressure test (a).
**Parallel:** sequential: needs Task 3 (references the new skill by name)

- [ ] **Step 1: Add entry branch** — in the checklist near item 1 and in "The Process > Understanding the idea": if the build target itself is undecided ("다음 뭐 하지" style entry), invoke `jstack:project-management` (next mode) first, then return here with the chosen issue.

- [ ] **Step 2: Add Linear linking to the "After the Design" documentation flow**, preserving peer-review-fixed sequencing:
  - BEFORE writing the spec file: ensure the Linear issue exists (create via `jstack:project-management` capture conventions if missing) so `linear-issue: <ID>` frontmatter is in the spec's initial commit.
  - If issue creation FAILS at this point (Linear unavailable): **omit the `linear-issue:` frontmatter line entirely** — no placeholder values — write and commit the spec normally, and announce "Linear sync skipped — manual reconciliation needed (add linear-issue frontmatter + create the issue later, e.g. via project-management groom)."
  - Right after the spec commit: set the spec path in the Linear issue description.
  - AFTER the User Review Gate passes: move the issue to In Progress.
  - On any other Linear failure: do not block; state "Linear sync skipped — manual reconciliation needed."

- [ ] **Step 3: Add "later" idea capture** — one line in "Understanding the idea": ideas deferred during brainstorming are captured as Backlog issues (project-management capture mode).

- [ ] **Step 4: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "feat: add Linear issue touchpoints to brainstorming skill"
```

---

### Task 5: Finishing-a-development-branch touchpoints

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md` (after "Step 3: Determine Base Branch" ~line 59-67, and inside each Option in Step 5)

**Test-first:** covered by Task 6 scenario (c) and pressure tests (b)(c).
**Parallel:** sequential: needs Task 2 (references the script) and Task 3 (references conventions)

- [ ] **Step 1: Add "Step 3.5: Locate Linked Linear Issue"** — run `scripts/find-linear-issue.sh <base-branch>` (note: script lives in the jstack repo; in other repos, fall back to the same `git diff --name-only <base>...HEAD -- docs/` + frontmatter scan inline). Exactly one ID → proceed with it. Zero or multiple → ask the user which issue (or none) applies. Never guess.

- [ ] **Step 2: Add status transitions per option** (Done means merged, not submitted):
  - Option 1 (merge locally): after merge succeeds and tests pass → issue to Done + comment with merge commit.
  - Option 2 (push & PR): keep In Progress + comment the PR link; Done happens later when the user confirms merge.
  - Option 3 (keep as-is): no status change.
  - Option 4 (discard): ask Backlog (still valid) vs Canceled (dropped).
  - Any Linear failure: proceed with git workflow, announce "Linear sync skipped — manual reconciliation needed."

- [ ] **Step 3: Commit**

```bash
git add skills/finishing-a-development-branch/SKILL.md
git commit -m "feat: add Linear status transitions to finishing-a-development-branch"
```

---

### Task 6: Registration, GREEN + pressure verification

**Files:**
- Modify: `README.md` (skill list section — add project-management one-liner)
- Create: `.jstack/artifacts/linear-pm-verification/green-and-pressure.md`

**Test-first:** N/A — this IS the GREEN/pressure phase.
**Parallel:** sequential: needs Tasks 2-5

- [ ] **Step 1: Update README skill list** and run `scripts/sync-local-hosts.sh --dry-run`; if it reports pending host sync for the new skill, run `--apply`.

- [ ] **Step 2: GREEN scenarios** (fresh sessions, skill installed) — rerun Task 1's three scenarios. Expected: (1) capture creates a real Backlog issue in Jephalabs; (2) next consults Linear and recommends with priority reasons; (3) finishing Option 1 → Done with comment, and separately Option 2 → stays In Progress with PR-link comment (two runs).

- [ ] **Step 3: Pressure scenarios** — (a) clear feature request "X 기능 만들어줘" must NOT detour through project-management; (b) finish a branch with no linked spec → agent asks, does not guess; (c) with Linear MCP disabled, capture states the idea was NOT saved, touchpoints announce skipped sync without blocking; (d) capture an idea for a product with no existing Linear project → agent runs `list_projects`, proposes project creation, and waits for user confirmation before `save_project`.

- [ ] **Step 4: Live evidence** — inspect the Jephalabs workspace (list_issues) after each GREEN run; states/links must match the conventions table. Record before/after in `green-and-pressure.md`. If any scenario fails, fix the skill text (REFACTOR), rerun that scenario, and record the second run.

- [ ] **Step 5: Update the spec's `## JSTACK REVIEW REPORT`** (Verification + Live Evidence rows) and commit:

```bash
git add README.md .jstack/artifacts/linear-pm-verification/green-and-pressure.md docs/jstack/specs/2026-06-13-linear-pm-integration-design.md
git commit -m "test: GREEN + pressure verification evidence for Linear PM integration"
```

---

## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Spec Review | Codex | 1 | Issues Found → Fixed | 5 blocking, all applied | .jstack/artifacts/peer-review-codex-plan-20260613T005900Z.md |
| Plan Review | Codex | 1 | Issues Found → Fixed | 4 blocking: test fixture mkdir, RED expectation exit-127, Linear-fail-before-spec rule, missing-project branch | .jstack/artifacts/peer-review-codex-plan-20260613T012500Z.md |
| Peer Review | Codex | 2 | Pass (post-fix, spec+plan) | - | .jstack/artifacts/peer-review-codex-plan-20260613T012500Z.md |
| Adversarial Review | Claude/Codex | 0 | Pending | - | - |
| Verification | Scenario runs | 0 | Pending | - | - |
| Live Evidence | Jephalabs workspace | 0 | Pending | - | - |

## Execution Handoff

Cleanup note: Task 1 and Task 6 scenario runs may create throwaway issues in Jephalabs — title them with a `[test]` prefix and archive them during Task 6 Step 4.
