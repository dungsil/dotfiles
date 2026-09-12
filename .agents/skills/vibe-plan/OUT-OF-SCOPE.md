# Out-of-Scope Knowledge Base

The repository's `docs/agents/out-of-scope/` directory retains a durable record of rejected feature requests, serving two purposes:

1. **Organizational Memory** — Why features were rejected, so reasons survive issue closure
2. **Deduplication** — When incoming issues match prior rejections, skills surface prior decisions rather than reopening discussion

## Table of Contents

- Directory Structure
- File Format — Record template, file naming, writing reasons
- When to Check `docs/agents/out-of-scope/`
- When to Write to `docs/agents/out-of-scope/`
- Updating or Removing Out-of-Scope Files

## Directory Structure

```
docs/agents/out-of-scope/
├── dark-mode.md
├── plugin-system.md
└── graphql-api.md
```

One file per **concept**, not per issue. Multiple issues requesting the same thing cluster under one file.

## File Format

Write files in readable, natural prose — closer to short design documents than database entries. Use paragraphs, code samples, and examples so rationale is clear to newcomers:

```markdown
# Dark Mode

This project does not support dark mode or user-facing theming.

## Why Out of Scope

The rendering pipeline assumes a single color palette defined in `ThemeConfig`.
Supporting multiple themes would require:

- Theme context provider wrapping the entire component tree
- Per-component theme-aware style resolution
- Persistence layer for user theme preferences

This represents a significant architectural change misaligned with the project's
focus on content authoring. Theming is the concern of downstream consumers
embedding or redistributing output.

```ts
// Current ThemeConfig interface is not designed for runtime switching:
interface ThemeConfig {
  colors: ColorPalette; // Single palette resolved at build time
  fonts: FontStack;
}
```

## Previous Requests

- #42 — "Add dark mode support"
- #87 — "Night theme for accessibility"
- #134 — "Dark theme option"
```

### File Naming

Use short, descriptive kebab-case names for concepts: `dark-mode.md`, `plugin-system.md`, `graphql-api.md`. Make them recognizable enough that someone browsing the directory understands what was rejected without opening files.

### Writing Reasons

Reasons must be substantive — explaining why rather than merely stating "not wanted". Good reasons cite:

- Project scope or philosophy ("This project focuses on X; theming is a downstream concern")
- Technical constraints ("Supporting this requires Y, conflicting with our Z architecture")
- Strategic decisions ("Chose A over B because...")

Reasons must be durable. Do not reference temporary circumstances ("too busy right now") — that is deferral, not rejection.

## When to Check `docs/agents/out-of-scope/`

During triage (Step 1: Gather Context), read all files in `docs/agents/out-of-scope/`. When evaluating new issues:

- Check if request matches an existing out-of-scope concept
- Match by conceptual similarity, not keywords — "night theme" matches `dark-mode.md`
- If a match exists, surface to maintainer: "This is similar to `docs/agents/out-of-scope/dark-mode.md` — rejected previously for [reason]. Do you still feel the same?"

Maintainers can:

- **Confirm** — New issue appends to "Previous Requests" in existing file, then closes
- **Reconsider** — Out-of-scope file is deleted or updated; issue proceeds through normal triage
- **Disagree** — Issue is related but distinct; proceeds through normal triage

## When to Write to `docs/agents/out-of-scope/`

Only when **enhancements** (not bugs) are *rejected* as `wontfix`. Applies identically to enhancement PRs — record rejected PRs here so the same request does not return as fresh code.

Do **not** write here when closing as `wontfix` because something is **already implemented**. That is a built feature, not a rejected request; recording it pollutes duplicate checks with false rejections. Closing comments point to existing code instead.

Workflow:

1. Maintainer decides feature request is out of scope
2. Check if matching `docs/agents/out-of-scope/` file already exists
3. If yes: append new issue to "Previous Requests"
4. If no: create new file with concept name, decision, reason, and first previous request
5. Post comment on issue explaining decision and referencing `docs/agents/out-of-scope/` file
6. Close issue with `wontfix` label

## Updating or Removing Out-of-Scope Files

If maintainers change their mind on previously rejected concepts:

- Delete the `docs/agents/out-of-scope/` file
- No need to reopen old issues — they serve as historical records
- The new issue prompting reconsideration proceeds through normal triage
