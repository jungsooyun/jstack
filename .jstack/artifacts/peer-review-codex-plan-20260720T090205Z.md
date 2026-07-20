# Peer Review: plan

## Reviewer
codex (gpt-5.6-sol, reasoning=high)

## Prompt
Spec plan review of docs/jstack/specs/2026-07-20-adhd-integration-design.md with standard boundary + plan output contract (repo skills/ explicitly in scope as review subject). Full raw transcript: peer-review-codex-plan-20260720T090205Z.raw

## Raw Output
Verdict: BLOCKING — the plan cannot meet its release and verification gates as written.

- **BLOCKING** — spec:60, skills/writing-skills/SKILL.md:374: Workstreams 1–2 modify behavior-shaping skills without the mandatory pre-edit failing pressure scenarios and post-edit compliance reruns, so their behavioral effect cannot be accepted.
- **BLOCKING** — spec:63, tests/jstack-static/run.sh:46, tests/skill-triggering/run-all.sh:14: Deleting `requesting-code-review` and archiving `dispatching-parallel-agents` leaves existing tests targeting missing skills, making the stated "existing tests pass" gate impossible.
- **HIGH** — spec:33, hooks/hooks.json:5, .codex/INSTALL.md:3: The "all harnesses, once per session" claim is unsupported because Claude reinjects on `clear` and `compact`, while Codex, Gemini, and OpenCode use separate delivery mechanisms absent from the verification plan.
- **HIGH** — spec:26, skills/requesting-code-review/SKILL.md:8: Removing the existing 66-word compatibility redirect in a minor release makes explicit `jstack:requesting-code-review` callers fail while providing negligible consolidation benefit.
- **HIGH** — spec:28, commands/brainstorm.md:5: Deleting the deprecated commands in 5.6.0 violates their published promise of removal in the next major release, breaking users before the announced compatibility boundary.

## Triage
- Accepted:
  - BLOCKING 1 (writing-skills Iron Law): 검증됨 — SKILL.md의 "NO SKILL WITHOUT A FAILING TEST FIRST ... applies to EDITS". 스펙 검증 섹션에 전 워크스트림의 스킬 수정에 pre-edit 실패 시나리오 + post-edit 재실행 요구 추가.
  - BLOCKING 2 (테스트 참조): 검증됨 — jstack-static/run.sh가 requesting-code-review를 grep, skill-triggering/run-all.sh SKILLS 배열에 dispatching-parallel-agents/requesting-code-review 포함. W1에 테스트 갱신 항목 추가.
  - HIGH 1 (하네스 전달 경로): 검증됨 — Codex는 session-start 훅이 아니라 native skill discovery(clone+symlink)로 로드. 스펙의 전달 경로 서술 수정 + 하네스별 검증 추가.
  - HIGH 3 (major 릴리스 약속): 검증됨 — deprecated 커맨드가 "next major release 제거"를 공표. 릴리스를 5.6.0→6.0.0, 5.7.0→6.1.0으로 변경해 semver 정합성 확보 (스킬 삭제도 breaking이므로 일관).
- Rejected (근거 포함):
  - HIGH 2의 "스텁 유지" 함의: requesting-code-review는 이미 peer-review로의 redirect 스텁이며, 모든 호출자가 in-repo(테스트+스킬 상호참조)라 같은 커밋에서 갱신 가능. 단일 사용자 포크 + 사용자가 명시적으로 삭제 선택 + 6.0.0 major 릴리스로 breaking 우려 해소. 단, "이미 redirect 스텁"이라는 사실관계는 스펙에 반영(수용).
- Needs user decision: 없음 (버전 6.0.0 변경은 요약에서 보고)
