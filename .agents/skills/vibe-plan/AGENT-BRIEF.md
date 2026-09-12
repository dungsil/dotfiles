# Writing an Agent Brief

An agent brief is a structured comment posted to a GitHub issue or PR when moved to `ready-for-agent`. It is the authoritative specification against which an AFK agent works. The original body and discussion provide context — the agent brief is the contract.

The brief describes **what the agent must do**, applying to both surfaces: building changes from scratch for issues, or finishing remaining work *on* existing diffs for PRs — closing gaps and addressing review feedback. Principles remain identical; PR examples below illustrate the differences.

## Table of Contents

- Principles — Durability, Behavior Over Mechanics, Complete Acceptance Criteria, Explicit Scope
- Template — Brief structure posted as comments
- Examples — Good briefs for bugs, enhancements, PRs; and bad briefs

## Principles

### Durability Over Precision

Issues may sit in `ready-for-agent` for days or weeks while codebases evolve. Write briefs so they remain useful even if files are renamed, moved, or refactored.

- Describe interfaces, types, and behavioral contracts
- Name concrete types, function signatures, and config shapes the agent must find or modify
- Do not reference file paths — they become stale
- Do not reference line numbers
- Do not assume current implementation structures remain unchanged

### Behavior Over Mechanics

Describe **what** the system must do, not **how** to implement it. Agents explore fresh codebases and make implementation decisions independently.

- **Good:** "`SkillConfig` type must accept an optional `schedule` field of type `CronExpression`"
- **Bad:** "Open src/types/skill.ts and add the schedule field on line 42"
- **Good:** "When users run `triage list` with no arguments, a summary of issues needing attention should appear"
- **Bad:** "Add a switch statement to the main handler function"

### Complete Acceptance Criteria

Agents must know when work is done. Every agent brief requires concrete, testable acceptance criteria, independently verifiable.

- **Good:** "Running `gh issue list --label needs-triage` returns issues that passed initial classification"
- **Bad:** "Triage should work properly"

### Explicit Scope Boundaries

Describe what is out of scope. This prevents agents from over-decorating or making assumptions about adjacent features.

## Template

```markdown
## Agent Brief

**Category:** bug / enhancement
**Summary:** One-line description of what should happen

**Current Behavior:**
What happens now. For bugs, the broken behavior.
For enhancements, the current state on which the feature builds.

**Desired Behavior:**
What should happen after the agent's work completes.
Be specific about edge cases and error conditions.

**Key Interfaces:**
- `TypeName` — What needs to change and why
- `functionName()` return type — What it currently returns vs what it should return
- Config shapes — New configuration options needed

**Acceptance Criteria:**
- [ ] Concrete, testable condition 1
- [ ] Concrete, testable condition 2
- [ ] Concrete, testable condition 3

**Out of Scope:**
- What should not be changed or addressed in this issue
- Related-looking but distinct adjacent capabilities
```

## Examples

### Good Agent Brief (Bug)

```markdown
## Agent Brief

**Category:** bug
**Summary:** Skill description truncation cuts off mid-word, producing broken output

**Current Behavior:**
When skill descriptions exceed 1024 characters, they are truncated at exactly
1024 characters regardless of word boundaries, leaving descriptions ending
mid-word (e.g. "when user wants to confi").

**Desired Behavior:**
Truncation should break at the last word boundary before 1024 characters
and append "..." to indicate truncation.

**Key Interfaces:**
- `description` field on `SkillMetadata` type — no type change required,
  but validation/processing logic populating it must respect word boundaries
- Functions reading SKILL.md frontmatter and extracting descriptions

**Acceptance Criteria:**
- [ ] Descriptions under 1024 characters remain unchanged
- [ ] Descriptions over 1024 characters are truncated at the last word boundary before 1024 characters
- [ ] Truncated descriptions end with "..."
- [ ] Total length including "..." does not exceed 1024 characters

**Out of Scope:**
- Changing the 1024-character limit itself
- Supporting multi-line descriptions
```

### Good Agent Brief (Enhancement)

```markdown
## Agent Brief

**Category:** enhancement
**Summary:** Add `docs/agents/out-of-scope/` directory support for tracking rejected feature requests

**Current Behavior:**
When feature requests are rejected, issues are closed with `wontfix` labels
and comments, leaving no durable record of decisions or rationale. Future
similar requests require maintainers to recall or search previous discussions.

**Desired Behavior:**
Rejected feature requests should be documented in `docs/agents/out-of-scope/<concept>.md`
files containing decision, rationale, and links to all issues requesting the feature.
When triaging new issues, check these files for matches.

**Key Interfaces:**
- Markdown file format in `docs/agents/out-of-scope/` — each file must have
  `# Concept Name` title, `**Decision:**` line, `**Reason:**` line,
  and `**Previous Requests:**` list with issue links
- Triage workflow reads all `docs/agents/out-of-scope/*.md` files early
  and matches incoming issues by conceptual similarity

**Acceptance Criteria:**
- [ ] Closing a feature as wontfix creates or updates a file in `docs/agents/out-of-scope/`
- [ ] File contains decision, reason, and link to closed issue
- [ ] If matching `docs/agents/out-of-scope/` file already exists, new issues append to "Previous Requests" without creating duplicates
- [ ] During triage, check existing `docs/agents/out-of-scope/` files and surface matches if new issues match prior rejections

**Out of Scope:**
- Automated matching (humans confirm matches)
- Re-opening previously rejected features
- Bug reports (only enhancement rejections go to `docs/agents/out-of-scope/`)
```

### Good Agent Brief (PR)

For PRs, "Current Behavior" describes diff state, asking the agent to finish or fix rather than build from scratch.

```markdown
## Agent Brief

**Category:** enhancement
**Summary:** Finalize contributor's `--json` output flag for `triage list`

**Current Behavior:**
PR adds a `--json` flag serializing issue lists to JSON. Happy path works
and diff matches project command structure. Two gaps remain: errors are still
output as human text (not JSON), and the new flag lacks test coverage.

**Desired Behavior:**
Under `--json`, all output — including errors — is well-formed JSON on stdout,
and exit codes remain unchanged. Default human-readable output without the flag
remains untouched.

**Key Interfaces:**
- Command error paths must output `{ "error": string }` under `--json` instead of plain text errors
- Reuse existing serializers added in PR; do not introduce a second serializer

**Acceptance Criteria:**
- [ ] `triage list --json` outputs valid JSON on both success and error
- [ ] Exit codes match non-JSON commands
- [ ] Tests cover `--json` success output and at least one error case
- [ ] Default (non-JSON) output remains byte-for-byte unchanged

**Out of Scope:**
- Adding `--json` to other commands
- Changing JSON shapes of success payloads already defined in PR
```

### Bad Agent Brief

```markdown
## Agent Brief

**Summary:** Fix triage bug

**TODO:**
Triage is broken. Look at the main file and fix it.
The function around line 150 is the problem.

**Files to change:**
- src/triage/handler.ts (line 150)
- src/types.ts (line 42)
```

Why this is bad:
- No category
- Vague description ("Triage is broken")
- References file paths and line numbers destined to become stale
- No acceptance criteria
- No scope boundaries
- No description of current vs desired behavior
