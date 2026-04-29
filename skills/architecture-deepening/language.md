# Architecture Language

Use these terms consistently.

**Module**
Anything with an interface and an implementation. This can be a function, class,
package, service, or vertical slice.

**Interface**
Everything a caller must know to use the module correctly: signatures,
invariants, ordering constraints, error modes, configuration, and performance.

**Implementation**
The code behind the interface.

**Depth**
How much useful behavior sits behind the interface. A deep module gives callers
more capability per concept they must learn.

**Seam**
A place where behavior can vary without editing the caller. The seam is where
the interface lives.

**Adapter**
A concrete implementation that satisfies an interface at a seam.

**Leverage**
What callers get from depth: more capability per unit of interface.

**Locality**
What maintainers get from depth: bugs, changes, and verification concentrate in
one place instead of spreading through callers.

## Principles

- Depth is a property of the interface, not the number of implementation lines.
- The interface is the test surface.
- One adapter usually means a hypothetical seam; two adapters can justify a real seam.
- The deletion test: if deleting a module removes complexity, it was not hiding
  much. If deleting it spreads complexity across callers, it had value.
