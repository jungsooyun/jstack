# ADHD Output Contract + Skill Cleanup (6.0.0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use jstack:subagent-driven-development (recommended) or jstack:executing-plans to implement this plan by executable slices. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** i-have-adhd 기반 Output Contract를 using-jstack에 추가하고, 미사용 스킬 3종 + deprecated 커맨드 3종을 정리하여 6.0.0을 릴리스한다.

**Architecture:** 스펙 `docs/jstack/specs/2026-07-20-adhd-integration-design.md`(JEP-495)의 W1+W2. 각 태스크는 정적 계약 테스트(`tests/jstack-static/run.sh`)에 실패하는 어서션을 먼저 추가(RED)한 뒤 콘텐츠를 수정(GREEN)한다 — writing-skills Iron Law 준수. 6.1.0(token diet)은 별도 플랜.

**Tech Stack:** Bash 정적 테스트, Claude Code plugin 구조 (skills/, commands/, hooks/), scripts/bump-version.sh

**Plan Fidelity:** Interface-Level Plan — 기존 프로즈 편집이 대부분이라 전체 본문 재작성은 stale 위험이 있고, 새로 추가되는 두 프로즈 블록(Output Contract, Receiving Review Feedback)만 전문을 포함한다.

**Worktree:** `.claude/worktrees/jep-495-adhd-integration` (branch `worktree-jep-495-adhd-integration`, base = local main `8ed2ee8`)

**참조 노트:** 배포는 main 머지로 완결된다 — `~/.codex/skills/jstack`·`~/.codex/skills/superpowers`가 `~/.codex/jstack/skills` 심링크라서 Codex는 머지 즉시 반영, Claude Code plugin도 같은 체크아웃을 바라본다. RELEASE-NOTES·docs/plans·docs/superpowers 내 과거 기록의 스킬명 언급은 역사 기록이므로 수정하지 않는다.

---

### Task 1: receiving-code-review → peer-review 병합

**Files:**
- Modify: `skills/peer-review/SKILL.md` (Finding Triage 섹션 앞에 새 섹션)
- Modify: `tests/jstack-static/run.sh`
- Delete: `skills/receiving-code-review/`

**Test-first:** 행동 베이스라인 probe(RED) + 정적 어서션 — peer-review에 "Receiving Review Feedback" 섹션 존재 + receiving-code-review 디렉토리 부재
**Parallel:** sequential (Task 2와 같은 테스트 파일 수정)

- [ ] **Step 0: Iron Law 베이스라인 probe (수정 전).** 현재(병합 전) peer-review SKILL.md만 컨텍스트로 넣고 리뷰 피드백 수신 시나리오를 1회 실행, 결과를 `.jstack/artifacts/pressure-task1-baseline.txt`에 저장:

```bash
claude -p --model claude-haiku-4-5 "다음 스킬 지침을 따르라: $(cat skills/peer-review/SKILL.md)

리뷰어가 '이 레거시 코드 제거하세요'라고 피드백했다. 어떻게 응답할지 답하라." > .jstack/artifacts/pressure-task1-baseline.txt
```

기대(RED 근거): 현행 peer-review에는 수신 규율 섹션이 없어 성과적 동의 금지·검증 우선 지침이 응답에 반영된다는 보장이 없음을 기록.

- [ ] **Step 1: RED — 어서션 추가.** `tests/jstack-static/run.sh`에 추가:

```bash
grep -q "## Receiving Review Feedback" skills/peer-review/SKILL.md || fail "peer-review must absorb receiving-code-review discipline"
grep -q "performatively agree" skills/peer-review/SKILL.md || fail "peer-review must retain no-performative-agreement rule"
[[ ! -d skills/receiving-code-review ]] || fail "receiving-code-review must be merged into peer-review"
```

- [ ] **Step 2: 실행 → FAIL 확인.** Run: `bash tests/jstack-static/run.sh` → Expected: FAIL "peer-review must absorb..."

- [ ] **Step 3: peer-review SKILL.md에 병합.** `## Finding Triage` 섹션 바로 앞에 삽입 (핵심 규율 압축본, 유실 금지 항목: 성과적 동의 금지·검증 우선·불명확 항목 전체 클라리파이·한 항목씩 구현·기술적 pushback·GitHub 스레드 답글):

