# Logic Prototypes

A small interactive terminal app allowing users to pilot state models directly. Use when the question is about **business logic, state transitions, or data shapes** — things that look reasonable on paper but feel wrong once pushed through concrete test cases.

Place all artifacts in `.agents/prototype/<name>/`: pure logic, TUI, README with run command, dependency manifests and lockfiles, fixtures, and persistence scratch. The prototype may inspect production source in read-only mode for context, but must not import production modules or modify production source, root manifests, task runners, production configs, databases, auth, routes, or shared components. Use prototype-local dependencies, in-memory or local scratch data, and stubs instead.

## When This Shape Fits

- "Not sure this state machine handles the edge case where Y follows X."
- "Can this data model actually represent cases where...?"
- "Want to get a feel for what the API should look like before writing code."
- Any case where the user wants to **press buttons and observe state changes**.

If the question is "what should this look like", that is the wrong branch. Use [PROTOTYPE-UI.md](PROTOTYPE-UI.md).

## Process

### 1. State the Question

Before writing code, state the state model and question being prototyped in a single paragraph — in `.agents/prototype/<name>/README.md` or a top-level comment in prototype-local files. A logic prototype answering the wrong question is pure waste. Make the question explicit so it can be verified later whether the user is watching now or returning AFK.

### 2. Choose Language

Reuse the host project's language and runtime when pragmatic. If the project lacks a clear runtime (e.g. documentation repo), ask.

Place all dependency manifests and lockfiles inside `.agents/prototype/<name>/`. Do not modify root manifests or task runners, or introduce new runtimes solely for a prototype.

### 3. Isolate Logic into Portable Modules

Place the core logic — the part answering the question — behind a small, pure interface in `.agents/prototype/<name>/`. It should be readable as reference material for a separate follow-up production implementation. The surrounding TUI is throwaway. Logic modules and TUI must remain separated.

The right shape depends on the question:

- **Pure reducer** — `(state, action) => state`. Great when actions are discrete events and state is a single value.
- **State machine** — Explicit states and transitions. Great when "what actions are legal right now" is part of the question.
- **Small set of pure functions over plain data types.** Great when there is no implicit current state and only transformations exist.
- **Class or module with clean method surface** when logic genuinely owns ongoing internal state.

Choose the shape that best fits the question, not what is easiest to wire to a TUI. Keep it pure: no I/O, terminal codes, `console.log` for control flow, production module imports, or real auth/data/database/config mutations. The prototype-local TUI imports and calls prototype-local logic. Never the reverse.

This makes the prototype useful beyond its own lifespan: verified reducers/machines/functions record decisions and provide references for subsequent production implementations. Do not lift, copy, or merge into production source while resolving the prototype.

### 4. Build Minimal State-Exposing TUI

Place the TUI alongside logic in `.agents/prototype/<name>/`. Use only prototype-local dependencies, fixtures, scratch data, and stubs.

Make it a **lightweight TUI** — clear the screen on each tick (`console.clear()` / `print("\033[2J\033[H")` / equivalent) and re-render the entire frame. Users should see a single stable view rather than an expanding scrollback.

Each frame consists of two parts in this order:

1. **Current state**, pretty-printed and easy to diff (one line per field, or formatted JSON). Field names or section headers in **bold**, less important context (time, IDs, derived values) in **dim**. Native ANSI escape codes suffice — `\x1b[1m` bold, `\x1b[2m` dim, `\x1b[0m` reset. No need to pull in styling libraries unless already in the project.
2. **Keyboard shortcuts** listed at the bottom: `[a] Add User  [d] Delete User  [t] Tick Clock  [q] Quit`. Keys bold, descriptions dim, or vice versa — whichever reads cleanly.

Lifecycle:

1. **Initialize state** — A single memory object/struct, or explicitly disposable prototype-local scratch data when persistence itself is the question. Render first frame at startup.
2. **Read one keystroke (or line) at a time**, pass to local pure interface, and replace state with the result.
3. **Re-render full frame after every action** — replace, not append.
4. **Repeat until quit.**

The full frame must fit on one screen.

### 5. Runnable via a Single Local Command

Document exactly one copy/paste command in `.agents/prototype/<name>/README.md`. It must launch the prototype from local code and, if used, local manifests and dependencies — e.g. `pnpm --dir .agents/prototype/<name> start`.

Reuse host runtimes where pragmatic, but do not add root task-runner scripts or edit root manifests. The single-command handoff stays prototype-local.

### 6. Hand Off

Give the user that exact prototype-local run command. The user drives directly. The valuable moment is when they say "Wait, that shouldn't be possible" or "Huh, I expected X to happen like that". That is a bug in the *idea*, and that is the whole point. Add new actions if desired. Prototypes evolve.

### 7. Capture Answer and Prototype

Once the prototype has answered the question, capture answer and prototype as described in [PROTOTYPE.md](PROTOTYPE.md): record verdict and question in the ticket's resolution comment, close the prototype ticket, and preserve the prototype as a primary source. Verified logic serves as a decision/reference for a separate follow-up production implementation, not code to lift into production during prototype resolution.

## Anti-Patterns

- **Do not add tests.** A prototype requiring tests is no longer a prototype.
- **Do not connect to production services.** Do not use or mutate production databases, configs, auth, or data. Use memory storage unless persistence is the question, in which case use only clearly disposable scratch files/stores under `.agents/prototype/<name>/`.
- **Do not generalize.** No "what if we support X later". Prototypes answer one question.
- **Do not mix logic and TUI.** If reducers/machines reference `console.log`, prompts, terminal escape codes, or production modules, they are no longer portable. Keep the TUI as a thin shell over pure prototype-local modules.
- **Do not ship the TUI shell or lift its logic into production.** The shell is optimized for hands-on terminal piloting. Verified logic provides evidence for a subsequent, separate production implementation.
