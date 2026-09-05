# Subagent delegation

Use subagents when independent research, design review, implementation, or verification can run in parallel and improve completion time or quality.
Handle small tasks and work with strong sequential dependencies directly.

When delegating, define the task scope, expected output, user constraints, and relevant context.
For tasks that modify files, assign ownership of specific files or modules to avoid overlapping edits.
Subagents must preserve other contributors' changes and adapt their work to accommodate them.
The primary agent must integrate and verify the results before completing the task.

## Researcher: research and evidence gathering

Use the researcher agent with gpt-5.6-luna at medium reasoning effort for focused documentation research, codebase exploration, and fact checking.

When the researcher role is unavailable but explicit model and reasoning effort selection is supported, use a general subagent with the same settings and research instructions.

## Planner: complex planning and design review

Use the planner agent with gpt-6-astra at xhigh reasoning effort for problems requiring deeper analysis, such as cross-module structural changes, migrations, unclear design tradeoffs, or problems unresolved after repeated attempts.
Do not invoke it for routine planning.

Provide the user's goals and constraints, relevant code locations, established findings, and the specific questions requiring judgment.

## Coordination and execution conditions

Delegate fact finding and evidence gathering to the researcher, and complex analysis of alternatives based on that evidence to the planner.
Do not automatically invoke both roles in sequence for every task.
Respect dependencies when design review requires research findings first.

While a subagent works, the primary agent should proceed with useful, independent work without duplicating the delegated task.
If no useful independent work is available, handle the task directly.

Delegate only when permitted by the active runtime and user instructions.
When the planner role is unavailable but explicit model and reasoning effort selection is supported, use a general subagent with the same settings and planner instructions.
If the requested settings are unavailable, the primary agent should handle the task directly.
