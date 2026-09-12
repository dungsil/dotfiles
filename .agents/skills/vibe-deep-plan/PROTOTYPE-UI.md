# UI Prototypes

Build **multiple radically different UI variants** within a **standalone prototype app** under `.agents/prototype/<name>/`, switchable via a bottom floating bar. The user flips through variants in the browser to pick one (or take pieces from each) and discard the rest.

If the question is about logic/state rather than "what should it look like", that is the wrong branch. Use [PROTOTYPE-LOGIC.md](PROTOTYPE-LOGIC.md).

## Table of Contents

- When This Shape Fits
- Prototypes are Always Standalone Apps
- Recreate Real Context Without Importing
- Process — State Question, Scaffold, Copy Context, Generate Variants, Wire, Build Switcher Bar, Hand Off, Capture
- Anti-Patterns

## When This Shape Fits

- "What should this page look like?"
- "Want to see a few options for this dashboard before committing."
- "Let's try a different layout for the settings screen."
- Any case where the user would otherwise spend the day comparing three vague mockups in their head.

## Prototypes are Always Standalone Apps

There are no sub-variants. Whether the question is about a brand-new screen or one section of an existing `/settings` page, variants live in a prototype-local app with its own entrypoint under `.agents/prototype/<name>/`. **Never mount anything on production routes.**

The perennial temptation is rendering variants on the actual page because variants judged in a vacuum always look fine. The intuition is right; the mechanics are wrong. Hosting on actual routes buys fidelity with production diffs — host pages, data layers, shared components, and build configs get edited for something destined for the trash. Isolation buys the same fidelity differently: **copy the parts of real context that alter judgment into the prototype**.

### Strong Boundaries

- **Everything under `.agents/prototype/<name>/`** — variant source, switcher bar, fixtures, copied shell components, styles, dependency manifests, run commands.
- **Never import from production source.** No `@/components/…`, no `../../src/…`, no real types, hooks, or API clients. If a variant needs a real sidebar, copy the file to the prototype directory and trim it.
- **No real auth, data, or mutations.** Fixtures and in-memory state only. Interfaces that perform writes call local stubs logging what they would have done.
- **Do not edit production routes, shared components, build configs, or manifests** — root `package.json`, lockfiles, `vite.config`, `next.config`, `tsconfig`, `Makefile`/`justfile`, CI configs, route manifests. Leave all untouched.

Run two scoped isolation checks instead of requiring a clean repository:

- **Production boundary** — Compare `git status --short` captured before scaffolding with the same command afterward. Ignore preexisting unrelated work. Verify zero production changes introduced by the prototype. Any prototype-related modification outside `.agents/prototype/<name>/` violates boundaries.
- **Prototype contents** — If `.agents/prototype/<name>/` is ignored, list files with `git ls-files --others --ignored --exclude-standard .agents/prototype/<name>/`; otherwise verify tracked/untracked prototype diffs are confined to that path. Either way, confirm variants, switcher bar, fixtures, manifests, and README reside under `.agents/prototype/<name>/`.

This is also why production build gates are unnecessary. Prototypes have no path into production bundles, so there is nothing to hide behind environment checks — isolation *itself* is the guard.

PROTOTYPE.md's rule "follow project routing conventions" applies **inside** the prototype app. Route however the prototype's own entrypoint routes. Do not add to the project's route tree.

## Recreate Real Context Without Importing

Fidelity is the whole reason to care about context, so do not skip it — recreate it locally. Copy only what changes judgment:

- **Shell** — Headers, sidebars, page chrome at actual size, so each variant is evaluated in the space it will actually occupy. Copy real components and trim them, or stub with fixed-size blocks carrying proper labels and widths.
- **Density** — Real row counts, real string lengths, real worst cases: 40-character workspace names, empty states, accounts with 47 notification toggles. Three rows of happy-path fixtures make every layout look good and teach nothing.
- **Data shape** — Mirror actual payload/props shapes in local fixture modules, re-typing fields inline. Copy shapes; do not import types.
- **Styling system** — Recreate the project's actual system (Tailwind config values, shadcn tokens, MUI theme, standard CSS variables) by copying relevant tokens into the prototype. Approximate without importing.

Copy just enough for variants to disagree meaningfully, then stop. Re-architecting the app is not the goal.

**Concrete Example — A Section of an Existing Page.** For "what structure should the notification section in /settings have": the prototype app renders a *local copy* of the settings shell — same nav, same page header, same surrounding section stack — varying only the notification section, fed by fixtures mirroring the real preference payload including long labels and empty groups. Evaluation carries the exact same sharpness as on the actual route. `/settings` itself is never opened.

## Process

### 1. State the Question and Pick N

Default is **3 variants**. Beyond 5, they become noise rather than fundamentally different approaches — stop there.

Write the plan in one line at the top of the prototype's README:

> "Three structurally different proposals for the /settings notifications section, switchable via `?variant=` in `.agents/prototype/settings-notifications/`."

Works whether the user is present to push back or not.

### 2. Scaffold Prototype App

- Make `.agents/prototype/<name>/` its own **entrypoint** — cheapest option in project framework: small Vite app, standalone framework app, or a single HTML file with a script.
- Reuse project framework and package manager so variants look right, but declare dependencies in the **prototype's own manifest**. Do not add dependencies or scripts to root manifests.
- **Single run command**, documented in the prototype's README and executable from the prototype directory — e.g. `cd .agents/prototype/<name> && pnpm dev`, or `bun run index.tsx`. Run metadata stays prototype-local. Do not touch project task runners.
- Leave repository ignore policies untouched. If `.agents/prototype/<name>/` is ignored, force-add that path only on the throwaway branch (Step 8).