```markdown
## Receiving Review Feedback

When feedback arrives — from your human partner, a peer reviewer, or GitHub:

1. READ all items without reacting. If any item is unclear, stop and ask before
   implementing any of them — items may be related, and partial understanding
   produces wrong implementations.
2. VERIFY each claim against codebase reality before implementing.
3. RESPOND technically. Never performatively agree — no "You're absolutely
   right!", no "Great point!", no gratitude. State the requirement, ask, push
   back with evidence, or just fix it: the diff is the acknowledgment.
4. IMPLEMENT one item at a time — blocking issues, then simple fixes, then
   complex ones — testing each before the next.
5. PUSH BACK with technical reasoning when a suggestion breaks existing
   functionality, lacks context, violates YAGNI (grep for actual usage first),
   or conflicts with your human partner's architectural decisions. If you
   pushed back and were wrong, state the correction factually and move on.

For GitHub inline review comments, reply in the comment thread
(`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a
top-level PR comment.
```

- [ ] **Step 4: 디렉토리 삭제.** Run: `git rm -r skills/receiving-code-review`

- [ ] **Step 5: GREEN 확인 + 사후 probe.** Run: `bash tests/jstack-static/run.sh` → Expected: `[PASS] jstack static contract`. Step 0과 동일한 probe를 병합된 SKILL.md로 재실행해 `.jstack/artifacts/pressure-task1-after.txt` 저장 → 기대: 응답이 검증-우선 패턴을 따르고 성과적 동의 문구("You're absolutely right" 류) 없음.

- [ ] **Step 6: Commit.** `git add -A && git commit -m "refactor(skills): merge receiving-code-review into peer-review (JEP-495)"`

### Task 2: requesting-code-review 스텁 삭제 + 트리거 테스트 재배선

**Files:**
- Modify: `tests/jstack-static/run.sh:46` (기존 어서션 교체)
- Modify: `tests/skill-triggering/run-all.sh` (SKILLS 배열)
- Rename: `tests/skill-triggering/prompts/requesting-code-review.txt` → `peer-review.txt`
- Delete: `skills/requesting-code-review/`

**Test-first:** 기존 line 46 어서션이 삭제 후 fail하므로 교체가 곧 테스트 갱신; 부재 어서션 추가
**Parallel:** sequential: needs Task 1

- [ ] **Step 1: 정적 테스트 교체.** `tests/jstack-static/run.sh:46`의 `grep -q "jstack:" skills/requesting-code-review/SKILL.md ...` 줄을 다음으로 교체:

```bash
[[ ! -d skills/requesting-code-review ]] || fail "requesting-code-review stub must be deleted (consolidated into peer-review)"
grep -q "## When to Request" skills/peer-review/SKILL.md || fail "peer-review must retain When to Request section"
```

- [ ] **Step 2: RED 확인.** Run: `bash tests/jstack-static/run.sh` → Expected: FAIL "requesting-code-review stub must be deleted"

- [ ] **Step 3: 삭제 + 트리거 테스트 재배선.**

```bash
git rm -r skills/requesting-code-review
git mv tests/skill-triggering/prompts/requesting-code-review.txt tests/skill-triggering/prompts/peer-review.txt
```

`tests/skill-triggering/run-all.sh`의 SKILLS 배열에서 `"requesting-code-review"`를 `"peer-review"`로 교체 (트리거 커버리지 유지 — 완료 후 리뷰 요청 프롬프트는 이제 peer-review를 트리거해야 함).

- [ ] **Step 4: GREEN 확인 + 재배선된 트리거 테스트 실행.** Run: `bash tests/jstack-static/run.sh` → PASS. Run: `bash tests/skill-triggering/run-test.sh peer-review tests/skill-triggering/prompts/peer-review.txt 3` → Expected: 트리거 성공 (완료-후-리뷰 프롬프트가 peer-review를 트리거). 실패 시 프롬프트 문구를 peer-review description에 맞게 조정 후 재실행.

- [ ] **Step 5: Commit.** `git commit -am "refactor(skills): delete requesting-code-review stub, retarget trigger test to peer-review (JEP-495)"`

### Task 3: dispatching-parallel-agents 아카이브 + 라이브 참조 갱신

**Files:**
- Move: `skills/dispatching-parallel-agents/` → `archive/skills/dispatching-parallel-agents/`
- Modify: `skills/subagent-driven-development/SKILL.md:74`, `skills/using-jstack/references/codex-tools.md:25`, `skills/using-jstack/references/gemini-tools.md:21`, `README.md:158-162` 부근, `docs/README.codex.md:35`
- Modify: `tests/jstack-static/run.sh`, `tests/skill-triggering/run-all.sh` (배열에서 제거), Delete: `tests/skill-triggering/prompts/dispatching-parallel-agents.txt`

**Test-first:** 부재 + 아카이브 존재 + 라이브 참조 0건 어서션
**Parallel:** sequential: needs Task 2 (같은 테스트 파일)

- [ ] **Step 1: RED — 어서션 추가.** `tests/jstack-static/run.sh`에 추가:

```bash
[[ ! -d skills/dispatching-parallel-agents ]] || fail "dispatching-parallel-agents must be archived"
[[ -f archive/skills/dispatching-parallel-agents/SKILL.md ]] || fail "archived dispatching-parallel-agents must be preserved"
! rg -q --no-messages "dispatching-parallel-agents" skills/ commands/ hooks/ 2>/dev/null || fail "no live references to archived skill"
```

Run → Expected: FAIL "must be archived"

- [ ] **Step 2: 아카이브 이동.** `mkdir -p archive/skills && git mv skills/dispatching-parallel-agents archive/skills/`

- [ ] **Step 3: 라이브 참조 갱신.**
  - `skills/subagent-driven-development/SKILL.md:74`: "dispatch them concurrently in one batch via jstack:dispatching-parallel-agents" → "dispatch them concurrently in one batch (multiple agent invocations in a single message)"
  - `skills/using-jstack/references/codex-tools.md:25` / `gemini-tools.md:21`: dispatching-parallel-agents 언급을 subagent-driven-development만 남기고 제거
  - `README.md` 스킬 목록: requesting-code-review·receiving-code-review·dispatching-parallel-agents 항목 제거 (Task 1-2 잔여분 포함)
  - `docs/README.codex.md:35`: dispatching-parallel-agents 언급 제거
  - `tests/skill-triggering/run-all.sh` SKILLS 배열에서 `"dispatching-parallel-agents"` 제거, `git rm tests/skill-triggering/prompts/dispatching-parallel-agents.txt`

- [ ] **Step 4: GREEN + 잔여 참조 스캔 (스펙 W1.5 전체 경로).** Run: `bash tests/jstack-static/run.sh` → PASS. Run:

```bash
rg -ln "requesting-code-review|receiving-code-review|dispatching-parallel-agents" \
  skills/ commands/ hooks/ tests/ docs/ README.md AGENTS.md CLAUDE.md GEMINI.md \
  --glob '!docs/plans/**' --glob '!docs/superpowers/**' \
  --glob '!docs/jstack/plans/**' --glob '!docs/jstack/specs/**' 2>/dev/null
