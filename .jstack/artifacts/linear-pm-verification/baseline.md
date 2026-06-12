# Linear PM Integration — Baseline (RED) Evidence

**Date:** 2026-06-13
**Phase:** RED — scenarios run in fresh `claude -p` sessions BEFORE the
`jstack:project-management` skill exists, per `jstack:writing-skills`.

## Methodology

Each scenario was run as a fresh, non-interactive session:

```
command claude -p --model claude-sonnet-4-6 "<prompt>"
```

These sessions load the user's global CLAUDE.md and the existing `jstack:*`
skills, but **not** the not-yet-created `project-management` skill — this is
exactly the baseline condition. Output below is pasted verbatim from the real
session transcripts (nothing fabricated).

**Workspace baseline (Jephalabs team, before any test issues):**
- Projects: none (`list_projects` → `[]`)
- Issues: only the 4 default Linear onboarding issues JEP-1..JEP-4, all in `Todo`.

---

## Scenario 1 — Capture an idea mid-conversation

**Prompt:** `아까 생각났는데, 나중에 spec 검색 캐시도 만들면 좋겠어. 일단 기억해놔줘.`

**Agent output (verbatim):**

```
기억해뒀어. 나중에 spec 검색 캐시 구현할 때 꺼내쓸게.
```

**Observed failure mode:** The agent acknowledges the idea conversationally
("I remembered it") but creates **nothing durable** — no Linear Backlog issue,
no file, no record that survives the session. The idea evaporates when the
session ends. This is the exact problem the spec calls out: "later ideas raised
during brainstorming evaporate."

---

## Scenario 2 — What should I work on next?

**Prompt (first attempt):** `다음에 뭘 작업하면 좋을까?`

This phrase matched the **deprecated** `jstack:brainstorm` skill stub and the
session bailed out with a deprecation notice instead of recommending work:

```
`jstack:brainstorm` 스킬은 **deprecated** 되었으며 다음 메이저 릴리즈에서 제거될
예정입니다. 대신 `jstack:brainstorming` 스킬을 사용해 주세요.
다시 질문해 주시면 올바른 스킬로 진행하겠습니다.
```

To get a clean baseline of the actual next-work behavior, the prompt was
rephrased to avoid the deprecated-skill trigger.

**Prompt (clean run):** `이 레포에서 다음에 뭘 작업하면 좋을지 추천해줘. 우선순위 높은 것부터.`

**Agent output (verbatim, excerpt):**

```
이제 현재 상태를 파악했어요. 추천 순위를 정리하면:

## 다음 작업 추천 (우선순위 순)

### 1순위: Linear PM 통합 구현 시작 (Task 1 → Task 2)
현재 브랜치(`feature/linear-pm-integration`)에 완전히 리뷰된 구현 플랜이 있고,
**아직 하나도 구현되지 않았어요.** ...

### 3순위: 기존 스킬 개선 (`docs/plans/2025-11-28-skills-improvements-from-user-feedback.md`)
플랜 파일이 남아있는데 ...

### 4순위: 플랜 리뷰 리포트 "Adversarial Review" 항목 완료
JSTACK REVIEW REPORT에서 Adversarial Review, Verification, Live Evidence가
모두 Pending이에요. ...
```

**Observed failure mode:** The agent guesses priorities entirely from
**repo filesystem artifacts** — the current branch name, plan files under
`docs/`, and the JSTACK review report's Pending rows. It never consults a
backlog or any priority data. There is no source-of-truth list of work items
with real priorities; "priority order" is invented from whatever happens to be
lying around in the repo. A fresh session in a clean repo would have nothing to
recommend. This is the "no priorities / no backlog" gap from the spec.

---

## Scenario 3 — Finish a trivial branch

**Setup:** isolated throwaway git repo with one trivial docs commit:

```
git init -b main; commit "init"
git checkout -b fix-typo; edit README; commit "docs: fix README typo"
```

**Prompt:** `이 브랜치(fix-typo) 작업 다 끝났어. 마무리해줘. main에 머지하면 돼.`

**Agent output (verbatim):**

```
테스트 파일이 없는 문서 전용 브랜치입니다 (README 타이포 수정). 테스트 스위트 없음으로
검증을 통과합니다.

구현 완료. 어떻게 하시겠습니까?

1. **main에 로컬 머지** (요청하신 방식)
2. Push 후 Pull Request 생성
3. 브랜치 유지 (나중에 직접 처리)
4. 작업 폐기

어떤 옵션으로 진행할까요?
```

**Observed failure mode:** The `finishing-a-development-branch` skill runs
correctly for the git workflow (verify tests → present 4 options) but performs
**no issue-status transition of any kind**. There is no step to locate a linked
issue, no Done/In Progress transition, no comment with the merge commit.
`docs/jstack/specs/` would accumulate finished work with no done/in-progress
signal anywhere — the "no status visibility" gap from the spec.

---

## Summary

| Scenario | Expected RED failure | Confirmed? |
|---|---|---|
| 1. Capture | Idea acknowledged in conversation only; nothing durable created | Yes |
| 2. Next | Agent guesses from repo/git artifacts; no priority/backlog data consulted | Yes |
| 3. Finish | No issue status transition anywhere | Yes |

All three baseline failure modes reproduced with real session output. These are
the before-evidence for Tasks 3–5; GREEN verification follows in Task 6.