### 3. Copy Context

Build the local shell, fixtures, and style tokens described in [Recreate Real Context](#recreate-real-context-without-importing) before authoring variants. Doing so afterward leads to variants designed in a vacuum and retrofitted later.

### 4. Author Radically Different Variants

Write each variant. For each:

- Screen purpose and accessible fixture data.
- Project component library/styling system, as recreated locally (TailwindCSS, shadcn, MUI, plain CSS, whatever is used).
- Distinct exported component names, e.g. `VariantA`, `VariantB`, `VariantC`.

Variants must be **structurally different** — distinct layouts, distinct information hierarchies, distinct primary interactions, not merely different colors. Three slightly adjusted card grids are wallpaper, not a UI prototype. If two drafts turn out too similar, redo one with an explicit "do not use card grids" constraint.

### 5. Wire Up

A single switcher bar sits at the prototype app entrypoint:

```tsx
// Pseudocode — adapt to project framework
import { fixture } from './fixtures';        // Local fixture, not real loader/query

const variant = searchParams.get('variant') ?? 'A';
return (
  <PrototypeShell>                            {/* Local copy of real chrome */}
    {variant === 'A' && <VariantA {...fixture} />}
    {variant === 'B' && <VariantB {...fixture} />}
    {variant === 'C' && <VariantC {...fixture} />}
    <PrototypeSwitcher variants={['A','B','C']} current={variant} />
  </PrototypeShell>
);
```

Data originates from the fixture module above the switcher bar. Only the rendered subtree changes across variants.

### 6. Build Floating Switcher Bar

A small fixed-position bar centered at bottom screen, three parts:

- **Left arrow** — Cycle to previous variant (wraps around).
- **Variant label** — Displays current variant key, plus exported name if variant provides one. E.g. `B — Sidebar Layout`.
- **Right arrow** — Cycle forward (wraps around).

Behavior:

- Clicking arrows updates `?variant=` URL search params, making variants **shareable and refresh-stable**. Use what the prototype app provides — framework routers (`router.replace`, `navigate`) or `history.replaceState` with re-render in plain HTML prototypes.
- Keyboard: `←` and `→` arrow keys cycle variants. Do not intercept arrow keys when focus is inside `<input>`, `<textarea>`, or `[contenteditable]`.
- Visually distinct from the page (e.g. high-contrast pill, subtle shadow) making it obvious it is not part of the design under review.

The switcher bar is a prototype-local component — inside `.agents/prototype/<name>/` beside variants, not in the project's shared UI folder.

### 7. Hand Off

Provide run command, URL, and `?variant=` keys. This is the ticket's HITL half: the user flips through when available, and the ticket resolves only through that exchange — never pick a winner on the user's behalf.

Valuable feedback is often **"We want B's header with C's sidebar"** — that combination is their real design. Build it as an additional variant and hand off again.

### 8. Capture Verdict — Implementation is a Follow-up Ticket

When a variant wins, capture the answer — which variant, why, requested combinations — and capture the prototype as described in [PROTOTYPE.md](PROTOTYPE.md): all variants and switcher bar go to a **throwaway branch** as a primary source. Leave repository ignore policies untouched; force-add `.agents/prototype/<name>/` on that throwaway branch only if the path is ignored. Leave a context pointer to that branch on the ticket. Post the verdict as a resolution comment, close the ticket, and add a one-line gist to the map's **Decisions so far**.

**Do not fold the winner into production code here.** This ticket resolves a *decision*. Building it is separate work — a follow-up task ticket, or `/vibe-plan` output after the map finishes. Therefore, the verdict must capture what that follow-up needs:

- Which variant won, and meaningful structural decisions within it (information hierarchy, primary interactions, layout).
- Elements borrowed from losing variants.
- What the production version actually needs to wire up — real routes, real components, real data sources and auth — everything untouched by the prototype.

Main branch retains only the recorded decision. No variant code, switcher bar, or prototype directory.

## Anti-Patterns

- **Variants differing only in color or copy.** That is tweaking, not prototyping. Real variants take differing stances on structure.
- **Importing "just this one component" from production source.** A single import links throwaway code to the real tree and pulls in providers, types, and configs. Copy the file to the prototype directory and trim it.
- **Mounting variants on actual routes**, or hiding behind feature flags / environment checks in production code. The prototype has its own entrypoint. That is the whole point.
- **Touching root manifests, build configs, or task runners** to run the prototype. Declare needed dependencies or scripts in the prototype's own manifest.
- **Thin fixtures.** Three clean rows make every layout shine. Unless real density and ugly edge cases are recreated, the prototype answers nothing.
- **Sharing too much code across variants.** A shared shell is fine — that is copied context. A shared `<Layout>` defeats the point: each variant must remain free to discard layouts.
- **Connecting variants to real data, auth, or mutations.** Fixtures and logging stubs only. The question is "what should it look like", not "does the backend work".
- **Directly promoting prototype code to production.** Variant code was written under prototype constraints (no tests, minimal error handling, mock data). Follow-up tickets rewrite it properly.
