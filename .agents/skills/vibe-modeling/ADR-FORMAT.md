# ADR Format

ADRs live in `docs/adr/` and are numbered sequentially: `0001-slug.md`, `0002-slug.md`, and so on.

Create `docs/adr/` only when the first ADR is needed.

## Template

```md
# {Short Decision Title}

{1–3 sentences: Context, decision, and rationale.}
```

An ADR can be written in a single paragraph. Record the decision and its rationale. No further structure is required.

## Optional Structure

Add structure only when adding valuable information. Most ADRs need no additional structure:

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`) — used when revisiting decisions
- **Considered Alternatives** — used when rejected options must be remembered
- **Consequences** — used when impacts on other parts of the system need documenting

## Numbering

Find the highest existing integer in `docs/adr/` and add 1.

## When to Propose an ADR

Do not create ADRs automatically. Propose an ADR only when all three conditions are met:

1. **Hard to change** — Significant cost to reverse the decision later.
2. **Non-obvious from code alone** — Future readers cannot deduce reasoning from code alone.
3. **Evaluated real alternatives** — Real alternatives were evaluated and one was chosen for concrete reasons.

Do not propose ADRs for easy-to-change decisions, decisions whose reasons are obvious from code, or when real alternatives were not evaluated.

### Decisions Meeting These Conditions

- **Architectural decisions.** "Use a monorepo." "Use events for write model, Postgres for read model."
- **Cross-context integration patterns.** "Ordering and Billing use domain events instead of synchronous HTTP."
- **Technology choices taking ~3 months to change.** Database, message bus, auth provider, deployment target. Do not record every library; record choices that take months to replace.
- **Boundary and scope decisions.** "Customer data belongs to Customer context; other contexts reference by ID only." State what contexts own and do not own.
- **Intentional deviations from standard expectations.** "We use raw SQL instead of an ORM because of X." Record when a reasonable reader would expect a different choice.
- **Constraints invisible in code.** "Regulatory requirements prohibit AWS." "Partner API contract requires response times under 200ms."
- **Rejected alternatives when reasons are non-obvious.** If GraphQL was evaluated and REST was chosen for specific reasons, record the reasoning so future readers understand why.
