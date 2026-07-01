# Peer Review: plan

## Reviewer
codex (gpt-5.5, reasoning=high)

## Prompt
Review the design spec at docs/jstack/specs/2026-07-02-simplest-thing-design.md.

Context: this spec absorbs ideas from the ponytail project (github.com/DietrichGebert/ponytail) into this skills library: a new simplest-thing skill (7-rung simplicity ladder, debt: marker convention, test qualification gate), small touchpoints in existing skills (writing-plans, subagent-driven-development, executing-plans, test-driven-development, peer-review complexity mode, project-management debt harvest), and alignment of the user's global test-coverage rules. Verify the spec's claims about existing skill files against the actual files in skills/.

Review for blocking planning issues only: missed requirements, contradictions, ambiguous implementation choices, unsafe sequencing, missing tests, scope creep, YAGNI violations, and dependencies not reflected in the task order.

(Boundary prefix included; repo itself exempted as it is the skills library under review.)

## Raw Output
**Findings**

1. Blocker: the test qualification gate contradicts the current TDD skill while the spec says to leave the Iron Law unchanged.
The spec allows no-test implementation for "자명한 one-liner, 글루 코드, 위임뿐인 코드" and says only gate-passing tests matter (spec:60), but the existing TDD skill says behavior changes always use TDD, "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST," and every new function/method has a test (test-driven-development/SKILL.md:18, :34, :289). Adding a short reference before RED while keeping the body unchanged (spec:82) will create two incompatible rules.

2. Blocker: the project-management fallback is opposite to the current Linear failure policy.
The spec says Linear-unavailable debt harvest should fall back to proposing a local `DEBT.md` (spec:104). Current `project-management` explicitly says capture must tell the user the idea was not saved and must not write a local todo file because Linear is the single source of truth (project-management/SKILL.md:118, :123). The spec needs either to remove the `DEBT.md` fallback or explicitly change that source-of-truth policy.

3. Blocker: the subagent touchpoint targets the wrong behavioral file.
The spec says to inject the Ladder and `debt:` convention into the implementation subagent prompt via `skills/subagent-driven-development/SKILL.md` (spec:80). The actual implementer prompt is the referenced implementer-prompt.md (:3), and it owns the instructions about targeted tests, TDD-if-task-says-so, and YAGNI self-review (:43, :57, :112). Without adding that file to the task list, the planned drift-prevention path likely won't reach implementers.

4. Blocker: the verification plan does not satisfy `writing-skills` test-first requirements for skill changes.
The spec lists pressure tests as verification evidence after the design (spec:93), but current `writing-skills` requires failing baseline pressure scenarios before new skills or edits, including documenting behavior without the skill (writing-skills/SKILL.md:377, :537, :600). The task order needs an explicit RED baseline artifact before drafting or editing `simplest-thing`.

5. Blocker: global rule changes are required for success but sit outside the repo and outside what I could verify here.
The spec says `~/.claude/rules/common/*` must change or every session will conflict (spec:86). I did not inspect those files because your instruction forbids reading `~/.claude/`. If those changes remain a success criterion, the implementation plan needs a separate explicit user-approved external-config step, not just a repo-local skill change.

I did not edit files or spawn subagents.

## Triage
- Accepted:
  - #1 — TDD 스킬의 스코프 문장("every new function/method has a test", "behavior changes always TDD")을 게이트 조건부로 명시 수정하는 것으로 스펙 변경. Red-Green 절차 본문과 Red Flags 테이블은 불변 유지.
  - #2 — DEBT.md 폴백 제거. Linear 실패 시 기존 정책 준수: 대화에 수확 결과 보고 + "Linear sync skipped — manual reconciliation needed", 로컬 원장 파일 미작성.
  - #3 — 터치포인트에 `skills/subagent-driven-development/implementer-prompt.md` 추가 (기존 YAGNI self-review 지점 확장).
  - #4 — 검증 순서 수정: 스킬 작성 전 RED baseline(스킬 없는 행동 기록) → 작성 → GREEN 재실행. writing-skills 규율 준수.
  - #5 — 전역 rules 변경을 명시적 별도 태스크로 분리, 사용자 승인 근거(2026-07-02 대화) 기록.
- Rejected: 없음
- Needs user decision: 없음 (#5의 승인은 이미 확보됨)
