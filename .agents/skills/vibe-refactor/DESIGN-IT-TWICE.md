# Design It Twice

Use this parallel sub-agent pattern when exploring other interfaces for a chosen deepening candidate. Based on "Design It Twice" (Ousterhout) — the first idea is rarely the best.

Use [VOCABULARY.md](VOCABULARY.md) — **모듈**, **인터페이스**, **경계**, **어댑터**. Compare in easy Korean.

## Process

### 1. Define the problem space

Before spawning sub-agents, explain the problem space to the user:

- Constraints the new interface must meet
- Dependencies and their classification (see [DEEPENING.md](DEEPENING.md))
- Rough code sketches that make the constraints concrete — not proposals

Show this to the user and go straight to step 2. The user reads while the sub-agents work.

### 2. Spawn sub-agents

Spawn 3 or more sub-agents in parallel. Each must produce a **very different** interface for the deepened module.

Give each a separate technical brief (file paths, coupling, [DEEPENING.md](DEEPENING.md) classification, what sits behind the boundary). The brief is independent of the user-facing write-up in step 1. Give each agent a different constraint:

- Agent 1: "Minimize the interface — at most 1–3 entry points. Make each entry point do more for callers."
- Agent 2: "Maximize flexibility — support many uses and extensions."
- Agent 3: "Optimize for the most common callers — make the default case obvious."
- Agent 4 (when relevant): "Design ports and adapters for dependencies across the boundary."

Include [VOCABULARY.md](VOCABULARY.md) and `CONTEXT.md` terms in the briefs.

Each sub-agent returns:

1. Interface (types, methods, parameters — plus invariants, order, errors)
2. A usage example
3. What the implementation hides behind the boundary
4. Dependency strategy and adapters (see [DEEPENING.md](DEEPENING.md))
5. Trade-offs — where one interface covers many callers, where it stays thin

### 3. Present and compare

Show each design one at a time, then compare in easy Korean prose. Contrast how deep it is, whether fixes stay in one place, and where the boundary sits. Do not label the comparison with `depth`, `locality`, or `seam`.

Then recommend in Korean: which design is stronger, and why. Propose a hybrid if pieces fit. Speak with conviction.
