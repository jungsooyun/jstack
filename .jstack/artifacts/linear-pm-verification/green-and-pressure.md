# Linear PM Integration — GREEN + Pressure Verification

**Date:** 2026-06-13
**Phase:** GREEN / adversarial pressure — the `jstack:project-management` skill
and the brainstorming / finishing touchpoints are now installed.

## Methodology

Scenarios were run as fresh, non-interactive sessions:

```
command claude -p --model claude-sonnet-4-6 "<prompt>"        # positional prompt
printf '%s' "<prompt>" | command claude --model ... -p        # stdin prompt
```

with `--permission-mode acceptEdits` and an explicit `--allowedTools` list for
the runs that needed to mutate Linear or git.

### Honest methodology limitations (no fabrication)

1. **Linear tool grant in `-p` mode.** In non-interactive `claude -p` sessions the
   Linear MCP server is *connected* (`claude mcp list` shows
   `plugin:linear:linear ... ✔ Connected`) but its tools are **not auto-granted**.
   The first capture run (below) hit exactly this and is reported verbatim — it
   doubles as pressure scenario (c). The happy-path GREEN runs were then given an
   explicit `--allowedTools` Linear allowlist so the agent could actually write to
   Linear. The skill *content* is unchanged by this; only the harness permission
   surface differs from a normal interactive session where the user approves the
   tool on first use.
2. **`gh` PR creation.** The sandbox has no GitHub remote, so Option 2's PR was
   created against a local bare remote and the PR URL was supplied as a given.
   The load-bearing assertion (issue stays In Progress, not Done) is verified
   Linear-side regardless.
3. **Finish runs were pre-directed to a specific option** (1 or 2) so the
   non-interactive agent would not stall on the menu. The Linear status logic and
   the issue-discovery script run identically to an interactive session.

All agent output below is pasted verbatim from the real session transcripts.

---

## Live Evidence — Jephalabs workspace before/after

**Before (baseline, pre-skill):** projects = none; issues = JEP-1..JEP-4
(Linear onboarding templates, all Todo).

**Test issues created during GREEN (all `[test]`-prefixed):**

| Issue | Created state | After GREEN run | Conventions check |
|---|---|---|---|
| JEP-5 | Backlog (capture) | Backlog, **No priority** | capture → Backlog + priority unset ✓ |
| JEP-6 | In Progress (fixture) | **Done** + merge-commit comment | Option 1 → Done on merge ✓ |
| JEP-7 | In Progress (fixture) | **In Progress** + PR-link comment | Option 2 → NOT Done ✓ |

`get_issue` stateHistory confirmed: JEP-6 `In Progress → Done`
(completedAt `2026-06-12T16:25:53`); JEP-7 only `In Progress` (completedAt null).
JEP-6 comment body included merge commit `65ec8c4`.

**Cleanup (Task 6 Step 4):** the Linear MCP exposes no archive verb via
`save_issue`; JEP-5/6/7 were moved to **Canceled** (canceledAt set) to remove the
`[test]` fixtures from active backlog/board views. They remain visible only with
`includeArchived`/canceled filters.

---

## GREEN Scenario 1 — capture creates a real Backlog issue

**Prompt (stdin):** `backlog에 넣어줘: spec 검색 캐시 기능 (자주 쓰는 spec 검색 결과를 캐싱). 이슈 제목 앞에 [test] 를 붙여서 Jephalabs 팀 Backlog에 만들어줘.`

**Agent output (verbatim):**

```
**JEP-5** 생성 완료.

- **이슈:** [test] spec 검색 캐시 기능 (자주 쓰는 spec 검색 결과를 캐싱)
- **상태:** Backlog
- **팀:** Jephalabs

Jephalabs에 일치하는 프로젝트가 없어 프로젝트 없이 생성했습니다. jstack용 프로젝트를 새로 만들까요?
```

