---
name: vibe-refactor
description: Discovers deepening opportunities across codebase, presents them as a visual HTML report, and drills into user-selected candidates via focused deep dives. Use when requesting architecture reviews, refactoring/improving code structure, or addressing difficulty in testing or navigating code.
disable-model-invocation: true
---

# Improving Codebase Architecture

Surfaces architectural friction and proposes **deepening opportunities** — refactorings that turn shallow modules into deep modules. The goal is testability and ease of navigation for AI and developers.

This command is grounded in the project's domain model and operates on a shared design vocabulary:

- See [VOCABULARY.md](VOCABULARY.md) for Korean architectural terms (**모듈**, **인터페이스**, **깊이**, **경계**, **어댑터**) and principles (`삭제 테스트`, `인터페이스가 테스트하는 면이다`, `어댑터가 하나면 경계를 만들지 마라`). Use those Korean terms and Korean plain explanations in user-facing text. Do not stamp `seam`, `leverage`, or `locality` as labels. Do not drift into "component", "service", or "API".
- Domain language in `CONTEXT.md` provides names for good boundaries. ADRs in `docs/adr/` record decisions this command must not re-adjudicate.

## Process

### 1. Exploration

**Scope before scanning — YAGNI.** The reward for deepening a module comes from making future changes to that module easier, so weight recently modified areas of the codebase. Decide where to look *before* looking:

- If the user specified a direction (module, subsystem, problem area), follow it, skipping heuristic inference below.
- Otherwise, retrace a substantial span of commit history (`git log --oneline`) to identify codebase hotspots — files and areas appearing repeatedly — and let those paths draw initial attention. If changes are diffuse without clear hotspots, widen the net.

Read the project's domain glossary (`CONTEXT.md`) and ADRs for the target area first.

Then traverse the codebase using Agent tools with `subagent_type=Explore`. Do not follow rigid heuristics — explore organically and record where you encounter friction:

- Where must you jump between multiple small modules to understand a single concept?
- Where are modules **shallow** — interfaces as complex as their implementations?
- Where were pure functions extracted solely for testability, while real bugs hide in call patterns (fixes do not stay in one place)?
- Where do tightly coupled modules leak across boundaries?
- Which parts of the codebase remain untested or difficult to test through current interfaces?

Apply the **deletion test** to anything suspected of being shallow: if deleted, does complexity concentrate, or merely shift? "Concentrates" is the desired signal.

See [DEEPENING.md](DEEPENING.md) for dependency classification, boundary rules, and the "replace, don't overlay" test policy when evaluating candidates.

### 2. Present Candidates as an HTML Report

Write a self-contained HTML file to the OS temporary directory to avoid leaving artifacts in the repository. Determine the temp directory from `$TMPDIR`, falling back to `/tmp` (or `%TEMP%` on Windows), writing to `<tmpdir>/architecture-review-<timestamp>.html` so each run produces a fresh file. Open it for the user (`xdg-open <path>` on Linux, `open <path>` on macOS, `start <path>` on Windows) and report the absolute path.

The report uses **Tailwind (CDN)** for layout and styling, and **Mermaid (CDN)** for diagrams where graphs/flows/sequences clearly communicate structure. Mix Mermaid with bespoke CSS/SVG visualizations — use Mermaid for graph-shaped relations (call graphs, dependencies, sequences) and bespoke divs/SVGs when an editorial feel (mass diagrams, cross-sections, folding animations) is needed. Each candidate includes **before/after visualizations**. Make it visual. Write the report in plain Korean.

For each candidate, render a card containing:

- **파일** — Relevant files/modules
- **문제** — Why current architecture causes friction
- **해결** — What changes, explained in plain Korean
- **이점** — Whether fixes stay in one place, whether one interface covers many callers, and how testing improves
- **전/후 다이어그램** — Side-by-side bespoke illustrations showing shallowness vs deepening
- **권고 강도** — Rendered as a badge: `추천`, `검토`, or `불확실`

Conclude the report with a **최우선 권고** section: which candidate to tackle first and why.

**Use domain vocabulary from CONTEXT.md and the Korean plain explanations from [VOCABULARY.md](VOCABULARY.md).** If `CONTEXT.md` defines `주문 (Order)`, write `주문 접수 모듈` rather than `FooBarHandler` or `Order service`.

**ADR Conflicts**: When candidates contradict existing ADRs, surface them only when friction is substantial enough to warrant reopening the ADR. Mark clearly on cards (e.g. warning callout: _"ADR-0007과 충돌 — 하지만 재검토할 가치가 있는 이유는…"_). Do not list every theoretical refactor prohibited by ADRs.

See [HTML-REPORT.md](HTML-REPORT.md) for HTML scaffolding, diagram patterns, and styling guidance.

Do not propose interfaces yet. After writing the file, ask the user: "이 중 어느 것을 탐색해 보겠습니까?"

### 3. Deep Dive Loop

Once the user selects a candidate, run `/vibe-grilling` to walk the decision tree together — constraints, dependencies, shape of deepened modules, what lies behind the boundary, surviving tests.

Side effects occur inline as decisions solidify — run `/vibe-modeling` as you go to keep domain models current:

- **Naming deepened modules with concepts not in `CONTEXT.md`?** Add terms to `CONTEXT.md`. Create file lazily if missing.
- **Sharpening ambiguous terms during discussion?** Update `CONTEXT.md` on the spot.
- **User rejects a candidate for substantive reasons?** Propose an ADR: _"이것을 ADR로 기록하여 향후 아키텍처 검토에서 다시 제안하지 않게 할까요?"_ Propose only when reasons are genuinely necessary to prevent future explorers from suggesting the same thing — skip temporary reasons ("not worth it right now") and self-evident rationale.
- **Want to explore alternative interfaces for deepened modules?** Use the design-it-twice parallel sub-agent pattern in [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md).
