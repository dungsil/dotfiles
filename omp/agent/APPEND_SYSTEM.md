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
