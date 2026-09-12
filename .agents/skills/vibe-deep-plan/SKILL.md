---
name: vibe-deep-plan
description: Charts large blocks of work too big for a single agent session into a shared map of decision tickets on the repository issue tracker, then resolves them one by one until the path to the destination is clear. Use when work is too large to plan in one session, or when asked to chart, expand, or advance a decision map.
disable-model-invocation: true
---

# Charting a Decision Map

A loose idea has arrived — too large for a single agent session, shrouded in fog. The path from here to the **Destination** is not yet visible. Wayfinding is not rushing toward the destination; it is finding the path. This skill charts the path as a **shared map** on the repository issue tracker, then works through its **decision tickets** — questions whose resolution is a decision, not an execution build step — one at a time until the path is clear.

The destination varies by effort, and naming it is the first act of charting — it shapes every ticket. It may be a spec to hand off for iteration, decisions to lock before planning begins, or an in-place change like a data structure migration. Maps are domain-agnostic — engineering tasks, course content, or whatever fits the shape.

## Plan, Do Not Build

This skill is fundamentally **planning**: each ticket resolves a decision, and the map ends when the path is clear — when nothing remains to decide before someone goes and does the work. The urge to simply do the work is usually the signal that you have reached the end of the map and it is time to hand off. An effort may override this in its **Notes** — pulling execution into the map — but without that, produce decisions, not deliverables.

### Hand Off When Map Ends — Do Not Build

A map is finished when there are no open tickets and **Not yet specified** is empty. Hand off to the **spec** phase of `/vibe-plan`. If using local Markdown, pass the clean `map.md` path. `/vibe-plan` reuses the parent `.agents/plans/<effort>/` directory, writing `spec.md` there in Stage 2 and implementation tickets under `issues/` in the same directory in Stage 3. If using GitHub, GitLab, or another hosted tracker, pass the map URL or number. `/vibe-plan` reads the map and all linked closed tickets. It first fetches each linked decision's question and final answer: `## Question` and `## Answer` in local Markdown, or the issue body/question and final resolution comment or note in hosted trackers. It follows raw research, comments, attachments, or prototype artifacts only when the final answer references them or the spec requires evidence. The map is an index, not a storehouse. Its Destination and Decisions-so-far plus linked decisions form the handoff input, leaving nothing left to interview.

Going straight to `/vibe-implement` skips that synthesis and discards linked details. Use that shortcut only when the effort has truly reduced to a single ticket's worth of work.

### When a Session Fills Up Mid-Ticket

That is a different exit: the ticket is not resolved, but space has run out. Leave the ticket in the **claimed** state, hand off the thread (see `/vibe-handoff`), and continue in a new session. Never post a half-baked answer as a resolution comment.

## Reference by Name

Every map and ticket has a **name**. On hosted trackers, the name is the issue title. In local Markdown, the map is `map.md` and the decision record filename/path is its identity. Refer to them by name in all human-readable contexts — narrative prose and the map's Decisions-so-far. Never refer to them by bare id, number, or slug alone. Hosted ids/URLs and local paths may still be used within names or links.

## The Map

On a hosted tracker, the map is a single issue labeled `상태:초안` and `유형:계획`, and its tickets are child issues. In local Markdown, the canonical map is `.agents/plans/<effort>/map.md`, and its tickets are typed decision records under `research/`, `interviews/`, `prototypes/`, or `tasks/`.

The map is an **index**, not a storehouse. It lists decisions made and points to the tickets containing their details. A decision lives in exactly one place — its ticket — so the map summarizes and links without duplicating decisions.

`상태:초안` and hosted triage statuses share the same status axis and are therefore **mutually exclusive**. `유형:계획` is on a separate type axis, so the map carries it together with `상태:초안`. A hosted map and its decision issues never carry triage statuses. Local maps have no hosted labels. Local Markdown decision records use a separate `Status: open` → `claimed` → `open`/`resolved` lifecycle. Triage statuses apply again only when the map finishes and `/vibe-plan` posts implementation tickets.

**Where the map, child tickets, blocking, and frontier queries physically live depends on the tracker.** An issue tracker should have been provided — run `/vibe-init` if missing. Refer to the tracker document's "Wayfinding operations" section for how *this* repository represents them. Default to the local Markdown tracker if no tracker is provided.

### Map Body

A low-resolution view of the entire map, loaded once per session. Open tickets are **not listed** — they are open child issues found via query.

