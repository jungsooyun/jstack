---
linear-issue: JEP-495
status: draft
---

# i-have-adhd Output Contract 통합 + jstack 슬림화

## 문제

1. **출력 스타일이 사용자의 인지 패턴과 안 맞음.** 사용자는 ADHD가 있고(투약 중), 장황한 도입부·곁가지·마무리 인사가 섞인 출력은 핵심 행동을 묻히게 한다. [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd)(MIT)가 이 문제를 다루는 검증된 규칙 세트를 제공하지만, 매 메시지 skill 트리거 방식이라 적용이 불안정하고 사용자의 기존 패턴(Linear 상태관리, verdict-first, 한국어)과 통합돼 있지 않다.
2. **스킬 사용 실측과 구성이 불일치.** Claude Code 트랜스크립트 전수 검색 결과, 실제 Skill 툴 호출은 peer-review 8회 / brainstorming 2회 / project-management 1회 / using-git-worktrees 1회이고 **나머지 13개 스킬은 0회**다(Codex 세션은 로그 포맷상 호출 측정 불가 — 이 수치는 Claude Code 한정). 이는 (a) 중복·미사용 스킬이 목록 고정비만 차지하고 있으며, (b) 파이프라인 스킬의 트리거(description)가 약하다는 신호다.

## 범위

- **6.0.0 릴리스**: 워크스트림 1(스킬 정리) + 워크스트림 2(Output Contract). major인 이유: 스킬 디렉토리 삭제는 명시적 호출자에게 breaking이고, deprecated 커맨드들이 "next major release에 제거"를 공표한 상태라 minor 릴리스에서의 삭제는 semver 약속 위반이다.
- **6.1.0 릴리스**: 워크스트림 3(token diet). 6.0.0의 행동 효과를 관찰한 뒤 별도 진행 — 행동 회귀 시 원인 이분탐색이 가능하도록 릴리스를 분리한다.

### Out of scope

- **크로스 세션 재개 지원**(session-start에서 Linear In Progress 이슈 주입): ADHD 관점에서 세션 간 컨텍스트 단절이 더 큰 문제지만, 세션 시작 지연·네트워크 의존성·비Linear 프로젝트 노이즈 리스크로 이번에는 제외. 향후 별도 이슈로 검토.
- `architecture-deepening` 정리: 유지 결정.
- i-have-adhd 플러그인 자체 설치: 규칙 추출 방식으로 대체.

## 워크스트림 1 — 스킬 정리 (6.0.0)

1. **code-review 2종 정리**: `skills/requesting-code-review/`(66단어)는 **이미 peer-review로의 redirect 스텁**이므로 스텁을 삭제만 한다. `skills/receiving-code-review/`(882단어)는 핵심 규율(성과적 동의 금지, 기술적 검증 우선)을 `skills/peer-review/SKILL.md` 내 "리뷰 피드백 받기" 섹션으로 유실 없이 병합한 뒤 디렉토리를 삭제한다.
2. **dispatching-parallel-agents 아카이브**: `skills/` 밖의 `archive/skills/dispatching-parallel-agents/`로 이동해 스킬 목록에서 제외한다. 네이티브 Agent/Workflow 툴과 기능 중복. 삭제가 아니므로 복원 가능.
3. **deprecated 커맨드 삭제**: `commands/brainstorm.md`, `commands/write-plan.md`, `commands/execute-plan.md` 삭제 (6.0.0 major이므로 "next major release 제거" 공표와 정합).
4. **테스트 갱신 (삭제와 같은 커밋)**: `tests/jstack-static/run.sh`의 requesting-code-review grep 어서션 제거·대체, `tests/skill-triggering/run-all.sh`의 SKILLS 배열에서 dispatching-parallel-agents·requesting-code-review 제거 및 해당 prompts 정리. peer-review 병합 콘텐츠에 대한 static 어서션을 추가한다.
5. **상호 참조 갱신**: `rg "requesting-code-review|receiving-code-review|dispatching-parallel-agents" skills/ commands/ hooks/ docs/ tests/ *.md`로 전수 검색해 남은 참조를 peer-review 또는 네이티브 툴 언급으로 교체한다. 사용자 전역 설정(`~/.claude/CLAUDE.md`, rules/)의 참조는 이 repo 밖이므로 변경 사항을 사용자에게 보고만 한다.

## 워크스트림 2 — ADHD Output Contract (6.0.0)

`skills/using-jstack/SKILL.md` 하단에 **"Output Contract"** 섹션(~150단어, 영문)을 추가한다. 출처 크레딧: `<!-- Adapted from ayghri/i-have-adhd (MIT) -->`.

**하네스별 전달 경로** (경로마다 검증 필요):
- **Claude Code**: session-start 훅이 파일 전문을 주입 (matcher: `startup|clear|compact` — 세션 시작뿐 아니라 clear/compact 시 재주입되므로 컨텍스트 요약 후에도 유지됨).
- **Codex / Gemini / OpenCode**: 훅이 아니라 각 하네스의 native skill discovery로 using-jstack 스킬이 로드될 때 적용된다. 즉 이 하네스들에서는 using-jstack이 활성화된 세션에서만 contract가 유효하다.

### 적용 범위 (핵심 제약)

