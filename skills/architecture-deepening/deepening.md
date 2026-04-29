# Deepening Modules

Classify dependencies before proposing a deeper module. The dependency category
determines where the seam belongs and how tests cross it.

## Dependency Categories

### In-Process

Pure computation or in-memory state. Deepen directly and test through the new
interface.

### Local-Substitutable

Dependencies with local test stand-ins, such as an in-memory filesystem or
local database. Keep the seam internal and test the deepened module with the
stand-in.

### Remote-Owned

Services you own across a process or network boundary. Put a port at the seam,
keep orchestration in the deep module, and provide production and test adapters.

### True External

Third-party systems you do not control. Inject a port and use a mock or fake
adapter in tests.

## Seam Discipline

- Do not create a port unless at least two adapters are justified.
- Keep internal seams private to the implementation.
- Do not expose a test-only seam as part of the public interface.

## Testing Strategy

- Test observable behavior through the deepened interface.
- Avoid assertions on internal state or call order unless those are part of the interface.
- Replace shallow internal tests once the same behavior is covered at the new interface.