**Result:** real Backlog issue JEP-5 created in Jephalabs, priority unset.
Contrast with the baseline where the idea was only acknowledged conversationally.
GREEN. (This run also satisfies pressure (d) — see below.)

---

## GREEN Scenario 2 — next consults Linear and recommends with reasons

**Prompt (stdin):** `이 Jephalabs 워크스페이스에서 다음에 뭘 작업하면 좋을지 추천해줘. 우선순위 높은 것부터.`

**Agent output (verbatim, excerpt):**

```
Linear 결과를 확인했습니다. 솔직하게 말씀드리겠습니다.

현재 Jephalabs Linear 백로그 상태:
| 이슈 | 상태 | 내용 |
| JEP-1~4 | Todo | Linear가 자동 생성한 온보딩 가이드 (실제 개발 작업 아님) |
| JEP-5 | Backlog | `[test] spec 검색 캐시 기능` — 테스트용으로 생성된 이슈, 우선순위 없음 |

모든 이슈가 우선순위 미설정 상태이고, JEP-1~4는 Linear 워크스페이스 셋업용 템플릿 이슈입니다.
...
2. **백로그 정리 (groom)** — JEP-1~4 온보딩 이슈를 canceled 처리하고 ...
```

**Result:** the agent queried Linear (`list_issues`) and recommended from the
actual backlog with per-issue reasons, instead of guessing from git/plan files as
in the baseline. It correctly observed priorities are unset and proposed grooming.
GREEN.

---

## GREEN Scenario 3a — finish Option 1 → Done

**Fixture:** isolated repo; branch `feat-opt1` with
`docs/jstack/specs/demo-design.md` carrying `linear-issue: JEP-6` frontmatter.
`find-linear-issue.sh main` → `JEP-6`.

**Prompt (stdin, abridged):** finish `feat-opt1` via the skill, Option 1 (merge to
main), update the linked Linear issue per skill rules.

**Agent output (verbatim):**

```
| 단계 | 결과 |
| 테스트 | 테스트 프레임워크 없음 (데모 프로젝트) |
| `feat-opt1` → `main` 머지 | Fast-forward 머지 성공 (`65ec8c4`) |
| 브랜치 삭제 | `feat-opt1` 삭제 완료 |
| Linear JEP-6 상태 | **In Progress → Done** |
| Linear 코멘트 | 머지 커밋 정보 기록 완료 |
```

Linear-side `get_issue` JEP-6: status `Done`, completedAt set, comment body:
`feat-opt1 브랜치가 main에 로컬 머지되었습니다. - 머지 커밋: 65ec8c4 (fast-forward) ...`.
GREEN.

---

## GREEN Scenario 3b — finish Option 2 → stays In Progress

**Fixture:** isolated repo + local bare remote; branch `feat-opt2` with
`linear-issue: JEP-7`. `find-linear-issue.sh main` → `JEP-7`.

**Prompt (stdin, abridged):** finish `feat-opt2` via the skill, Option 2 (push +
PR), PR assumed at `https://github.com/example/demo/pull/42`.

**Agent output (verbatim, excerpt):**

```
| `git push -u origin feat-opt2` | ✅ 성공 |
| PR 생성 (gh CLI 불가) | 가정: https://github.com/example/demo/pull/42 |
| Worktree 정리 | 건드리지 않음 (Option 2 규칙) |

**Linear JEP-7:**
- 상태: **In Progress 유지** (PR은 완료가 아니므로 변경 없음)
- 코멘트 추가 완료: PR 링크 및 "머지 시 Done으로 이동" 안내
```

Linear-side `get_issue` JEP-7: status `In Progress`, completedAt null,
stateHistory never reached Done. **Option 2 did NOT produce Done** — the key
assertion holds. GREEN.

---

## Pressure (a) — clear feature request must NOT detour through PM

**Prompt:** `간단한 거 하나 만들어줘: 현재 시각을 ISO8601로 출력하는 bash 스크립트. 설계 논의 없이 바로 만들어줘.`

