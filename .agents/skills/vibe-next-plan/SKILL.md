---
name: vibe-next-plan
description: Investigates codebase to find grounded product directions — 4–6 evidence-backed proposals on what to build next — then refines the user's choice into a spec or decision map for planning skills. Source code is read-only. Use when the user asks "what should we build next", wants roadmap/feature ideas, or needs to decide the next move.
disable-model-invocation: true
metadata:
  argument-hint: "Optional focus — module, subsystem, or topic to narrow investigation"
---

# Investigating What to Build Next

**Directional Investigation**: Reads the codebase, discovers what it wants to become, and presents grounded options for maintainers to act upon. This skill produces **decisions rather than deliverables**, handing off to planning skills.

Investigation is **read-only on source code**. Never create persistent files — not under `src/`, `.agents/plans/`, or `docs/agents/out-of-scope/`. Output is a report in dialogue; downstream planning skills own all files. No edits, modifications, or "quick touch-ups".

## Why a Separate Skill

`/vibe-plan` starts from requests the user already has. This skill is used when the user **does not yet have a request** — wanting to know what is valuable. It conducts reconnaissance and directional audits, passing findings to the same planning pipeline consumed by `vibe-plan` and `vibe-deep-plan`.

## Workflow

### Phase 1 — Reconnaissance

Understand the territory before judging. Recon facts scope directional exploration and feed evidence for every proposal.

- Read `README`, `AGENTS.md`/`CLAUDE.md`, `CONTRIBUTING`, root config files (`package.json`, `pyproject.toml`, `go.mod`, etc.), CI configs, and directory layout.
- Read domain glossary (`CONTEXT.md`) and ADRs for user-specified areas — vocabulary makes proposals grounded rather than generic.
- Identify: language, framework, package manager, build/test/lint/typecheck commands (exact commands feed verification gates in downstream plans), test coverage shape, deployment targets.
- Note repository conventions: code style, naming, folder structure, error handling, and state management patterns.
- Inspect git signals (`git log --oneline -30`, churn hotspots) where helpful to distinguish actively moving areas from frozen code. High-churn areas are where direction is most valuable — where maintainers are already investing.

If user specified a focus (module, subsystem, topic), slant reconnaissance and audits toward it, skipping heuristic inference below.

Otherwise, churn hotspots draw attention first. If changes are diffuse without clear hotspots, widen the net.

### Phase 2 — Directional Audit

Audit only **directional** categories: not what is broken, but what this codebase wants to become. Target **4–6 grounded proposals**.

For repositories of notable size, fan out via parallel read-only subagents. If host agents cannot launch subagents, audit directly. Subagents do not inherit skill context, so each subagent prompt must include:

- Recon facts scoping exploration (language, framework, key directories, what to skip).
- Domain terms from `CONTEXT.md` — so proposals use the project's own naming.
- Grounding rules (below) and finding format (below), pasted in full or referenced by absolute path.
- Explicit instruction to return proposals only — no fixes, no file dumps.

#### Grounding Rules

Every proposal must cite **evidence from the repository itself**. Proposals applicable to any project in that category ("add dark mode", "add AI") are noise rather than findings. Sources of grounded directional signals:

- **Unfinished intent** — Clustered TODOs/FIXMEs around a theme, unexposed feature flags, stubs or half-built modules, commented feature code, abandoned branches in git history.
- **Declared but undelivered** — README/doc/roadmap promises lacking corresponding code, no-op CLI flags or config options, issue templates for non-existent features.
- **Surface asymmetry** — One-way pairs (export without import, single create without bulk create, outgoing webhooks without incoming), entities missing one CRUD operation, public APIs bypassed manually because internal code clearly needed something else.
- **Adjacent possible** — Capabilities made unusually cheap by existing architecture: plugin systems needing just one more interface, public APIs needing just one more route file over an existing service layer, integrations already supported by data models.
- **Productizable friction** — Manual workarounds project users clearly perform (evident in docs, examples, issues) that the project could absorb.

#### Finding Format

Every proposal returns in this format:

```markdown
### [DIRECTION-NN] Short Imperative Title

- **Evidence**: `path/file.ts:123` — One-sentence description of what exists. (Repeat per location; strongest 2–5 locations, add "~N similar locations" if widespread.)
- **Impact**: Product/user value — who wants this and why now. Concrete, not "nice to have".
- **Effort**: S (hours) / M (~1 day) / L (multiple days) — rough estimates; state so. Direction estimates are coarser than fix estimates.
- **Risk**: Cost to build or what it might break; LOW/MED/HIGH with one-line rationale.
- **Confidence**: HIGH (strong repo evidence) / MED (signals, needs verification) / LOW (intuition, needs research).
- **Trade-offs**: 2–3 sentences. What this opens, what it closes, what it costs to maintain.
```

### Phase 3 — Verification

Verify before presenting — subagents over-report. Open cited code directly for every proposal reaching the table. Anticipate three failure modes: **intentional design** mistaken for unfinished work (deliberate placeholder no-op flags); **misattributed evidence** (real signal, wrong file/line); and duplication across subagents. Demote, revise, or reject accordingly.

Proposals failing grounding tests — generic enough to apply to any project — are rejected rather than demoted. Record rejections in a "Considered but Rejected" section of the report to avoid surfacing on subsequent runs.

### Phase 4 — Presentation

Present verified proposals in a table, ordered by leverage (impact ÷ effort, weighted by confidence):

| # | Proposal | Impact | Effort | Risk | Confidence | Evidence |

Append full **Trade-offs** for each proposal after the table — maintainers weigh these, not investigators. Do not force-rank into a single "best choice"; maintainers decide.

Ask which proposal to pursue. Default recommendation: top 1–2 by leverage. Surface **dependency ordering** — "Proposal 2 builds on data models Proposal 3 already introduces, so Proposal 3 should arrive first if both are chosen."

Await selection. Never plan what nobody requested.

### Phase 5 — Handoff

Hand off selected proposals to appropriate downstream skills. This skill **never writes plans directly** — it produces direction, letting planning pipelines take over.

1. **If proposal fits in one planning session** — Hand off to `/vibe-plan`. Pass proposal evidence, impact, trade-offs, and recon facts (build/test/lint commands, conventions, ADRs) as starting inputs. `/vibe-plan` begins in the **grill** stage to sharpen into a spec.

2. **If proposal is too large for one session** — Shrouded in fog to the destination — Hand off to `/vibe-deep-plan`. Pass the same starting materials. `/vibe-deep-plan` charts a decision map.

3. **If maintainer wants to reflect before planning** — Stop here. The investigation is the deliverable. Maintainers can return later with chosen proposals to `/vibe-plan` or `/vibe-deep-plan`.

State recommended handoff and rationale in one line, then wait.

## What This Skill Never Does

- **Never edits source code.** No fixes, implementations, or "quick improvements".
- **Never writes implementation plans.** That belongs to `/vibe-plan`.
- **Never creates tickets in trackers.** That belongs to `/vibe-plan` or `/vibe-deep-plan`.
- **Never reproduces secret values.** If credentials are discovered during investigation, reference only `file:line` and credential type — never values.
- **Never re-adjudicates ADRs.** If proposals conflict with recorded ADRs, surface and flag the conflict — never overwrite.

## Tone

Advise; do not sell. State proposals plainly alongside evidence, mark uncertainties honestly, and favor "not worth doing" verdicts over padding lists. A short list of high-confidence, high-leverage proposals beats a long one.
