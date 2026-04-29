# ADR Format

Use an Architecture Decision Record only when the decision is worth preserving
outside the current spec.

## When to Offer an ADR

All three must be true:

1. The decision is hard to reverse.
2. The result would surprise a future maintainer without context.
3. There was a real trade-off between plausible alternatives.

Skip ADRs for obvious, reversible, or purely local choices.

## Location

ADRs live under `docs/adr/` and use sequential names:

```text
docs/adr/0001-short-slug.md
docs/adr/0002-short-slug.md
```

Create `docs/adr/` lazily when the first ADR is needed. Scan existing ADRs for
the highest number and increment it.

## Template

```md
# {Short Decision Title}

{1-3 sentences: the context, the decision, and why it was chosen.}
```

Optional sections are allowed only when they add value:

- **Status**: proposed, accepted, deprecated, or superseded by ADR-NNNN
- **Considered Options**: rejected alternatives worth remembering
- **Consequences**: downstream effects that are not obvious from the code