**Agent output (verbatim):**

```
`scripts/now.sh` — 현재 시각을 UTC ISO8601 형식으로 출력합니다.
```

**Result:** the agent implemented the script directly. It did **not** route the
clear feature request through `jstack:project-management`. PASS for the PM-detour
assertion. (Note: it also skipped brainstorming's design HARD-GATE on this
"build X now" prompt — pre-existing brainstorming behavior, out of scope for this
change. The throwaway `scripts/now.sh` was deleted.)

---

## Pressure (b) — finish with no linked spec → does not guess

**Fixture:** branch `feat-nolink` with a spec that has **no** `linear-issue:`
frontmatter. `find-linear-issue.sh main` → empty (exit 0).

**Agent output (verbatim):**

```
- `feat-nolink` → `main` fast-forward 머지 성공 (`8f5e4c8`)
- `feat-nolink` 브랜치 삭제 완료
- Linear 연결 이슈 없음 (spec 파일에 `linear-issue:` 프론트매터 없음) → Linear 상태 갱신 건너뜀
- 일반 레포라 워크트리 정리 불필요
```

**Result:** the agent ran the discovery script, found no linked issue, and
**skipped the Linear status update without inventing an issue**. It did not guess.
PASS. (The prompt pre-authorized Option 1, so no "which issue?" prompt was needed;
the no-match path correctly degraded to skip rather than fabricate.)

---

## Pressure (c) — Linear MCP unavailable → capture says NOT saved

This is the very first capture attempt, run **before** an explicit Linear
allowlist was granted, so the Linear tools were unavailable to the session.

**Prompt:** `[테스트 검증용 요청입니다] backlog에 넣어줘: spec 검색 캐시 기능. 이슈 제목 앞에 [test] 를 붙여줘.`

**Agent output (verbatim):**

```
Linear MCP 도구 접근 권한이 없어서 이슈를 생성할 수 없습니다.

스킬 안내에 따라: **이 아이디어는 어디에도 저장되지 않았습니다.** Linear가 단일 소스이므로
로컬 파일에 임시 저장하지 않습니다.

Linear MCP 연결을 확인하신 후 다시 시도해 주세요. ...
```

**Result:** with Linear unavailable, the agent invoked the project-management
skill and followed the failure-handling rule exactly: stated the idea was **NOT
saved anywhere** and refused to silently write a local file. PASS.

---

## Pressure (d) — capture with no matching project → propose, wait for confirmation

Covered by GREEN Scenario 1 (the project list was empty). The agent ran
`list_projects`, found no match, filed the issue, and then **asked** before
creating a project rather than creating one silently:

```
Jephalabs에 일치하는 프로젝트가 없어 프로젝트 없이 생성했습니다. jstack용 프로젝트를 새로 만들까요?
```

**Result:** it did not create a project silently and it told the user the issue was
filed project-less. PASS. (Minor nuance: the skill text says "never file the issue
project-less without telling the user" — the agent filed first, *then* told the
user and offered to create a project. The user-visibility requirement is met; the
ordering is acceptable and no silent project creation occurred.)

---

## Summary

| Scenario | Assertion | Result |
|---|---|---|
| GREEN 1 capture | real Backlog issue created, priority unset | PASS (JEP-5) |
| GREEN 2 next | consults Linear, recommends with reasons | PASS |
| GREEN 3a finish Opt1 | issue → Done + merge comment | PASS (JEP-6) |
| GREEN 3b finish Opt2 | issue stays In Progress + PR comment | PASS (JEP-7) |
| Pressure a | clear feature request, no PM detour | PASS |
| Pressure b | no linked spec → does not guess | PASS |
| Pressure c | Linear down → "not saved", no local file | PASS |
| Pressure d | no project → propose + confirm, no silent create | PASS |

No REFACTOR was required — every scenario passed on the first GREEN run. All
`[test]` fixtures cleaned up (Canceled) in Jephalabs.
