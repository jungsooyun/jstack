# Peer Review: plan (implementation plan)

## Reviewer
codex (gpt-5.6-sol, reasoning=high)

## Prompt
Plan review of docs/jstack/plans/2026-07-20-adhd-integration-6.0.0.md against spec. Raw transcript in same-stamp .raw file.

## Raw Output
BLOCKING
- BLOCKING plan:29,200 — Tasks 1/5 lack pre-edit behavioral pressure runs (Iron Law)
- BLOCKING plan:198,234 — per-harness verification omits Gemini/OpenCode, defers Codex
- BLOCKING plan:219 — nonexistent tests/shell-lint/run.sh + `;` masks failure
- HIGH plan:98 — rewired skill-triggering suite never executed
- HIGH plan:15,133 — residual-reference scan narrower than spec (docs/, tests/, *.md excluded)
- HIGH plan:215 — bump-version --audit checks new version, not stale 5.5.1

## Triage
- Accepted (전부):
  1. Task 1 Step 0 + Step 5, Task 5 Step 2 + Step 5에 pre/post 행동 probe 추가 (haiku 프로브, 아티팩트 저장).
  2. 검증 요약에 4개 하네스(Claude/Codex/Gemini/OpenCode) 확인 절차 명시 — Codex/Gemini/OpenCode는 심링크·파일 기반이라 머지 후 finishing 단계가 유일한 검증 지점임을 명시.
  3. Task 6 Step 3을 `&&` 체인으로 교체, 존재하지 않는 shell-lint 제거 (upstream 전용 디렉토리였음 — 검증됨).
  4. Task 2 Step 4에 재배선된 peer-review 트리거 테스트 1회 실행 추가 (전체 스위트는 비용상 제외 — 변경된 항목만).
  5. Task 3 Step 4 스캔을 스펙 W1.5 전체 경로로 확장, 역사 기록만 명시적 glob 제외.
  6. Task 6에 구버전(5.5.1) 문자열 스캔 별도 추가.
- Rejected: 없음
- Needs user decision: 없음
