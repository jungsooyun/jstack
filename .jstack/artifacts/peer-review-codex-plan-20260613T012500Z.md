# Peer Review: plan

## Reviewer
codex (gpt-5.5, reasoning=high)

## Prompt
Review the implementation plan at docs/jstack/plans/2026-06-13-linear-pm-integration.md against its spec. Blocking planning issues only; also verify the Task 2 bash script and test are correct and runnable as written.

## Raw Output
**Findings**

1. **Blocking: Task 2 test is not runnable after the script is added.** `docs/jstack/specs` is created before the root commit, but empty directories are not tracked by Git. After `git checkout -q main` in later cases, the directory no longer exists, so Case 3/4 fail with `No such file or directory`. Fix: add `mkdir -p docs/jstack/specs` after each branch checkout that writes spec files.

2. **Blocking: Task 2 RED expectation is inaccurate.** Plan says the missing-script RED run should produce `FAIL`, but the test exits via shell error before `fail()` runs: `No such file or directory`, exit `127`. Still a valid RED; record the actual expected result.

3. **Blocking ambiguity: Linear failure during initial spec linking is underspecified.** Spec requires `linear-issue:` in the initial spec commit but touchpoint failures must not block. Plan does not specify what to write when issue creation fails before the spec exists. Fix: explicitly say whether to omit `linear-issue:` on failure, use no placeholder, and record "manual reconciliation needed."

4. **Blocking missed requirement: missing-project behavior is not planned or tested.** Conventions say the skill proposes project creation if missing, but Task 3 capture only names `save_issue` (no `list_projects`/`save_project` + user confirmation), and Task 6 lacks a missing-project verification case.

**Task 2 Verification** — reviewer ran the snippets in an isolated temp repo: missing-script RED exits 127; GREEN as written fails Case 3 on missing dir; with the mkdir fix the script logic passes all four cases.

## Triage
- Accepted: All 4.
  1. `mkdir -p docs/jstack/specs` added after each checkout (cases 1, 3, 4).
  2. RED expectation rewritten as exit 127 + shell error.
  3. Rule added: on issue-creation failure before spec write, omit `linear-issue:` frontmatter entirely (no placeholder), commit normally, announce manual reconciliation (link later via groom).
  4. capture mode gains missing-project branch (`list_projects` → propose `save_project` → user confirmation, never silent); pressure scenario (d) added to Task 6.
- Rejected: none.
- Needs user decision: none.
