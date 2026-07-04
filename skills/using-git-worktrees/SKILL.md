---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via Orca, native tools, or git worktree fallback
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer Orca when it manages the repo, then your platform's native worktree tools. Fall back to manual git worktrees only when neither is available.

**Core principle:** Detect existing isolation first. Then Orca. Then native tools. Then git fallback. Never fight the managing layer.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 3 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

If the worktree is Orca-managed (`orca worktree current --json` succeeds), keep its board card fresh while working: `orca worktree set --worktree active --comment "<short status>"` at meaningful checkpoints (repro, implemented, verified, blocked).

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 3.

## Step 1: Create Isolated Workspace

**Try the mechanisms below in this order.**

### 1a. Native Worktree Tools (preferred)

The user has asked for an isolated workspace (Step 0 consent).

**Orca first.** If the Orca app manages this repo — check with:

```bash
orca repo show --repo path:"$(git rev-parse --show-toplevel)" --json
```

— create the worktree through Orca so the work appears as a monitorable card on the Orca board:

```bash
orca worktree create --name <task-name> --no-parent [--linear-issue JEP-123] --json
cd <path from output>
```

Rules:
- Independent work: `--no-parent`, omit `--base-branch` (repo default base). Stacked work only: `--parent-worktree active`.
- Link the Linear issue at create time when known (`--linear-issue <ID|url>`) — finishing skills read it back via `orca worktree show`.
- If the repo's setup hook is heavy and the task doesn't need it, pass `--setup skip` (check repo CLAUDE.md for per-repo worktree setup notes).
- Handing the work to another agent instead of doing it yourself: add `--agent <claude|codex> --prompt "<task brief>"` and stop after creation.
- While working, update the card at meaningful checkpoints: `orca worktree set --worktree active --comment "<short status>" --workspace-status <todo|in-progress|in-review|completed>`.
- Cleanup at finish time is `orca worktree rm` (jstack:finishing-a-development-branch handles it) — never manual `git worktree remove`.

Then skip to Step 3.

**Other native tools.** No Orca? Do you have a harness worktree tool — a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag? Use it and skip to Step 3.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool — or a harness tool when Orca manages the repo — creates phantom state the managing layer can't see.

Only proceed to Step 1b if none of the above applies.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection

Follow this priority order. Explicit user preference always beats observed filesystem state.

1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.

2. **Check for an existing project-local worktree directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If found, use it. If both exist, `.worktrees` wins.

3. **Check for an existing global directory** (jstack first, superpowers fallback for backward compat):
   ```bash
   project=$(basename "$(git rev-parse --show-toplevel)")
   ls -d ~/.config/jstack/worktrees/$project 2>/dev/null \
     || ls -d ~/.config/superpowers/worktrees/$project 2>/dev/null
   ```
   If found, use it.

4. **If there is no other guidance available**, default to `.worktrees/` at the project root.

#### Safety Verification (project-local directories only)

**MUST verify directory is ignored before creating worktree:**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:** Add to .gitignore, commit the change, then proceed.

**Why critical:** Prevents accidentally committing worktree contents to repository.

Global directories (`~/.config/jstack/worktrees/`, `~/.config/superpowers/worktrees/`) need no verification.

#### Create the Worktree

```bash
project=$(basename "$(git rev-parse --show-toplevel)")

# Determine path based on chosen location
# For project-local: path="$LOCATION/$BRANCH_NAME"
# For global (jstack): path="~/.config/jstack/worktrees/$project/$BRANCH_NAME"
# For global (legacy superpowers, backward compat only): path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.

## Step 3: Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 4: Verify Clean Baseline

Run tests to ensure workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Orca manages this repo | `orca worktree create` (Step 1a) |
| Native worktree tool available | Use it (Step 1a) |
| No Orca, no native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Global path exists | Use it (jstack first, superpowers legacy) |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Mistakes

### Fighting the harness

- **Problem:** Using `git worktree add` when the platform already provides isolation
- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools.

### Skipping detection

- **Problem:** Creating a nested worktree inside an existing one
- **Fix:** Always run Step 0 before creating anything

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** Follow priority: existing > global legacy > instruction file > default

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

## Red Flags

**Never:**
- Create a worktree when Step 0 detects existing isolation
- Use `git worktree add` or a harness tool (e.g., `EnterWorktree`) in an Orca-managed repo — Orca can't see that checkout; use `orca worktree create`
- Use `git worktree add` when you have a native worktree tool (e.g., `EnterWorktree`). This is the #1 mistake — if you have it, use it.
- Skip Step 1a by jumping straight to Step 1b's git commands
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking

**Always:**
- Run Step 0 detection first
- Prefer native tools over git fallback
- Follow directory priority: existing > global legacy > instruction file > default
- Verify directory is ignored for project-local
- Auto-detect and run project setup
- Verify clean test baseline

## Integration

**Called by:**
- **jstack:brainstorming** (Phase 4) - When design is approved and implementation follows
- **jstack:subagent-driven-development** - Before executing any tasks
- **jstack:executing-plans** - Before executing any tasks
- Any skill needing isolated workspace

**Pairs with:**
- **jstack:finishing-a-development-branch** - Provenance-based cleanup after work complete