```markdown
## Destination

<What reaching the end of this map looks like — the spec, decision, or change this effort seeks. One or two lines. Every session aligns to this before picking a ticket.>

## Notes

<Domain; skills all sessions should reference; evergreen preferences for this effort>

## Decisions so far

<!-- Index — one line per closed ticket: enough to assess relevance, expanding the link leads to full details in the ticket -->

- [<closed ticket title>](link) — <one-line summary of answer>

## Not yet specified

<!-- See "Fog of War": in-scope fog that cannot yet be turned into tickets. Graduates as the frontier advances -->

## Out of scope

<!-- See "Out of scope": work excluded beyond the destination. Closed, never graduates -->
```

### Tickets

Each ticket is a child decision item of the map. Hosted trackers represent them through the host's **native child-issue relationship** with tracker ids. A `Parent map` line, task list, or link in the body does not replace that relationship when the host supports child issues. Missing relationship support in a high-level tool does not mean the host lacks the feature: use the lower-level API or CLI allowed by the tracker document, then read the relationship back immediately. If the write or verification cannot be performed, do not report charting as complete; report the created-but-unlinked issue ids and the blocked operation. Local Markdown stores them as typed decision records whose path is their identity. The body is a question, sized for a single 100K token agent session:

```markdown
## Question

<The decision or investigation this ticket resolves>
```

