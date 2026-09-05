# Subagent delegation

Use subagents when independent research, implementation, or review tasks can run in parallel and improve completion time or quality. Handle small tasks and work with sequential dependencies directly.

When delegating, define the task scope, expected output, and file ownership. Preserve the user's constraints, avoid overlapping edits, and integrate and verify the results before completing the task.

Use the researcher agent with gpt-5.6-luna at medium reasoning effort for focused documentation research, evidence gathering, and codebase exploration. Keep interpretation of conflicting evidence and final decisions with the primary agent. When the researcher role is unavailable but explicit model selection is supported, use the same model and effort with equivalent research instructions.

Delegate only when permitted by the active runtime and user instructions.
