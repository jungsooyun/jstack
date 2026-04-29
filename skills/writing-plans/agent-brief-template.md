# Agent Brief Template

Use this for long-lived backlog or issue-tracker work that may sit for days or
weeks before an AFK agent picks it up. This is not a replacement for a JStack
implementation plan. It is a durable behavioral contract.

Do not use stale-prone file paths or line numbers. Prefer interfaces, types,
config shapes, behavior, acceptance criteria, and explicit scope boundaries.

```md
## Agent Brief

**Category:** bug / enhancement
**Summary:** One-line description of what needs to change

**Current behavior:**
Describe what happens now. For bugs, name the broken behavior. For
enhancements, name the status quo the feature builds on.

**Desired behavior:**
Describe what should happen after the agent's work is complete. Include edge
cases and error conditions that affect correctness.

**Key interfaces:**
- `TypeName` - what needs to change and why
- `functionName()` return type - current contract vs desired contract
- Config shape - any new option or invariant

**Acceptance criteria:**
- [ ] Specific, independently testable criterion
- [ ] Specific, independently testable criterion
- [ ] Specific, independently testable criterion

**Out of scope:**
- Adjacent behavior that should not change
- Related feature that belongs in a separate issue
```