Hosted tickets carry a single `유형:` label — `유형:조사`, `유형:프로토타입`, `유형:인터뷰`, or `유형:작업`. Local Markdown records have a matching `Type:` line (see [Ticket Types](#ticket-types)). Resolve strings from `docs/agents/triage-labels.md`; never invent English stand-ins such as `type:research`.

Before starting work, a session **claims** the ticket so concurrent sessions skip it. Use the configured tracker's claim operation: hosted trackers assign the ticket to the acting developer. Local Markdown initializes unclaimed records with `Status: open`, updates to `Status: claimed` before work, and returns to `Status: open` after successful charting save. The final answer updates local records to `Status: resolved`. Incomplete handoffs or failed saves remain `claimed`. Local Markdown never uses an `Assignee:` field.

Blocking uses the tracker's **native** dependency relations — essential because it renders the frontier *visually* in the tracker UI so humans can see what is ready without opening the map. Only trackers without native blocking fall back to body conventions. A ticket is **unblocked** when all tickets blocking it are closed. The **frontier** consists of open, unblocked, unclaimed children — the edge of what is known.

Questions remain in the ticket body. Research persistence follows [RESEARCH.md](RESEARCH.md).
Research persistence varies by tracker: local Markdown places each research ticket and its full findings in `.agents/plans/<effort>/research/<ticket-stem>.md`. Interviews, prototypes, and task records reside under `.agents/plans/<effort>/interviews/<ticket-stem>.md`, `.agents/plans/<effort>/prototypes/<ticket-stem>.md`, and `.agents/plans/<effort>/tasks/<ticket-stem>.md`. `.agents/plans/<effort>/issues/` is reserved for implementation tickets posted by `/vibe-plan`. Hosted trackers place full findings in ticket comments or notes, or linked persistent snippets, wiki pages, attachments, or equivalents. No tracker creates research-only branches.

## Ticket Types

Every ticket is either **HITL** — human in the loop, working *with* a human who speaks for themselves — or **AFK**, driven by the agent alone. On AFK research tickets, only background research is delegated: subagents may inspect documentation, public or read-only APIs, and local resources, but must not write files, publish artifacts or branches, modify maps or tickets, use credentials, or cause **external side effects**. The calling session receives findings with primary source citations and stores them under [RESEARCH.md](RESEARCH.md). HITL tickets resolve only through real-time exchange. The agent never speaks on behalf of the human (a grilling agent answering its own questions violates this).

- **Research** (AFK Research): Read-only subagent returns findings with primary source citations and open unknowns; calling session saves them under [RESEARCH.md](RESEARCH.md). Used when knowledge outside the current working directory is needed.
- **Prototype** (HITL): Builds a cheap, rough, concrete artifact — an outline, rough draft, stub, or UI/logic code — to raise discussion fidelity for feedback. Place all artifacts under `.agents/prototype/<name>/`. Do not modify or import production source/modules, do not use real credentials or alter real data, and do not edit project-level manifests, task runners, routes, configs, or shared components. Resolved by building throwaway code — [PROTOTYPE.md](PROTOTYPE.md) for choosing branches, [PROTOTYPE-LOGIC.md](PROTOTYPE-LOGIC.md) for state/logic questions, [PROTOTYPE-UI.md](PROTOTYPE-UI.md) for "what should it look like". Link prototype as an asset. Used when "what should it look like" or "how should it behave" is the central question.
- **Grilling** (HITL): Dialogue via `/vibe-grilling` and `/vibe-modeling` skills, one question at a time. The default case.
- **Task** (HITL): Manual work that must occur before a *decision* can be made — not something to decide, prototype, or research, but blocking discussion until completed. Signing up for a service, provisioning access, or migrating data are human-involved external side effects, never AFK tasks. Provide read-only findings and a precise target-specific human checklist before requesting approval. Resolve only after authorized tasks finish. Record resulting facts needed for future tickets, recording only credential types and secure vault references.

### Human-Involved External Side Effects

**Account creation, permission changes, data movement, and credential usage** are distinct categories of human-involved **external side effects**, and are always HITL regardless of ticket type. Maps, plans, prior approvals, or broad "feel free to proceed" statements never grant blanket authority.

Before requesting approval, complete only permitted read-only research and return results alongside a numbered, target-specific checklist for human execution. Preview immediately before executing **each** category:

- Target;
- Exact action;
- Expected impact and scope; and
- Reversibility, including rollback or recovery paths.

Request and obtain separate affirmative approval explicitly naming that category before the first action. Approval for one category never authorizes another. If the target, exact action, or scope changes, preview again and re-request. Declines, ambiguities, or non-responses constitute absence of approval: retain local Markdown records in `Status: claimed` to keep them off the frontier. Leave hosted tracker issues open, assigned, and blocked. Do not append `## Answer`, post resolution comments/notes, set `Status: resolved`, close issues, update **Decisions so far**, or trigger external side effects.

Never record raw credential values in maps, tickets, comments, resolution text, command/output logs, or research artifacts. Retain only credential types and secure vault references. Credential usage still requires its own just-in-time approval.

## Fog of War

Maps are *deliberately* incomplete: do not design what cannot yet be seen. Beyond live tickets lies the **fog of war** — a dim view of decisions and research known to be coming but not yet pin-downable because they depend on open questions. Resolving a ticket clears the fog before it, graduating what can now be specified into new tickets — one by one until the path to the destination is clear and no tickets remain.

The map's **Not yet specified** section is where that dim view is captured: suspected questions, areas to revisit later. It is the undiscovered frontier toward the destination — everything here is in scope but not yet crisp enough to become a ticket. Write as loosely or thoroughly as visibility permits. It also serves as wayfinding signposts for collaborators reading where the effort is headed.

**Fog or Ticket?** The test is whether you can state the exact question right now — *not* whether you can answer it right now.

- **If the question is already crisp, it is a ticket** — even if blocked and unable to act immediately.
- **If it cannot yet be stated with such clarity, it is Not yet specified.** Do not slice fog into ticket-sized pieces in advance. It is coarser than tickets; a single chunk may graduate into multiple tickets or none at all once the frontier reaches it.

**Not yet specified** excludes what is already decided (Decisions so far), already live tickets, and out of scope (next section).

## Out of Scope

Fog gathers only toward the destination. Because the destination pins the scope, work beyond it is **out of scope** — it is not fog, and does not belong in **Not yet specified**. The map has its own **Out of scope** section: work consciously excluded from *this* effort. What belongs here is determined by scope, not clarity.

Out of scope work never graduates — the frontier stops at the destination — so it returns only if the destination is redrawn, and even then as a new effort rather than a resumption.

Marking something out of scope is a scope-defining act, not a step along the path. If an existing ticket turns out to lie beyond the destination — mistakenly scoped during charting, or revealed by a resolution — **close it** (closed tickets are unambiguously off the frontier) and add a line to the **Out of scope** section: summary, why it is out of scope, and a link to the closed ticket. It is omitted from **Decisions so far** (which records the actual path walked) — scope boundaries are not steps on that path.

## Invocation

Two modes. By default, a work session claims and resolves a single ticket. Research persistence during charting follows [RESEARCH.md](RESEARCH.md). It is a handoff record, not a resolution, and does not count against that limit. An explicit user request may continue the same charting invocation into parallel work across multiple **named, unblocked HITL** tickets. Only those named tickets join the exception; all claims, human exchanges, approvals, resolutions, and map updates still follow their standard rules.

### Charting a Map

User invokes with a loose idea.

1. **Name the Destination.** Run a `/vibe-grilling` and `/vibe-modeling` session to pin down what this map seeks — a spec, a decision, or a change. Because destination pins scope, it is established first.
2. **Chart the Frontier.** Grilling again, this time **breadth-first**: fanning out across the full space rather than drilling into any single thread, identifying open decisions and immediate first steps. **If this reveals no fog** — the path to the destination is already clear, and the entire journey fits in one session — a map is unnecessary. Stop and ask the user how they wish to proceed.
3. **Create the Map**: Hosted trackers create a map issue with `상태:초안` and `유형:계획`. Local Markdown writes `.agents/plans/<effort>/map.md` without hosted labels. Populate Destination and Notes, leave Decisions-so-far empty, and sketch fog in **Not yet specified**.
4. **Create Tickets for what can be specified now** as child tickets of the map — hosted trackers add the native child relationship in a second step requiring ids, then read the map's child list back and verify every id. An issue with only a body link or `Parent map` line is not a child ticket. If the host supports relationships but the current tool cannot write or verify them, do not treat a text fallback as success. Report any created-but-unlinked issue ids and the blocked operation, then stop. Local Markdown writes typed records in matching `research/`, `interviews/`, `prototypes/`, or `tasks/` directories. Linking organizes them into frontier and blocked items. Everything not yet specifiable remains in the fog — the **Not yet specified** section.
5. **Launch Read-Only Research Subagents.** Temporarily claim each `research` ticket before dispatch, launch AFK research in parallel, await all returns, and ensure the calling session saves each result under [RESEARCH.md](RESEARCH.md) before exit.
6. **Honor Explicit Parallel Work Requests.** If the user asks to spend waiting time on an interview or another named unblocked HITL ticket, switch that ticket to **advancing the map** and claim it before work. Multiple named HITL lanes may interleave, but each asks one question at a time, waits for the user's own answer, and never answers on the user's behalf. Do not infer this exception from idle time or add unnamed tickets.
7. **Wrap Up Charting.** Do not resolve research tickets during charting. After successful saving, hosted research issues remain open with session claim released, and local Markdown research records remain `Status: open`. Tickets lacking saved findings remain claimed for explicit handoff.

### Advancing the Map

User invokes with map path, URL, or number. Ticket is **optional** — if omitted, pick the next decision, not the user.

1. **Load Map** — low-resolution view, not all ticket bodies.
2. **Pick a Ticket.** If the user named one, use it; otherwise take the first frontier ticket in order. Read claim state before altering. Continue claims owned by this session or transferred via explicit handoff. Do not infer staleness from age, silence, or attached findings; never hijack another owner's claim. Reclaim only when the user or current owner explicitly states the previous session was abandoned. Re-read the ticket immediately to verify no newer owner or activity before updating the claim once. Ownerless local `Status: claimed` is stale only upon the same explicit instruction. Otherwise pick another frontier ticket or leave it alone.
3. **Claim Before Substantive Work**, then load full ticket body, comments, and attachments. If research, check canonical local notes or hosted comments/artifacts before re-running. If missing or unavailable, check all configured persistent locations under [RESEARCH.md](RESEARCH.md) first. Invoke skills named in `## Notes`. If the ticket will trigger external side effects, return read-only findings and a precise human checklist first, following [Human-Involved External Side Effects](#human-involved-external-side-effects) for all categories. When in doubt, use `/vibe-grilling` and `/vibe-modeling`.
4. **Record Resolution** only when the answer is complete and the ticket requires no external side effects, or all mandatory categories have been independently approved and completed. Research notes or pointers are not resolutions. Research follows [RESEARCH.md](RESEARCH.md): local Markdown adds `## Answer` and sets `Status: resolved`. Hosted trackers post a final resolution comment or note and close the issue. For other ticket types, local Markdown adds `## Answer` and sets `Status: resolved`. Hosted trackers post an answer comment and close the issue. Then add only the linked record or ticket title and a one-line gist to **Decisions so far**. If approval is declined, ambiguous, or absent, local Markdown keeps the record in `Status: claimed` to drop from the frontier. Hosted trackers leave the issue open, assigned, and blocked. Do not add `## Answer`, post resolution comments/notes, set `Status: resolved`, close the issue, update **Decisions so far**, or cause external side effects.
5. **Add newly emerged tickets** (create then link); graduate fog that the answer makes specifiable, deleting graduated chunks from **Not yet specified** so they live only as new tickets. If the answer reveals any ticket — this one or another — lies beyond the destination, **mark it out of scope** instead of resolving along the path. Update or delete tickets if decisions invalidate other parts of the map.

Users may run unblocked tickets in parallel, so expect other sessions to edit the tracker concurrently.
