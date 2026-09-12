---
name: vibe-review
description: Reviews changes after a fixed point against Standards and Spec, adding Risk for risk-audit, thermos, or thermo nuclear requests and for security, auth, permissions, persistence, transaction, or external-integration changes. Runs enabled axes in parallel subagents and reports them separately. Use for branches, PRs, working changes, "review after X", and risk audits.
---

# Reviewing Changes

A separated review of the diff between `HEAD` and a user-provided fixed point:

- **Standards** — Does the code adhere to this repository's documented coding standards?
- **Spec** — Does the code faithfully implement the source issue / PRD / spec?
- **Risk** — Does added or modified code introduce bugs, security problems, developer-experience breakage, or feature-gate leaks?

Standards and Spec are the default axes. Enable Risk only when the user requests a risk audit, thermos, or thermo nuclear review, or when the change touches security, authentication, permissions, persistence, transactions, or external integrations. Enabled axes run as **parallel subagents** so they do not pollute each other's context, with this skill aggregating the findings.

The Spec axis is a **fast review** — a single subagent reading the diff against the spec and reporting missing requirements, scope creep, and incorrect implementations within 400 words. When the user requests a formal requirements verdict — acceptance criteria with per-item status, separated evidence domains, independent reviewer passes, or an aggregate `PASS`/`FAIL`/`NEEDS_REVIEW` — run `/rq` separately on the same requirements. When `/rq` runs, it replaces Spec; do not run both and merge them. A direct `/vibe-review` never invokes `/rq` automatically merely because a change is high-risk.

Issue tracker should have been provided — run `/vibe-init` if `docs/agents/issue-tracker.md` is missing.

## Process

### 1. Pin the Fixed Point

What the user specified as fixed point — commit SHA, branch name, tag, `main`, `HEAD~5`, etc. If another skill invoked this skill passing a fixed point (`/vibe-implement` passes its commit recorded prior to start), use it without asking. Ask only when neither user nor caller provided one.

Capture diff command once: `git diff <fixed-point>...HEAD` (three dots for merge-base comparison). Record commit list via `git log <fixed-point>..HEAD --oneline`.

Verify fixed point resolves (`git rev-parse <fixed-point>`) and diff is non-empty before proceeding. Invalid refs or empty diffs must fail here — not inside parallel subagents.

### 2. Identify Spec Source

Locate source spec in this order:

1. Issue references in commit messages (`#123`, `Closes #45`, GitLab `!67`, etc.) — fetch via `docs/agents/issue-tracker.md` workflow.
2. Paths passed by user as arguments.
3. PRD/spec files under `docs/`, `specs/`, or `.agents/plans/` matching branch name or feature.
4. If none found, ask user for spec location. If user states there is none, skip **Spec** subagent and report "No spec".

### 3. Decide Whether to Run Risk

Before launching subagents, enable Risk when either condition holds:

- The user requested a risk audit, thermos, or thermo nuclear review.
- The diff touches security, authentication, permissions, persistence, transactions, or external integrations.

Otherwise disable Risk. A missing spec does not affect this decision. High-risk signals enable Risk; they do not automatically invoke `/rq`.

### 4. Identify Standards Source

Anything documenting how code should be written in this repository, such as `CODING_STANDARDS.md` or `CONTRIBUTING.md`.

On top of repository documentation, the Standards axis always includes the **Smell Baseline** below — a fixed set of Fowler code smells (*Refactoring*, ch.3) applying even when repos document nothing. Two rules bind this:

- **Repository takes precedence.** Documented repo standards always win; if repo endorses what the baseline flags, suppress the smell.
- **Always judgment calls.** Each smell is a labeled heuristic ("possible Feature Envy"), never a hard violation — and, like all standards here, skip what tooling already enforces.

Read each smell as *What it is* → *How to fix*; tailored to diffs:

