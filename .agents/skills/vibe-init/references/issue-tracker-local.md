# Issue Tracker: Local Markdown

Issues and specifications (specs; also known as PRDs) in this repository are managed as Markdown files inside `.agents/plans/`.

## Korean writing

Before drafting Korean specifications, issues, or comments, read the installed `vibe-docs` skill and follow its `Required application order`. Preserve the exact form of domain terms and label strings defined in `CONTEXT.md`, relevant ADRs, and `docs/agents/`; do not translate, generalize, or neutralize them.

## Rules

- One directory per feature: `.agents/plans/<feature-slug>/`
- Specs live at `.agents/plans/<feature-slug>/spec.md`
- Implementation issues live one file per ticket at `.agents/plans/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`. `/vibe-plan` manages this directory.
- Deep-plan decision records live one file per ticket in typed directories:
  - `research/<NN>-<slug>.md` — `유형:조사` (AFK research)
  - `interviews/<NN>-<slug>.md` — `유형:인터뷰` (HITL dialogue)
  - `prototypes/<NN>-<slug>.md` — `유형:프로토타입` (throwaway artifacts)
  - `tasks/<NN>-<slug>.md` — `유형:작업` (manual prerequisites)
- Identifiers for deep-plan records are relative file paths like `research/03-compare-providers.md` or `interviews/04-confirm-scope.md`. Numeric prefixes serve only as sort keys. Blocker references must include type directory and `.md` filename; `issues/` is reserved for implementation tickets.
- All deep-plan records contain `Type:` and `Status:` lines near the top. Triage statuses apply to implementation tickets published by `/vibe-plan`.
- Deep-plan records begin with `Status: open`. Claiming sets `Status: claimed`, returning to `Status: open` after completing charting save. Final answers alone set `Status: resolved`. Incomplete handoffs or save failures retain `claimed`.
- Append comments and dialogue records under `## Comments` at bottom of record. Research findings reside in research records, not implementation issues.

## Version Control and Completion Updates

- Track `.agents/plans/` in git, ignoring scratch paths (`.agents/worktrees/`, `.agents/prototype/`). Ticket files are **branch content** — checklist states reflect the branch being read.
- Flip acceptance checkboxes on implementation tickets to `[X]` on the **feature branch** implementing them, within the **same commit** as the implementation — no separate tracker commits or pre-code commits on target branches. Merging is a human decision; merge brings code and checklist together or neither. Do not edit `Status:` lines.

## Research Record Persistence

- In local Markdown, the research ticket and canonical findings record are the same file: `.agents/plans/<effort>/research/<ticket-stem>.md`. Full findings with source citations live under `## Research`, final decisions under `## Answer`.
- Leave repository ignore policies untouched. Do not create, checkout, commit, or push research-only branches. Records are handoff artifacts on current branch, not deployment changes.
- Set record to `Status: claimed` before starting research. Revert to `Status: open` during charting after writing full findings. Retain `claimed` if save fails or session passes incomplete work. Set `Status: resolved` only alongside final decision under `## Answer`. Inspect canonical records before re-running research.

## When a Skill Says "Post to Issue Tracker"

- `/vibe-plan` Stage 2 spec publishing writes `.agents/plans/<feature-slug>/spec.md`. Reuses existing `.agents/plans/<effort>/` directory if input is an approved local Markdown map.
- `/vibe-plan` Stage 3 implementation publishing writes `.agents/plans/<feature-slug>/issues/<NN>-<slug>.md`. Uses same `<effort>/issues/` directory if from an approved map or spec at `.agents/plans/<effort>/spec.md`; other local spec paths use configured `.agents/plans/<feature-slug>/issues/` root.
- `/vibe-deep-plan` posts decision records under matching `research/`, `interviews/`, `prototypes/`, `tasks/` directories.

## When a Skill Says "Fetch Relevant Tickets"

Read provided local plan artifacts as-is: `map.md`, `spec.md`, deep-plan decision records, implementation issues. Do not substitute other feature roots. Users typically pass paths directly.

## Wayfinding Operations

Used by `/vibe-deep-plan`. A map is a file with one decision record per ticket.

- **Map**: `.agents/plans/<effort>/map.md` — Notes / Decisions-so-far / Fog body.
- **Research Record**: `.agents/plans/<effort>/research/NN-<slug>.md` with `Type: 조사` and `Status:` line.
- **Interview Record**: `.agents/plans/<effort>/interviews/NN-<slug>.md` with `Type: 인터뷰` and `Status:` line.
- **Prototype Record**: `.agents/plans/<effort>/prototypes/NN-<slug>.md` with `Type: 프로토타입`, `Status:`, and `.agents/prototype/<name>/` pointer if artifacts exist.
- **Task Record**: `.agents/plans/<effort>/tasks/NN-<slug>.md` with `Type: 작업` and `Status:` line.
- **Blocking**: `Blocked by: research/03-compare-providers.md, interviews/04-confirm-scope.md`. Unblocks when each listed record resolves.
- **Frontier**: Union of `research/`, `interviews/`, `prototypes/`, `tasks/` finding records with `Status: open` and no open blockers, sorted by numeric prefix then canonical relative path.
- **Claim**: Set to `Status: claimed` and save before work. Local Markdown has no `Assignee:` field. Do not serialize hosted tracker assignee metadata.
- **Resolve**: Append answer under `## Answer`, set `Status: resolved`, and append linked record title with one-line gist to map's `map.md` Decisions-so-far.