Contract는 **대화형/상태 출력에만 적용**된다. 다음 아티팩트에는 적용하지 않는다고 명시한다: 스펙, 플랜, 문서, 커밋 메시지, 코드 주석, 리뷰 리포트. 이들은 소속 스킬(brainstorming, writing-plans 등)의 상세성 요구를 따른다.

### 규칙 (원본 10규칙의 조정본)

1. 결론/행동부터 시작 — 도입부·배경 설명 선행 금지 (기존 peer-review verdict-first와 일치).
2. 다단계 작업은 번호 매기기, 리스트는 5개 이하.
3. **다단계 작업 진행 중인 턴**의 끝에 "지금 위치 → 다음 단계" 1-2줄. Linear 연동 작업이면 이슈 ID 포함. 짧은 Q&A 턴에는 적용하지 않는다.
4. 곁가지 억제 — 요청받지 않은 부수 주제는 한 줄 언급 이하로.
5. 시간 추정 대신 규모 감각(S/M/L)과 다음 확인 지점 제시.
6. 오류·실패 시 담담한 어조, 자책·사과 반복 금지.
7. 마무리 인사·"도움이 되길 바랍니다"류 제거.

### 예외 (원본의 예외 조항 유지 — 필수)

사용자가 설명을 요청할 때, 모호성이 있어 질문이 필요할 때, 파괴적 행동 전 확인이 필요할 때는 규칙보다 해당 상황의 요구가 우선한다.

## 워크스트림 3 — Token diet (6.1.0, 별도 릴리스)

1. **description 재작성 — 목표는 축약이 아니라 트리거 품질.** 실측상 파이프라인 스킬 호출이 0회이므로, 남는 15개 스킬의 frontmatter description을 트리거 시나리오 기준으로 재작성한다. 짧아지는 것은 부산물이며, 트리거가 약한 스킬(writing-plans, verification-before-completion 등)은 오히려 트리거 문구가 늘 수 있다. `jstack:writing-skills`의 트리거 테스트 절차로 before/after 검증.
2. **brainstorming(4.8k 단어) core/references 분리.** 실호출 이력이 있고 세션 내 체류가 긴 유일한 대형 스킬. 분리 원칙: **행동 조형 콘텐츠(HARD-GATE, 체크리스트, 프로세스 플로우, 안티패턴)는 core에 유지**하고, 사례·템플릿·부록(visual-companion 상세 등)만 `references/`로 이동. superpowers의 "스킬은 행동 코드" 원칙에 따라 규율 콘텐츠를 optional read로 만들지 않는다.
3. systematic-debugging(5.2k) 분리는 선택 — brainstorming 분리 결과가 좋을 때만. writing-skills(11.7k)와 subagent-driven-development(5.4k)는 이번에 분리하지 않는다(호출 빈도 대비 효과 낮음, writing-skills는 본 작업의 거버넌스 문서).
4. 각 스킬 수정 후 `jstack:peer-review` 게이트 통과를 검증 조건으로 한다.

## 검증

- **writing-skills Iron Law 준수 (전 워크스트림)**: 스킬 콘텐츠(peer-review, using-jstack 포함)를 수정하는 모든 변경은 `jstack:writing-skills`의 절차를 따른다 — 수정 전 실패하는 pressure 시나리오를 먼저 정의하고, 수정 후 해당 시나리오 재실행으로 통과를 확인한다. W3만이 아니라 W1의 peer-review 병합, W2의 using-jstack 수정에도 적용.
- `bash hooks/session-start` 실행 → 출력 JSON이 유효하고 Output Contract 섹션이 포함되는지 확인 (`python3 -m json.tool`로 파싱). Codex 경로는 `~/.codex/` 심링크 기준 skill discovery로 using-jstack 로드를 별도 확인.
- `tests/` 통과 — 단, W1의 테스트 갱신(항목 4)이 같은 커밋에 포함된 상태에서.
- 상호 참조 전수 검색 결과 0건 (워크스트림 1의 삭제 대상 참조).
- 워크스트림별 커밋 분리, 6.0.0 / 6.1.0 버전 범프 + RELEASE-NOTES 갱신.

## 리스크와 완화

| 리스크 | 완화 |
|---|---|
| Contract가 스펙/플랜 상세성과 충돌 | 적용 범위를 대화형 출력으로 한정 + 예외 조항 명시 |
| description 재작성이 트리거를 더 약화 | 축약이 아닌 트리거 품질을 목표로, writing-skills 절차로 검증 |
| core/references 분리로 규율 콘텐츠가 안 읽힘 | 행동 조형 콘텐츠는 core 유지 원칙 명문화 |
| 행동 회귀 원인 추적 불가 | 6.0.0 / 6.1.0 릴리스 분리, 워크스트림별 커밋 |

## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Self-review | claude | 1 | Pass | - | - |
| Peer Review | codex | 1 | Issues Found → 반영됨 | BLOCKING 2 (Iron Law 검증 누락, 테스트 참조 깨짐) + HIGH 3 (하네스 전달 경로, 스텁 삭제, semver) — 4건 수용·1건 부분 수용, 전부 스펙 반영 | .jstack/artifacts/peer-review-codex-plan-20260720T090205Z.md |
