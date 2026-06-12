# Peer Review: plan

## Reviewer
codex (gpt-5.5, reasoning=high)

## Prompt
Review the spec at docs/jstack/specs/2026-06-13-linear-pm-integration-design.md. (Plan-review boundary prompt; blocking planning issues only. Full prompt in session transcript.)

## Raw Output
**Findings**

1. [Blocking] Delivery target is ambiguous. The spec adds a fixed Linear/Jephalabs integration inside core `skills/`, but the repo PR template says tool-specific or third-party integrations belong in their own plugin, not core (.github/PULL_REQUEST_TEMPLATE.md:18). If this is fork-only, the spec should say so explicitly; if it is meant for upstream Superpowers, the plan is structurally wrong.

2. [Blocking] PR completion semantics are unsafe. The spec says "On merge/PR completion: move the linked issue to Done" (spec:61), but the existing finishing skill's Option 2 only creates a PR and preserves the worktree for iteration (finishing-a-development-branch/SKILL.md:123). Moving Linear to Done at PR creation would mark unfinished work done; waiting for PR merge requires a workflow the spec does not define.

3. [Blocking] The branch-finishing touchpoint lacks a reliable way to find the linked issue. The finishing workflow starts from a branch/worktree state and has no step for locating the relevant spec, parsing the link, or asking when multiple/no specs match. Add this dependency before the Done/Canceled task.

4. [Blocking] Spec-link sequencing conflicts with the current brainstorming flow. The proposal says after the spec is committed, add `linear-issue:` frontmatter and update Linear (spec:55); the current skill commits the design document before self-review/peer-review/user-review (brainstorming/SKILL.md:153). The plan needs to decide whether Linear issue creation/linking happens before the spec commit, via an amend/second commit, or later after review approval.

5. [Blocking] Verification is below the repo's own skill-change bar. The spec lists three happy-path scenario runs plus a trigger-boundary check, but `writing-skills` requires baseline failure first and red/green pressure scenarios for behavior-shaping docs. The implementation plan should include baseline runs, adversarial trigger tests, and before/after outcomes.

## Triage
- Accepted: All 5.
  1. Spec now states fork-only scope (never proposed upstream).
  2. Done only on verified merge; PR-created (Option 2) keeps In Progress + PR-link comment.
  3. Added issue-discovery step (branch/spec frontmatter scan; ask user on no/multiple matches).
  4. Issue is created/linked BEFORE the spec file is written, so `linear-issue:` frontmatter lands in the initial commit; In Progress transition moves to user-approval time.
  5. Verification section upgraded to writing-skills bar: baseline runs + pressure scenarios + before/after evidence.
- Rejected: none.
- Needs user decision: none.
