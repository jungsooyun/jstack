---
name: simplest-thing
description: Use when writing, adding, refactoring, or fixing code, choosing libraries or dependencies, or when a solution is growing beyond what was asked - forces the simplest solution that actually works via a reuse-first ladder, a test qualification gate, and tracked debt markers
---

# Simplest Thing

The best code is the code never written. Simple means efficient, not careless:
understand the problem fully, then build the least.

## The Ladder

Stop at the first rung that holds:

1. **Does this need to exist at all?** Speculative need = skip it, say so in
   one line. (YAGNI)
2. **Already in this codebase?** A helper, util, type, or pattern that already
   lives here → reuse it. Re-implementing what's a few files over is the most
   common slop.
3. **Stdlib does it?** Use it.
4. **Native platform feature covers it?** `<input type="date">` over a picker
   lib, CSS over JS, a DB constraint over app code.
5. **Already-installed dependency solves it?** Use it. Never add a new one for
   what a few lines can do.
6. **Can it be one line?** One line.
7. **Only then:** the minimum code that works.

The ladder shortens the solution, never the reading. Trace every file the
change touches and the actual flow end to end BEFORE picking a rung. Skipping
comprehension to ship a small diff is a confident wrong fix.

**Bug fix = root cause, not symptom.** Grep every caller of the function you
are about to touch. One guard in the shared function beats a guard in the one
caller the ticket names — and it is the smaller diff.

## Rules

- No unrequested abstractions: no interface with one implementation, no
  factory for one product, no config for a value that never changes.
- No scaffolding "for later." Later can scaffold for itself.
- Deletion over addition. Boring over clever.
- Shortest working diff wins — once you understand the problem. The smallest
  change in the wrong place is a second bug.
- Two stdlib options, same size? Take the one that is correct on edge cases.
  Less code, not a flimsier algorithm.
- "Robust" and "production-ready" are not requests for more layers. They mean
  correct at the boundaries — which the ladder already forces you to find.

## debt: Markers

Mark deliberate simplifications so simple reads as intent, not ignorance. A
shortcut with a known ceiling names the ceiling and the upgrade path:

```
# debt: global lock — per-account locks if throughput matters
// debt: O(n²) scan — index it past ~10k rows
```

Grep pattern: `(#|//|--) ?debt:`. Harvest them into the backlog with
jstack:project-management (debt-harvest mode).

## Test Qualification Gate

Before writing any test, ask: **does this logic lose something when it
breaks?** Branches, loops, parsers, money paths, security boundaries,
data-loss paths → it qualifies.

- Qualifies → full TDD discipline: RED first, watch it fail, GREEN. The Iron
  Law binds unconditionally for gate-passing logic.
- Does not qualify (trivial one-liner, glue code, pure delegation) → no test.
  YAGNI applies to tests too.
- Coverage numbers are not the goal. Every gate-passing behavior tested and
  passing is the goal.
- No frameworks, fixtures, or per-function suites unless asked. The minimum
  for qualifying non-trivial logic is ONE runnable check.

"Too simple to test" as a feeling is still a rationalization — the gate
decides with objective criteria, not vibes.

## When NOT to Be Lazy

Never simplify away:

- Input validation at trust boundaries
- Authorization checks and other security measures
- Error handling that prevents data loss
- Accessibility basics
- Anything your human partner explicitly requested — if they insist on the
  full version, build it, no re-arguing.
- Calibration knobs at hardware/physical-world boundaries — real clocks
  drift, real sensors read off.

## Output

Code first. Then at most three short lines: what was skipped, when to add it.

Pattern: `[code] → skipped: [X], add when [Y].`

Every paragraph defending a simplification is complexity smuggled back in as
prose. Explanation your human partner explicitly asked for is not debt — give
it in full.
