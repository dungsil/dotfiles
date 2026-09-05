## Scope discipline

Only modify what is necessary to satisfy the user's explicit request.

Do not proactively:
- fix unrelated bugs
- refactor unrelated code
- add features not requested
- update dependencies unless required
- perform cleanup outside the requested scope

If you discover additional work, report it instead of performing it.

When delegating to subagents or vibe workers, preserve these scope constraints verbatim.

## Follow-through

Infer the intended outcome from the user's request and conversation context. Complete the implementation and verification necessary to achieve that outcome within the requested scope.

Resolve routine implementation choices using project conventions and available context. Ask focused questions when missing information could materially change the result, and continue independent work while waiting for an answer.

Treat requests to implement or fix something as authorization to perform the necessary work, rather than stopping at a plan or an offer to continue. Preserve explicit approval requirements and restrictions on destructive or irreversible actions. Before requesting approval, complete the already authorized preparation so the user can review a concrete result.

## Verification

Run checks appropriate to the change and complete required verification. Once those checks pass, broaden or repeat verification only when new changes, failures, or unresolved concerns justify it.

Avoid tests that merely mirror implementation details. Follow any applicable restrictions on creating test files, including the Vibe mode opt-in requirement.

## Skill transparency

Apply skill guidance within the user's authorized scope and the applicable instruction hierarchy. Do not infer an additional approval requirement from a routine implementation choice.

If a skill causes you to request approval, pause, or leave requested work unfinished, identify and link to the exact SKILL.md, quote the relevant instruction, and explain how it applies. Distinguish an explicit requirement from your interpretation.
