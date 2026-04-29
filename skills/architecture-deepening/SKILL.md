---
name: architecture-deepening
description: Use when planning, reviewing, or refactoring code with shallow modules, leaky interfaces, misplaced seams, adapter sprawl, duplicated orchestration, or architecture that is hard to test or change
---

# Architecture Deepening

## Overview

Deep modules hide meaningful behavior behind small interfaces. Use this skill
when architecture work needs sharper language than "clean up the design."

Core rule: deepen only when it increases leverage for callers or locality for
maintainers. Do not add seams just to make the design look more abstract.

## Required Vocabulary

Read `language.md` before making detailed suggestions. Use the terms there:
**Module**, **Interface**, **Implementation**, **Depth**, **Seam**,
**Adapter**, **Leverage**, and **Locality**.

## Process

1. **Name the candidate module cluster**
   - Which modules force callers to understand too much implementation detail?
   - Where is orchestration duplicated across call sites or tests?

2. **Run the deletion test**
   - Imagine deleting the module.
   - If complexity disappears, the module was shallow pass-through.
   - If complexity reappears across many callers, the module was earning its keep.

3. **Classify dependencies**
   - Use `deepening.md` to classify dependencies as in-process,
     local-substitutable, remote-owned, or true external.
   - The category determines whether tests should use direct calls, local
     stand-ins, ports and adapters, or mocks.

4. **Design the interface**
   - The interface includes signatures, invariants, ordering constraints,
     error modes, configuration, and performance characteristics.
   - Generate at least two materially different interface shapes before
     recommending one.
   - Use `interface-design.md` when the interface decision is high-impact.

5. **Move tests to the interface**
   - The interface is the test surface.
   - Delete old tests that only lock down shallow internals once equivalent
     behavior is covered through the deepened interface.

## Red Flags

- A seam has only one adapter and no real variation.
- Tests need private implementation details to assert behavior.
- A module's interface is nearly as complex as its implementation.
- Every caller repeats the same setup, ordering, validation, or error handling.
- A proposed abstraction only renames existing code without hiding complexity.

## Related References

- `language.md` - shared vocabulary and principles
- `deepening.md` - dependency categories and testing strategy
- `interface-design.md` - comparing alternative interface shapes
