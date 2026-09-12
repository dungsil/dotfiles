# Test-Driven Development

TDD is a red → green loop. This reference helps ensure that loop produces tests worth maintaining: what makes a good test, where tests belong, anti-patterns, and loop rules. Every section applies to every cycle. Consult before and during the loop, not afterward.

When exploring the codebase, read `CONTEXT.md` (if present) so test names and interface vocabularies align with the project's domain language, and respect ADRs for the area under modification.

## What is a Good Test

Tests verify behavior through public interfaces, not implementation details. Code may change completely while tests remain untouched. Good tests read like specifications. "user can checkout with valid cart" tells you exactly what feature exists and endures refactoring because it ignores internal structure.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Where Tests Belong

A **boundary** is the public interface at which you test — you observe behavior without going inside. Tests live at boundaries, not internals.

**Test only at pre-agreed boundaries.** Before writing any tests, write down where you will test and confirm with the user. Do not write tests at unconfirmed boundaries. Not everything can be tested. Agreeing on boundaries in advance keeps testing on critical paths and complex logic rather than every edge case.

Ask: "What is the public interface, and where should we test?"

## Anti-Patterns

- **Coupled to implementation** — Mocking internal collaborators, testing private methods, or verifying via side channels (querying databases instead of interfaces). Symptom: refactoring breaks tests even though behavior did not change.
- **Tautology** — Assertions recomputing expected values the same way the code does (`expect(add(a, b)).toBe(a + b)`, manual snapshots generated the same way, asserting constants equal themselves). These pass structurally and can never disagree with code. Expected values must come from independent sources of truth: known correct literals, real examples, specifications.
- **Horizontal slicing** — Writing all tests first, then all implementations. Bulk tests verify imagined behavior. They test surface appearances rather than user-visible behavior, become insensitive to actual changes, and freeze test structures before understanding implementations. Work in **vertical slices** instead: one test → one implementation → repeat. Each test is a **sighting shot** reacting to lessons from the prior cycle.

## Loop Rules

- **Red before green.** Write a failing test first, then write only enough code to pass it. Do not anticipate future tests or add speculative features.
- **One slice at a time.** One boundary, one test, one minimal implementation per cycle.
- **Refactoring is not part of this loop.** Refactoring belongs in the review phase (see `/vibe-review`), not the red → green implementation loop.