```

Expected: 출력 없음 (역사 기록 — RELEASE-NOTES.md, 과거 plans/specs — 만 제외 대상이며 라이브 문서·테스트·스킬은 전부 스캔에 포함)

- [ ] **Step 5: Commit.** `git commit -am "refactor(skills): archive dispatching-parallel-agents, update live references (JEP-495)"`

### Task 4: deprecated 커맨드 3종 삭제

**Files:**
- Delete: `commands/brainstorm.md`, `commands/write-plan.md`, `commands/execute-plan.md`
- Modify: `tests/jstack-static/run.sh`

**Test-first:** 부재 어서션
**Parallel:** sequential: needs Task 3 (같은 테스트 파일)

- [ ] **Step 1: RED.** 어서션 추가: `[[ ! -f commands/brainstorm.md && ! -f commands/write-plan.md && ! -f commands/execute-plan.md ]] || fail "deprecated commands must be removed in 6.0.0"` → Run → FAIL

- [ ] **Step 2: 삭제.** `git rm commands/brainstorm.md commands/write-plan.md commands/execute-plan.md` (commands/ 디렉토리가 비면 plugin manifest가 commands를 요구하는지 `.claude-plugin/plugin.json` 확인 — commands 키 없음, 디렉토리 부재 허용)

- [ ] **Step 3: GREEN.** Run: `bash tests/jstack-static/run.sh` → PASS

- [ ] **Step 4: Commit.** `git commit -am "feat(commands)!: remove deprecated brainstorm/write-plan/execute-plan commands (JEP-495)"`

### Task 5: Output Contract 추가 (using-jstack)

**Files:**
- Modify: `skills/using-jstack/SKILL.md` (파일 말미에 새 섹션)
- Modify: `tests/jstack-static/run.sh`

**Test-first:** 콘텐츠 존재 어서션 + session-start JSON 유효성
**Parallel:** sequential: needs Task 4 (같은 테스트 파일)

- [ ] **Step 1: RED — 어서션 추가.**

```bash
grep -q "## Output Contract" skills/using-jstack/SKILL.md || fail "using-jstack must include ADHD output contract"
grep -q "ayghri/i-have-adhd" skills/using-jstack/SKILL.md || fail "output contract must credit source"
grep -q "conversational and status output only" skills/using-jstack/SKILL.md || fail "output contract must scope to conversational output"
```

Run → FAIL

**[Step 3에서 삽입할 전문]** — `skills/using-jstack/SKILL.md` 말미(`## User Instructions` 섹션 뒤)에 삽입:

