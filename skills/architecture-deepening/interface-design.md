# Interface Design

Use this when the chosen deepening candidate could support more than one
reasonable interface.

## Frame the Problem

Write the constraints first:

- What behavior must sit behind the interface?
- What must callers be able to do?
- Which dependency category applies?
- What invariants, ordering constraints, and error modes must the interface expose?
- What should remain hidden behind the seam?

## Compare Alternatives

Generate at least two materially different designs:

- **Minimal interface**: one to three entry points, maximum leverage per entry point
- **Common-case interface**: make the most frequent caller path trivial
- **Flexible interface**: expose extension points only when real variation exists
- **Ports-and-adapters interface**: use only when cross-seam dependencies justify it

Use subagents for parallel design only when the user or host workflow explicitly
allows that. Otherwise, produce the alternatives inline.

## Evaluate

For each design, compare:

- Interface surface area
- What behavior the module hides
- How tests cross the seam
- Where leverage improves
- Where locality improves
- What trade-off the design accepts

End with a recommendation, not a menu. If a hybrid is strongest, say exactly
which pieces to combine.