- **Mysterious Name** — Function, variable, or type names failing to reveal what they do or hold. → Rename; if no honest name comes to mind, design is unclear.
- **Duplicated Code** — Same logical shape appears across multiple hunks or files in the change. → Extract shared shape and call from both sides.
- **Feature Envy** — Reaching into another object's data more than its own. → Move method to the data it envies.
- **Data Clumps** — Same few fields or parameters traveling together repeatedly (types waiting to be born). → Bundle into a single type and pass that.
- **Primitive Obsession** — Primitives or strings substituting for domain concepts deserving own types. → Give the concept a small type of its own.
- **Repeated Switches** — Same `switch`/`if` ladder over same types repeating across the change. → Replace with polymorphism or a shared map.
- **Shotgun Surgery** — Single logical change forcing edits scattered across multiple files in the diff. → Consolidate co-changing code into one module.
- **Divergent Change** — Single file or module edited for multiple unrelated reasons. → Split so each module changes for one reason.
- **Speculative Generality** — Abstractions, parameters, or hooks for needs absent from the spec. → Delete; revert inline until real need appears.
- **Message Chains** — Long `a.b().c().d()` navigations callers should not depend on. → Hide path behind a single method on first object.
- **Middle Man** — Classes or functions mostly delegating. → Cut them and call the real target directly.
- **Refused Bequest** — Subclasses or implementations ignoring or overriding most inherited behavior. → Abandon inheritance and use composition.

### 5. Run Enabled Axes in Parallel

Dispatch one `Agent` tool call per enabled axis in a single message, all using `general-purpose` subagents. Do not launch Spec when no spec exists or Risk when Step 3 disabled it.

**Standards Subagent Prompt** — Include:

- Full diff command and commit list.
- List of standards source files found in Step 4, **plus the full Smell Baseline from Step 4** pasted in — subagents have no other access.
- Instructions: "Report — per relevant file/hunk — (a) where diff violates documented standards: cite standard (file + rule); and (b) noticeable baseline smells: name smell and cite hunk. Distinguish hard violations from judgment calls — documented standard violations may be hard, baseline smells are always judgment calls, and documented repo standards override baseline. Skip what tooling enforces. Under 400 words."

**Spec Subagent Prompt** — Include:

- Diff command and commit list.
- Spec path or fetched contents.
- Instructions: "Report: (a) requirements required by spec but missing or partial; (b) unrequested behavior in diff (scope creep); (c) requirements appearing implemented but implemented incorrectly. Cite spec lines for each finding. Under 400 words."

If spec is absent, skip Spec subagent and note this in final report.

**Risk Subagent Prompt** — Include when Step 3 enabled Risk:

- Full diff command, commit list, and changed-file content needed to evaluate risk.
- Instructions: "Audit added and modified code only. Report (a) bugs and existing-functionality breakage, (b) security problems, (c) developer-experience breakage from secrets, environment-variable or port changes, or new mandatory manual installation, and (d) feature-gate leaks. Adding a dependency through the package manager is not itself developer-experience breakage. Skip feature-gate checks when the repository has no feature gates. Do not report intentional breakage when the branch clearly intends it and its impact is tightly contained. Do not inflate priority. Trace available code to completion and never report an unverified hypothesis. Only after completing your own audit, read PR/MR discussion if present and incorporate valid existing review findings without depending on any named bot. Cite files/hunks and evidence. Under 400 words."

### 6. Aggregate

Present reports under `## Standards`, `## Spec` when available, and `## Risk` when enabled, as-is or lightly trimmed. Do **not** merge or re-rank findings across axes or weight overlaps.

Conclude with a one-line summary: total findings per enabled axis, and worst issue *within each axis* (if any). Do not pick a single winner between axes.

### 7. Read-Only Review Contract

Direct reviews and reviews invoked by other workflows are **read-only**. The sole output is the separated axis report in Step 6:

- On clean passes, report 0 findings; passes are not authority to land, update, or close work.
- If findings exist, report findings; if spec was absent, report that limitation.
- Never edit issue/PR bodies or acceptance boxes, post comments, alter labels/statuses, close/reopen work, or create other tracker, repository, or external side effects.

Acceptance checklists belong to `/vibe-implement`, which ticks them after a clean review and before the human merges. Review does not defer those writes until after merge. Closing issues is separate from checklists and is out of this skill's scope.

## Why Separate Axes

Changes can pass one axis and fail the other:

- Code following all standards but implementing the wrong feature → **Standards Pass, Spec Fail.**
- Code doing exactly what the issue requested but violating project conventions → **Spec Pass, Standards Fail.**
- Code satisfying standards and spec but introducing an authentication bypass → **Standards and Spec Pass, Risk Fail.**

Reporting separately prevents one axis from obscuring the other.