```markdown
## Output Contract

<!-- Adapted from ayghri/i-have-adhd (MIT) — condensed and adapted for jstack -->

Scope: **conversational and status output only.** Artifacts — specs, plans,
docs, commit messages, code comments, review reports — follow their owning
skill's fidelity requirements, not this contract.

1. Lead with the verdict or action. No warm-up context before the point.
2. Number multi-step work. Keep lists to 5 items or fewer.
3. When a turn advances multi-step work, end with 1-2 lines: current position →
   next step. Include the Linear issue ID when the work is linked to one. Skip
   this on short Q&A turns.
4. Suppress tangents — unrequested side topics get one line at most.
5. Give effort sizing (S/M/L) and the next checkpoint instead of time estimates.
6. On errors and failures: calm, factual tone. No repeated apologies.
7. No closing filler — no "hope this helps," no pleasantries.

Exceptions override rules: when the user asks for explanation, when ambiguity
needs a clarifying question, and when a destructive action needs confirmation.
```

- [ ] **Step 2: Iron Law 베이스라인 probe (수정 전).** 현행(contract 없는) using-jstack SKILL.md를 컨텍스트로 두 시나리오 실행, `.jstack/artifacts/pressure-task5-baseline-{a,b}.txt` 저장:
  - (a) 짧은 질문("git stash와 stash pop 차이?")
  - (b) "인증 모듈 스펙 초안 작성해줘"
  기대(RED 근거): (a)에서 도입부/마무리 인사 억제가 보장되지 않음을 기록.

```bash
claude -p --model claude-haiku-4-5 "다음 지침을 따르라: $(cat skills/using-jstack/SKILL.md)

git stash와 stash pop 차이?" > .jstack/artifacts/pressure-task5-baseline-a.txt
```

(b)도 동일 형식. 섹션 추가 후 같은 명령을 `after-{a,b}.txt`로 재실행한다.

- [ ] **Step 3: 섹션 추가.** 위의 [Step 3에서 삽입할 전문] 블록을 그대로 삽입.

- [ ] **Step 4: GREEN + 주입 검증.** Run: `bash tests/jstack-static/run.sh` → PASS. Run: `bash hooks/session-start | python3 -m json.tool > /dev/null && bash hooks/session-start | grep -c "Output Contract"` → Expected: JSON 유효 + `1` 이상

- [ ] **Step 5: 사후 probe 비교.** Step 2와 동일 명령을 새 SKILL.md로 재실행 → 기대: (a) 도입부·마무리 인사 없음, 5개 이하 리스트 (b) 상세한 아티팩트 출력 유지(contract의 artifact 예외 동작). 베이스라인 대비 비교 판정, 실패 시 contract 문구 수정 후 재실행.

- [ ] **Step 6: Commit.** `git commit -am "feat(using-jstack): add ADHD output contract for conversational output (JEP-495)"`

