# Prototype Tickets

How `유형:프로토타입` tickets get resolved. Prototypes are a **HITL** type. The artifact exists to give a human something concrete to react to, and resolves solely through that real-time exchange.

A prototype is **throwaway code to answer a question**. The question shapes the artifact.

## Choosing a Branch

Identify the question being answered. Check user prompts, surrounding code, or ask directly if the user is present:

- **"Does this logic/state model feel right?"** → [PROTOTYPE-LOGIC.md](PROTOTYPE-LOGIC.md). Build a small interactive terminal app that stresses the state machine with cases that are difficult to reason through on paper.
- **"What should this look like?"** → [PROTOTYPE-UI.md](PROTOTYPE-UI.md). Build multiple radically different UI variants switchable via URL search params and a bottom floating bar from a prototype-local route/entrypoint under `.agents/prototype/<name>/`.

The two branches produce very different artifacts. Choosing wrong renders the entire prototype wasted effort. If the question is truly ambiguous and the user is unreachable, default to the branch best matching surrounding code (logic for backend modules, UI for pages/components) and state that assumption at the top of the prototype.

## Rules Common to Both

1. **Isolate before coding.** Create `.agents/prototype/<name>/` before writing code. Place all artifacts inside it: source, dependency manifests/lockfiles, fixtures, scratch data, route configs, run instructions. Production source may be referenced in read-only mode for context. Never import it.
2. **Zero production impact.** Do not modify or import production source/modules, do not edit root manifests, task runners, routes, configs, or shared components, and do not use real authentication or mutate real data. Use prototype-local dependencies and local copies or stubs.
3. **Document one run command.** Document a single command in `.agents/prototype/<name>/` that starts the prototype from that directory without project-level changes.
4. **No persistence by default.** Keep state in memory. If the question explicitly concerns persistence, use a clearly named, disposable scratch database or local file inside `.agents/prototype/<name>/`.
5. **Skip polish.** No tests, no error handling beyond what is needed to make the prototype *runnable*, no abstractions. The point is learning something quickly.
6. **Expose state.** Output or render all relevant state after every action (logic) or upon every variant switch (UI) so changes are visible.
7. **Record, do not implement.** Once real-time HITL exchange validates the decision, capture the entire prototype directory as a **primary source** on a throwaway branch off main and record the verdict. Do not implement in production. That is a separate follow-up ticket.

## Reconnecting with the Map

A prototype is an **asset**, not the answer itself. Link to it from the ticket. Do not paste into the body.

- Commit `.agents/prototype/<name>/` as a **primary source** on a throwaway branch off main, leaving a context pointer to that branch on the ticket.
- Post the verdict — which variant won and why — as a **resolution comment** on the ticket, close the ticket, and add a one-line gist with a link to the map's **Decisions so far**. Do not fold the prototype into production during this resolution. Production implementation belongs on a separate follow-up ticket.
- The map records the decision; the branch preserves the prototype as a primary source.
