---
linear-issue: JEP-296
---

# Simplest-Thing: ponytail 강점의 jstack 흡수 — 설계 스펙

**Date:** 2026-07-02
**Status:** Draft — pending peer review
**Source inspiration:** [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (MIT)

## Problem

jstack 파이프라인(brainstorming → writing-plans → 구현 → verification)은 프로세스 엄밀성은 강하지만, **무엇을 만들지 줄이는 규율**이 없다:

1. **과잉 빌드:** YAGNI가 단어로만 존재한다(writing-plans의 "DRY. YAGNI. TDD." 한 줄). 검사 가능한 절차가 없어서, 구현 서브에이전트는 stdlib 한 줄로 될 일에 클래스와 추상화를 만든다. ponytail 벤치마크 기준 이 낭비는 평균 ~54%, 최대 94%의 불필요 코드다.
2. **과잉 테스트:** TDD 스킬의 Iron Law는 순서(테스트 먼저)를 강제하지만, 어떤 테스트가 존재할 자격이 있는지 기준이 없다. 전역 rules(`~/.claude/rules/common/testing.md`)의 "80% 커버리지 + unit/integration/E2E 전부 필수"는 사용자의 실제 철학(TDD는 좋지만 중요한 테스트만, 커버리지 매몰 반대)과 어긋난다.
3. **추적 안 되는 단순화:** 의도적으로 미룬 것("나중에 per-account lock으로")이 대화 속에서 증발한다.
4. **복잡도 리뷰 부재:** peer-review는 정확성·보안 중심이라, 과잉설계는 리뷰를 통과한다.

## Non-Goals (의도적 제외)

- **강도 모드(lite/full/ultra):** jstack은 스킬 호출형이라 세션 모드 상태 관리가 이질적. 필요가 증명되면 나중에.
- **hook 상시 주입(ponytail 방식):** 비코딩 대화까지 상시 컨텍스트 비용을 냄. 드리프트 방지는 서브에이전트 프롬프트 터치포인트가 대신한다.
- **페르소나("게으른 시니어 개발자") 이식:** jstack의 목소리가 아님. 절차와 규칙만 가져온다.
- **기존 스킬의 튜닝된 본문 재작성:** 터치포인트는 각 2~5줄의 참조 추가로 제한.

## Design

### 1. 새 스킬 `skills/simplest-thing/SKILL.md`

단순성 규율의 단일 진실 공급원. 구현·리팩터·의존성 선택 시 트리거되는 description.

**섹션 구성:**

**The Ladder** — 첫 번째로 버티는 칸에서 멈춘다:
1. 애초에 존재할 필요가 있나? 추측성 필요 = 스킵하고 한 줄로 알린다. (YAGNI)
2. 이 코드베이스에 이미 있나? 헬퍼/유틸/타입/패턴 재사용. 몇 파일 옆의 것을 재구현하는 게 가장 흔한 슬롭.
3. stdlib로 되나?
4. 네이티브 플랫폼 기능으로 되나? (`<input type="date">` > 피커 라이브러리, CSS > JS, DB 제약 > 앱 코드)
5. 이미 설치된 의존성으로 되나? 몇 줄로 될 일에 새 의존성 추가 금지.
6. 한 줄로 되나?
7. 그제서야: 동작하는 최소 코드.

사다리는 이해를 줄이는 게 아니라 해법을 줄인다. 변경이 닿는 파일과 실제 흐름을 끝까지 읽은 뒤에 오른다. 이해를 건너뛰고 작은 diff만 내는 것은 자신감 있는 오답이다. 버그 수정 = 증상이 아니라 근본 원인: 수정할 함수의 모든 caller를 grep한 뒤, 모두가 지나는 지점에 한 번만 고친다.

**Rules:**
- 요청받지 않은 추상화 금지: 구현 하나짜리 인터페이스, 제품 하나짜리 팩토리, 바뀌지 않는 값의 config 금지.
- "나중을 위한" 스캐폴딩 금지. 나중이 알아서 스캐폴딩한다.
- 삭제 > 추가. Boring > clever.
- 최단 동작 diff — 단, 문제를 이해한 다음에. 잘못된 위치의 최소 변경은 두 번째 버그다.
- stdlib 두 옵션이 같은 크기면 엣지 케이스에 올바른 쪽. 게으름 = 코드를 덜 쓰는 것이지 허술한 알고리즘을 고르는 게 아님.

**단순화 마커 `debt:`** — 의도적 단순화는 천장과 업그레이드 경로를 주석으로 남긴다:
```
# debt: global lock — per-account locks if throughput matters
// debt: O(n²) scan — index it past ~10k rows
```
단순함이 무지가 아니라 의도로 읽히게 한다. grep 패턴: `(#|//|--) ?debt:`.

**테스트 자격 게이트** — 테스트를 쓰기 전에 통과해야 하는 질문: **깨지면 손실이 나는 로직인가?** (분기, 루프, 파서, 돈/보안 경계, 데이터 손실 경로)
- 통과 → TDD 규율이 완전 적용: RED 먼저, 실패를 눈으로 확인, GREEN. (Iron Law는 게이트 통과 로직에 대해 무조건 구속력을 가진다.)
- 불통과(자명한 one-liner, 글루 코드, 위임뿐인 코드) → 테스트 없이 진행. YAGNI는 테스트에도 적용된다.
- 커버리지 수치는 목표가 아니다. 게이트를 통과한 테스트가 전부 존재하고 전부 통과하는 것이 목표다.
- 프레임워크·픽스처·함수별 스위트는 요청 없이 만들지 않는다. 게이트를 통과한 비자명 로직의 최소 단위는 runnable check 1개(assert 기반 self-check 또는 작은 test 파일).

**When NOT to be lazy (안전 경계)** — 절대 단순화하지 않는다:
- 트러스트 경계의 입력 검증
- 데이터 손실을 막는 에러 처리
- 보안 조치, 접근성 기본
- 사용자가 명시적으로 요청한 것 — 풀 버전을 고집하면 재논쟁 없이 빌드한다.
- 하드웨어/물리 세계 접점: 캘리브레이션 노브는 남긴다(실제 시계는 드리프트하고 실제 센서는 어긋난다).

**Output 규율:** 코드 먼저, 그 뒤 최대 세 줄: 뭘 스킵했고 언제 추가할지. `[code] → skipped: [X], add when [Y].` 단순화를 방어하는 에세이는 산문으로 밀수된 복잡성이다. (사용자가 명시적으로 요청한 설명은 부채가 아니다 — 전부 제공.)

### 2. 기존 스킬 터치포인트 (각 2~5줄)

| 파일 | 변경 |
|---|---|
| `skills/writing-plans/SKILL.md` | "DRY. YAGNI. TDD." 지점에 확장: 태스크 설계 시 `jstack:simplest-thing`의 Ladder 적용, 태스크별 테스트는 자격 게이트 통과분만 플랜에 포함 |
| `skills/subagent-driven-development/implementer-prompt.md` | **실제 행동 파일은 이쪽** — 기존 YAGNI self-review·targeted-tests 지점에 Ladder 요약 3~4줄 + `debt:` 마커 컨벤션 주입 (드리프트 방지의 jstack식 등가물) |
| `skills/subagent-driven-development/SKILL.md` | simplest-thing 참조 한 줄 |
| `skills/executing-plans/SKILL.md` | 동일한 짧은 참조 |
| `skills/test-driven-development/SKILL.md` | RED 앞에 "테스트 자격 게이트" 참조 추가 **+ 다음 세 지점을 게이트 조건부로 스코프 수정하는 것을 명시적으로 승인** (peer review #1, 2차): (a) "When to Use"의 Always 목록 — behavior change/refactoring/new feature는 *게이트 통과 시* TDD, (b) Iron Law 문구 — "게이트를 통과한 로직에 대해 NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST", (c) rationalization 테이블의 "Too simple to test" 항목 — 주관적 "너무 단순함" 판단은 여전히 거부하되, 단순 여부는 감이 아니라 게이트의 객관 기준(분기/루프/파서/돈/보안 경계)이 결정한다고 재정의. **Red-Green-Refactor 절차 본문과 나머지 Red Flags/rationalization 항목은 불변.** 게이트 없이 참조만 추가하면 양립 불가능한 두 규칙이 공존하게 됨 |
| `skills/peer-review/SKILL.md` | `complexity` 모드 추가: 과잉설계만 사냥, 발견당 한 줄 삭제 리스트(`위치: 뭘 지울지 → 뭘로 대체`), 정확성/보안/성능은 명시적 스코프 밖(기존 review 모드 소관). 자격 게이트 최소 테스트(smoke check 1개)는 절대 삭제 플래그 대상 아님 |
| `skills/project-management/SKILL.md` | debt harvest 터치포인트: `grep -rnE '(#|//|--) ?debt:'` 수확 → capture mode로 Linear 백로그 이슈화 |

### 3. 전역 rules 정합화 (jstack 레포 밖)

- `~/.claude/rules/common/testing.md`: "Minimum Test Coverage: 80%"와 "Test Types (ALL required)"를 자격 게이트 기반 문구로 교체. TDD 워크플로(RED→GREEN→IMPROVE)는 유지하되 "Verify coverage (80%+)" 단계를 "자격 게이트 통과 테스트 전부 통과 확인"으로 교체.
- `~/.claude/rules/common/code-review.md`: 체크리스트의 "Tests exist, coverage ≥ 80%"를 "게이트 통과 로직에 테스트 존재, 전부 통과"로 교체.

이 변경 없이는 전역 rules가 새 스킬과 매 세션 충돌한다. **레포 밖 변경이므로 구현 플랜에서 명시적 별도 태스크로 분리**한다. 사용자 승인 근거: 2026-07-02 대화에서 "커버리지에 매몰되고 싶지 않다" 명시 + 흡수 범위 선택 시 "전역 testing.md의 80% 룰 수정 포함" 옵션 승인 (peer review #5).

### 4. 검증 (writing-skills 규율)

`jstack:writing-skills`의 test-first 규율을 따른다: **스킬을 쓰기 전에 RED baseline부터** — 아래 4개 시나리오를 스킬 없이 실행해 현재 행동(과잉 빌드, junk test 생성 등)을 아티팩트로 기록하고, 스킬 작성 후 같은 시나리오를 재실행해 GREEN 증거를 수집, 둘 다 커밋한다 (peer review #4):
- **과잉 빌드 저항:** 과잉설계를 유도하는 태스크(예: "date picker 만들어줘")에서 스킬 적용 전/후 diff 크기 비교. 기대: 적용 후 네이티브/stdlib 선택.
- **junk test 필터:** 자명한 글루 코드에 테스트를 유도했을 때 자격 게이트가 거부하는지.
- **안전 경계 저항:** "입력 검증도 지워서 더 단순하게 해줘" 공격에 When-NOT-to-be-lazy가 버티는지.
- **재논쟁 금지:** 사용자가 풀 버전을 고집했을 때 순응하는지.

## Error Handling / Edge Cases

- `debt:` 마커가 없는 코드베이스에서 harvest는 빈 결과 → "부채 없음" 보고, 정상 종료.
- Linear 불가 시: 수확 결과를 대화에 보고하고 "Linear sync skipped — manual reconciliation needed"를 알린다. **로컬 원장 파일은 쓰지 않는다** — Linear가 단일 진실 공급원이라는 project-management의 기존 정책 준수 (peer review #2).
- complexity 리뷰와 correctness 리뷰가 같은 diff에서 상충하는 제안을 낼 경우(예: correctness가 방어 코드 추가 요구, complexity가 삭제 제안) → 안전 경계가 우선, 충돌은 사용자에게 표면화.

## Success Criteria

1. pressure test 4종의 RED baseline + GREEN 증거가 커밋에 포함된다.
2. TDD 스킬의 Red-Green-Refactor 절차 본문과 Red Flags 테이블이 불변으로 유지된다 (diff로 확인). 수정은 명시된 스코프 문장에 한정.
3. 전역 rules와 jstack 스킬 간 테스트 정책 모순이 사라진다.

## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Peer Review | codex | 2 | Pass (after fixes) | 1차: blocker 5건 전부 수용·반영. 2차: 4건 해소 확인, TDD 스코프 수정 대상(Always 목록·Iron Law 문구·"Too simple to test" 항목) 명시 열거로 보완 완료 | .jstack/artifacts/peer-review-codex-plan-20260701T225300Z.md |
| Adversarial Review | codex | 0 | Pending | - | - |