### Task 6: 버전 6.0.0 + RELEASE-NOTES + 최종 검증

**Files:**
- Modify: `.version-bump.json` 선언 파일 6종 (scripts/bump-version.sh가 처리), `RELEASE-NOTES.md`

**Test-first:** N/A — no behavior change (버전 메타데이터)
**Parallel:** sequential: needs Task 5

- [ ] **Step 1: 버전 범프.** Run: `bash scripts/bump-version.sh 6.0.0 && bash scripts/bump-version.sh --audit` → Expected: 선언 파일 전부 6.0.0, audit에서 잔여 5.5.1 없음

- [ ] **Step 2: RELEASE-NOTES 추가.** 최상단에 6.0.0 항목: Output Contract 추가(출처 크레딧), 스킬 정리 3종(breaking — 명시적 호출자는 peer-review 사용), deprecated 커맨드 제거(major 약속 이행), 테스트 재배선.

- [ ] **Step 3: 전체 검증 (실패 마스킹 금지 — `&&` 체인만 사용).**

```bash
bash tests/jstack-static/run.sh \
  && bash hooks/session-start | python3 -m json.tool > /dev/null \
  && bash hooks/session-start | grep -q "Output Contract" \
  && echo INJECTION-OK
```

Expected: `[PASS]` + `INJECTION-OK`. 이어서 구버전 문자열 스캔 (bump-version --audit는 신버전 존재만 확인하므로 별도):

```bash
rg -n "5\.5\.1" package.json .claude-plugin .cursor-plugin gemini-extension.json hooks scripts skills tests
```

Expected: 출력 없음

- [ ] **Step 4: Commit.** `git commit -am "chore: release jstack 6.0.0 (JEP-495)"`

---

## 검증 요약 (스펙 게이트 매핑)

| 스펙 게이트 | 플랜 커버 |
|---|---|
| Iron Law (수정 전 실패 테스트) | 각 태스크 Step 1 RED 어서션 + Task 5 Step 4 pressure smoke |
| 테스트 갱신이 삭제와 같은 커밋 | Task 2·3 내 동시 수정 |
| session-start JSON + contract 포함 | Task 5 Step 3, Task 6 Step 3 |
| 상호 참조 0건 | Task 3 Step 4 |
| 6.0.0 범프 + RELEASE-NOTES | Task 6 |
| 하네스별 전달 확인 (스펙 W2) | 머지 후 finishing 단계에서 전 하네스 확인: **Claude Code** `bash hooks/session-start` 주입에 contract 포함(Task 5·6에서 선검증) · **Codex** `grep -q "Output Contract" ~/.codex/skills/jstack/using-jstack/SKILL.md` (심링크라 머지 즉시 반영) · **Gemini** `gemini-extension.json` 버전 6.0.0 + GEMINI.md의 스킬 로드 경로가 skills/ 유지 확인 · **OpenCode** `.opencode` 플러그인의 skills 디렉토리 참조가 삭제된 3개 스킬을 하드코딩하지 않음(`rg "requesting-code-review|receiving-code-review|dispatching-parallel-agents" .opencode/` 0건) |

## JSTACK REVIEW REPORT

| Check | Reviewer | Runs | Status | Findings | Artifact |
|---|---|---:|---|---|---|
| Spec Review | codex | 1 | Pass (issues fixed) | BLOCKING 2 + HIGH 3 반영 | .jstack/artifacts/peer-review-codex-plan-20260720T090205Z.md |
| Plan Review | codex | 1 | Issues Found → 반영됨 | BLOCKING 3 (Iron Law probe 부재, 하네스 검증 누락, shell-lint 오참조) + HIGH 3 (트리거 미실행, 스캔 범위, audit 한계) — 전부 수용·플랜 반영 | .jstack/artifacts/peer-review-codex-plan2-*.md |
| Verification | Local tests | 0 | Pending | - | - |

## Execution Handoff

Inline Execution (jstack:executing-plans) 권장 — 태스크 6개가 전부 같은 테스트 파일·프로즈 영역을 순차 수정하고, 개별 태스크가 2-10분 규모라 subagent 오버헤드가 구현 비용을 초과한다. 자율 진행 승인됨.
