# Deepening

How to safely deepen shallow module clusters given their dependencies. Uses [VOCABULARY.md](VOCABULARY.md) — **module**, **interface**, **boundary**, **adapter**. Use those words in user-facing text. Do not say `seam`.

## Dependency Classification

Classify dependencies when evaluating candidates. Classification decides how a deepened module is tested across the boundary.

### 1. in-process

Pure computation, in-memory state, no I/O. Always safe to deepen — merge modules and test through the new interface. No adapter needed.

### 2. local-substitutable

Dependencies with a local stand-in (PGLite instead of Postgres, in-memory filesystem). Deepen when the stand-in exists. Tests run the stand-in in the suite. The boundary stays internal; no port on the outer interface.

### 3. remote but owned (ports and adapters)

Your own services across the network (microservices, internal APIs). Define a **port** (interface) at the boundary. The deep module owns the logic; transport is an **adapter**. Tests use an in-memory adapter; production uses HTTP/gRPC/queue.

Recommendation: *"Put a port at the boundary. HTTP adapter in production, in-memory adapter in tests. Keep the logic in one deep module even when it is deployed across the network."*

### 4. true external (mock)

Third-party services you do not control (Stripe, Twilio). The deepened module takes the dependency as an injected port. Tests supply a mock adapter.

## Boundary rules

- **Do not add a boundary for one adapter.** Add a port only when two adapters are justified (usually production and test). A one-adapter boundary is just indirection.
- **Inner vs outer boundary.** A deep module may have an outer public boundary and inner boundaries used only by its own tests. Do not put an inner test boundary on the public interface just because tests use it.

## Testing: replace, do not overlay

- Delete unit tests of shallow modules once interface tests of the deepened module exist.
- Write new tests against the deepened module's interface. **The interface is where you test.**
- Tests check results visible through the interface, not internal state.
- Tests should survive internal refactors. If a test must change when the implementation changes, it is testing past the interface.
