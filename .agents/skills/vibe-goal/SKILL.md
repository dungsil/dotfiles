---
name: vibe-goal
description: Drives a goal through from request to review to committed code — routing to `/vibe-plan` (or `/vibe-deep-plan`) to obtain published tickets, dispatching a fresh subagent for each ticket into its own assigned branch and worktree, replaying reviewed ticket results into a single integration workspace, and safely landing only reviewed, gated results. Use when the user wants an end-to-end feature, says "do all of this", or asks to execute from planning through review in one go.
disable-model-invocation: true
metadata:
  argument-hint: "Goal — idea, request, spec, or issue reference"
---

# Driving a Goal to Completion

Execute a single goal through review to committed code in one run. This skill **orchestrates**; it does not implement directly, and does not plan directly. It may invoke or route to `/vibe-plan` and `/vibe-deep-plan`, but **does not perform planning work itself** — triage, exploration, spec drafting/editing, decomposition, ticket design, and ticket publishing are the responsibilities of those skills. Planning happens via `/vibe-plan` (or `/vibe-deep-plan` first if the effort is too large), each ticket is implemented by a **fresh subagent** running `/vibe-implement`, and the entire goal finishes with standard reviews plus a canonical requirement quality gate when `/rq` is available.

Each ticket gets its own **assigned branch and worktree** — a ticket-specific workspace isolated from all other tickets. Different tickets can run in parallel; the lifecycle of implementation → review → finding fixes → resumption for the same ticket reuses that ticket's exact assigned workspace. The goal maintains a single **integration workspace** separate from assigned workspaces: reviewed ticket results are replayed here for whole-goal verification, and ticket subagents do not commit directly to it. Resumption reuses recorded integration workspaces and each ticket's recorded assigned workspace using exact records — never opening a second one for the same goal or ticket.

This orchestrator supplies assignment records via ledger/handoff to invoke `/vibe-implement`, which executes atomically for a single ticket without branching by mode name. Direct invocations outside this orchestration execute identically. Do not infer state from current worktree path or branch name alone.

Issue trackers and triage label vocabularies must already be provided — run `/vibe-init` if `docs/agents/issue-tracker.md` is missing.

## Landing and Tracker State

`/vibe-review` is read-only: it reports findings and never alters tracker state. Review passes are not authority to close issues. Parent spec issues are read-only: never included in tracker change previews or modified. On hosted trackers, an issue that is both spec and the sole ticket is the ticket, not a parent.

The goal owns integration and final landing. Acceptance checklists and issue close are separate. For **hosted** trackers, `/vibe-implement` ticks acceptance checkboxes after a clean review and before the human merges — the orchestrator does not defer checkboxes until after merge. The orchestrator does not close issues in Stage 3. Only after authoritative proof shows the exact reviewed integrated commit SHA is on the original target branch in Stage 4 do you present an exact preview of close, status, and comments, awaiting separate explicit approval immediately before writing — declines or non-responses leave issues open. For **version-controlled local Markdown** trackers, there is nothing to preview: each ticket's checklist travels within its own implementation commit, so integration and landing move code and checklist together. In either case, the orchestrator never directly edits ticket files or adds tracker-only commits to the target branch.

## Orchestrators Do Not Plan or Write Production Code

Context is the only thing holding the goal together: the ticket graph, what has landed, and what remains. Spending this on implementation kills the run midway.

- **Never edit source files directly.** All code changes go through ticket subagents.
- **Never read full diffs.** Read subagent reports and review verdicts; open code only when adjudicating specific disagreements.
- **Stay in one context window** — from Stage 1 routing to the final ticket. If performance degrades nonetheless, hand off via `/vibe-handoff` — pass the ledger, not the history.

No exceptions. Planning stages belong to `/vibe-plan` and `/vibe-deep-plan`: route to them, let them produce tickets, and consume what they publish. If plans need changing later, route back to Stage 1 and planning skills — never modify plans directly.

## Stage 1 — Goal Routing

Read what the user brought, state entrypoint in one line, then act:

| What the user brought | Routing |
|---|---|
| Work too large for one planning session — shrouded in fog to the destination | `/vibe-deep-plan` first; once the map clears, Destination and Decisions-so-far feed into `/vibe-plan`'s **spec** stage |
| Everything else — external requests, loose ideas, concluded conversations, specs, issue references | `/vibe-plan`, which selects its own entry stage from the input |
| A set of tickets published from a previous run | Skip to **Stage 2** |

Two routing outcomes terminate runs early, representing success rather than failure:

- Triage resolves to `wontfix` or `needs-info` → Report outcome and stop. Nothing to implement.
- Triage resolves to `ready-for-human` → Report why it cannot be delegated and stop.

`/vibe-deep-plan` is a **multi-session** skill. When routing there, expect the run to end if the session fills mid-map; hand off and resume. Do not force an entire decision map and its implementation into one window.

## Stage 2 — Create or Resume Ledger and Integration Workspace

Once `/vibe-plan` publishes tickets, first establish the **canonical goal ID** — the durable identifier to which this goal's work attaches: published spec issue / path, or the same identifier recorded in the ledger by a prior run upon resumption. This ID binds the logical goal to a single integration workspace across sessions, resumptions, and handoffs; nothing else does.

### Resume or Create

Before creating anything, determine whether this is a **resumption** or a **new goal**. Resumption occurs when the user explicitly asks to continue, finish, or follow up on a previous goal run — or entry comes from a published ticket set or handoff naming a prior run. Otherwise, it is a new goal. With this determination, locate existing **workspace records** — ledger, handoff, or caller records binding the canonical goal ID to an integration workspace with recorded original target, original fixed point, integration branch, worktree path, and current owner/status. **Never match by branch name, number, slug, latest `vibe/*` branch, or similar-looking names** — a plausible name is not a match. Only an exact record authorizes reuse.

- **Exact record, no active owner, worktree exists and is clean** → Reuse that integration workspace as-is.
- **Exact record, no active owner, worktree gone but recorded integration branch exists** → Reattach worktree to same integration branch (`git worktree add <path> <recorded-branch>`); do not create new branches.
- **New goal, no matching record** → Truly a **new goal**. Record the original target branch or ref and its fixed point — the **original fixed point** held constant across the entire goal — and create a clean, goal-specific integration branch and separate worktree rooted at that exact fixed point: this is the **integration workspace**. Create it from commit objects without checking out, resetting, cleaning, stashing, staging, or altering the user's working checkout. Tracked or untracked, those changes belong to the user, even if dirty. If a clean separate worktree cannot be created, stop and report; never reuse working checkouts or shared worktrees.
- **Resumption, but matching record not found** → A resumption without records cannot safely reuse workspaces, nor should it create a new sibling integration workspace — which forks the goal into two integration lines. Stop and report absence of resumption records for this canonical goal ID; user must locate records or explicitly authorize a fresh start. Do not guess, create, or reuse.
- **Multiple candidates, active owner conflict (another run/subagent claiming recorded workspace), or branch head/cleanliness mismatching records** → Do not reuse, create sibling integration workspaces, or guess. Stop and report findings and ambiguity. User resolves conflict.

Upon reuse, the fixed point for continuous runs is the **original fixed point captured in the first run**, not the current head; Stage 4 whole-goal review still runs against that initial fixed point.

### The Ledger

Author the **ledger** — the only artifact kept in context for the remainder of the run. It is the workspace record and the live state of all tickets. Refer to tickets by title, never by number alone.

```markdown
## Goal

<One line — what "done" means for this run>

## Canonical Goal ID

<Published spec issue / path, or same identifier recorded by prior run on resume>

## Original Target

<Branch or ref selected for final landing; user checkout remains untouched>

## Original Fixed Point

<Commit SHA captured on first run via `git rev-parse HEAD`; whole-goal review runs against this>

## Integration Workspace

<Goal-specific integration branch>; <separate worktree path>; rooted at <original fixed point>; clean; owner: <this run / idle>; status: <new / resumed>

## Spec

<Published spec issue / path link>

## Tickets

| Ticket (Canonical ID) | Assigned Branch / Worktree | Blockers | Status | Wave Base (Integration head at dispatch) | Owner / Status | Returned Reviewed SHA | Verification | Replay Proof |
|---|---|---|---|---|---|---|---|---|
| <Title> (link) | vibe/<id> ; .agents/worktrees/<id> | — | pending | — | — / idle | — | — | — |
| <Title> (link) | vibe/<id> ; .agents/worktrees/<id> | <Title> | running | <base SHA> | subagent / active | <reviewed SHA> | <verdict> | — |
| <Title> (link) | vibe/<id> ; .agents/worktrees/<id> | <Title> | integrated | <base SHA> | — / idle | <reviewed SHA> | <verdict> | Replayed in integration workspace @ <head> |
```

Status progresses `pending` → `running` → `integrated` → `landed`, or `blocked` / `failed`. `integrated` means reviewed ticket results were replayed onto integration head and passed ticket-attribution verification on that head; unblocks dependent tickets. `landed` is recorded only after Stage 4 proves reviewed integrated results exist on the original target branch. Ledger status is not authority to close issues.

Record original fixed point and clean integration workspace before the first ticket subagent launches. On resume, original fixed point remains the initial run's value, not current head.

Show ledger to user and confirm execution order before dispatching anything.

## Stage 3 — Dispatch Frontier in Parallel, Replay Results into Integration Workspace

The **frontier** is all tickets whose blockers are all `integrated` or `landed`. Dispatch the **entire frontier at once** — all ready tickets in parallel, each into its own assigned branch and worktree. Never serialize ready tickets; by definition, frontier tickets are independent. Within the frontier, different tickets run concurrently in separate assigned workspaces; tickets depending on others wait until blockers become `integrated` before joining the next wave.

### Dispatch

For each ready ticket on the frontier, create a ticket-specific **assigned workspace**: dedicated branch and worktree rooted at integration head. Record that head as the ticket's **wave base** — the anchor against which reviews run. Create each assigned workspace from commit objects without checking out, resetting, cleaning, stashing, or altering working checkouts or integration workspaces. Record assigned branch, worktree path, wave base, owner, and state in ledger before subagents launch. Dispatch a **fresh subagent** for each ticket simultaneously. Each receives and receives only:

- Ticket reference and full body (fetched from tracker — never make subagents guess where it lives).
- Spec link for readable context if needed.
- Assigned workspace: ticket's assigned branch and worktree, plus exact wave base SHA.
- Instruction: **Run `/vibe-implement` atomically on this ticket in the assigned workspace, and do nothing else.**
- Boundaries: Implement **only** this ticket. Report out-of-scope issues without fixing.
- Linearity rules: Commit **directly to assigned ticket branch** in worktree — stay linear from wave base, never merge original target or integration branch, create no extra branches or worktrees, and report if base shifted instead of rebasing/merging.

Each ledger ticket holds **canonical ticket ID**, **assigned branch and worktree**, **wave base** (integration head at dispatch), **owner/status**, and **status** (`pending` → `running` → `integrated`/`failed`).

**Retries of the same ticket** — fixing review findings or corrective redispatch — reuse that ticket's **exact assigned workspace**: same assigned branch and worktree recorded for that canonical ticket ID. Fresh subagents are permitted; new branches, worktrees, or ticket IDs are prohibited. If an assigned workspace is stale, dirty, or head mismatches recorded state, that is a stop-and-report condition, not a reset shortcut; preserve the exact workspace and surface mismatches for explicit resolution. Never guess workspaces by name, slug, number, or latest `vibe/*` branch; reuse solely via exact recorded records. Truly **new** tickets (split slices with own canonical IDs, or Stage 4 fix tickets) alone receive new assigned workspaces and ledger entries.

All goal-dispatched implementers adhere to this **shared return contract**: commit directly to assigned ticket branch in worktree atomically, maintain linearity from wave base, and return assigned branch name, exact wave base SHA, exact reviewed head SHA, verification proof, and read-only `/vibe-review` verdict. Must not merge target or integration branches into ticket branch, create additional branches/worktrees, alter working checkouts or integration workspaces, clean/delete assigned workspaces, or close hosted issues — they may tick acceptance checkboxes per `/vibe-implement` tracker updates; for version-controlled local Markdown trackers, ticket files are branch content belonging in the same commit, not separate commits. If wave base moved, report instead of rebasing or merging. Missing branch, head SHA, wave base SHA, verification records, or review verdicts constitute incomplete returns, not completed tickets.

Do not paste conversations, other tickets, or planning history. A ticket unintelligible from its own body is a planning defect — route back to planning skills to fix rather than compensating in prompts.

### Verify Each Return and Replay into Integration Workspace

A subagent's `completed` is a claim, not a fact. Review passes are reporting evidence, not tracker authorization. To accept returned results, verify cheaply and independently:

- Assigned ticket branch exists, head SHA matches returned reviewed SHA, and is based on returned wave base SHA — matching the base recorded at dispatch.
- Acceptance criteria are met — per subagent verification proof and read-only `/vibe-review` verdict.
- Review findings, if any, are resolved or explicitly accepted by user.

Upon passing verification, **replay** reviewed ticket results into the integration workspace, **one at a time**: verify integration workspace is clean and head matches expected integration head, rebase or cherry-pick reviewed ticket commits onto that head, proceed fast-forward only (`--ff-only`), and verify patch-equivalent containment — reviewed ticket commits exist intact on new integration head without additions, omissions, or mutations. Then **re-run ticket's own verification on new integration head**: execute test/verification commands from ticket at that head in integration workspace and ensure they still pass — patches passing in isolation may break after they are combined. Replay is accepted only when patch containment and re-execution both pass. Record new integration head as replay proof. Unrelated dirty states, unexpected files, or integration head mutations require a safe stop: report and do not clean, reset, stash, delete, or touch working checkouts, integration workspaces, or assigned workspaces. If verification fails, ticket is not `integrated`; preserve both workspaces and report blockers.

After successful replay, record ticket's returned reviewed SHA, verification, and replay proof in ledger, mark owner idle, and set ticket to `integrated`. **Retain assigned ticket branch and worktree** until goal lands: same-ticket review fixes or resumptions reattach by record to that exact branch and worktree, not a new one. `integrated` is integration head proof, not target landing proof. The orchestrator does not close issues during Stage 3; hosted acceptance checkboxes are already ticked by implementers. Version-controlled local Markdown ticket files arrive within ticket commits, not via orchestrator edits.

### When a Ticket Fails

Diagnose which case applies:

- **Ticket too large for single context** — Route back to planning skills to split and publish as blocked slices; published slices enter ledger as new tickets, each with own assigned workspace. Slices execute next in dependency order.
- **Insufficient ticket specification** — Halt implementation and route back to `/vibe-plan` for missing decisions and ticket edits. `/vibe-goal` does not interrogate users or edit tickets directly; retry only after planning skills republish.
- **Genuinely broken codebase** — Report blockers to `/vibe-plan`; only blocker tickets published by planning skills enter ledger to execute in assigned workspaces via `/vibe-debug`.
- **Incorrect plan** — Stop execution, report, return to Stage 1: planning skills own corrections, never edit plans directly. Downstream tickets built on wrong plans waste more than restarts.

Failures or review findings staying within the same ticket execute in that ticket's **same assigned workspace** — retries of the same canonical ticket, not new workspaces, branches, or ticket IDs. New Stage 4 fix tickets must first be designed and published by `/vibe-plan`; only then can `/vibe-goal` add canonical IDs and assigned workspaces. If assigned workspaces are dirty or state is ambiguous, stop, preserve, and report; do not reset or guess.

## Stage 4 — Review, Gate, and Safely Land Integrated Results

When all tickets are `integrated` with no `pending`, `running`, `blocked`, or `failed` remaining, record integration branch and exact current head SHA as review candidates. Confirm integration workspace is clean; unexplained dirty states or files halt execution, preserving branch and SHA.

1. **Full suite once.** Run type checks, tests, and all repo checks across the recorded candidate in the integration workspace — not per ticket and not in user checkout.
2. **Separated Review Axes.** Run `/vibe-review` from Stage 2 fixed point to recorded integration branch and commit. Per-ticket reviews saw single slices; this review examines the space between them, where interesting findings reside. Always run Standards. Also run Risk when the goal touched security, authentication, permissions, persistence, transactions, or external integrations, or requested a risk audit. If `/rq` will run in Step 3, skip Spec because the gate handles it. If `/rq` is unavailable, retain Spec — high-risk goals run Standards + Spec + Risk; low-risk goals run Standards + Spec.
3. **Spec Verdict.** If the `/rq` skill is available in this session, run it with Stage 2 fixed point as change boundary, recorded integration results as head, scoped to implementation domains (`CODE`, plus `MIGRATION` if needed). Source requirements represent the goal's **definition of done** — acceptance criteria actually promised by execution (spec acceptance criteria, or ledger goal line if absent from spec). User stories beyond that remain tracking rows and are out of scope; gating every story in large specs duplicates per-ticket reviews. Gate returns per-item status and aggregate `PASS` / `WARNING` / `NEEDS_REVIEW` / `FAIL`.
   - Default to gate's `LIGHT` tier. Use `HEAVY` only when the goal touched domains consistently requiring heavy tiers — security, auth, permissions, persistence, transactions, external integrations. These are also Risk-enabling signals, but they do not make direct `/vibe-review` invoke `/rq` automatically.
   - Keep operational, deployment, and data obligations as **separate gates**. They do not downgrade implementation verdicts and do not run here unless requested.
   If `/rq` is not available, **skip this step**. State that the formal spec gate was skipped. Do not invent `PASS`/`FAIL`. Missing `/rq` does not by itself make landing unsafe.
4. **Adjudicate.** Present Standards findings, Risk findings when enabled, and gate reports when run side by side without merging. Items marked `not satisfied` or `unknown` by a gate that ran, plus Standards or Risk findings the user wants resolved, become **remediations**: route back to planning skills to design and publish new tickets, which flow through Stage 3 — never patch inline directly. Remediation tickets are genuinely new canonical tickets with own IDs and assigned workspaces, dispatched and replayed like any other ticket. After those tickets integrate, re-run the gate if it ran, otherwise re-run `/vibe-review`; goals never close on `FAIL`.
5. **Land only when safe.** Use clean, isolated landing contexts; never checkout, reset, clean, stash, or merge in user working checkout. Land on original target **fast-forward only** (`--ff-only`), carrying exact reviewed integrated commits. If target shifted from recorded fixed point, rebase integration branch onto current target head, re-run Stage 4 full suite on new candidate, record new candidate SHA, then fast-forward. Never create merge commits on target, force-push, or reset/rewrite target. If workspace dirtiness, unexpected files, unclear conflicts, failed re-runs, or missing landing proofs make landing unsafe, do not land. Preserve reviewed integration branch and SHA, report, and leave tracker state untouched. Resolve clearly intended landing conflicts by staging explicit, intended conflict paths only — never whole-worktree staging, user files, secrets, or unexpected files.
6. **Seek close approval after proving landing.** Record affected tickets as `landed` only after authoritative proof shows exact reviewed integrated commit SHA is on original target branch. For version-controlled local Markdown trackers, landing already carried checked checklists so there is nothing to preview or write — never add tracker-only commits to target. For hosted trackers, acceptance checkboxes were already ticked at implementation disposition. Display proposed close, status, and comments for each ticket; exclude parent spec issues (do not exclude an issue that is both spec and the sole ticket). Await separate explicit approval before applying preview alone. Declines or non-responses leave issues open.
7. **Report.** Goal, landed tickets with links, integration branch and reviewed commit, final landing proof, overall gate status if a gate ran (otherwise that it was skipped), Standards findings, Risk findings when enabled, and intentional open items.

Never close, modify, or include parent spec issues in tracker change previews, even after landing proof and approval.

## Execution Completion — Exactly One Surviving Artifact

The sole final landing/publishing target is the **goal integrated result** — reviewed integrated commit on the original target branch. Assigned ticket branches are caller-owned ephemeral scaffolding reused across ticket implementation → review → fix → resume, never standalone publishing targets: never open per-ticket PRs or MRs on hosted trackers. After final reporting, execution leaves **exactly one surviving artifact**, cleaned up in safe order — worktree first, branch second.

- **With landing proof** — Survivor is the original target branch. Clean up ticket assigned artifacts and integration workspace created by this run: for each, remove worktree first via `git worktree remove <path>`, then delete branch via `git branch -D`. Leave only original target.
- **Without landing proof** (landing unsafe or unapproved) — Survivor is reviewed integration branch and at most its own worktree. Clean up integrated ticket assigned artifacts only when patch-equivalent containment is proven in integration survivor **and** no longer needed for same-ticket review fixes or resumption; if either is unclear, preserve and report as named exceptions. Never force-delete branches without landing proof.

Always remove worktree before deleting branch — branches checked out in active worktrees cannot be deleted while worktrees exist, causing failures if attempted in reverse order. Never delete or alter user-owned or unrelated branches/worktrees, and never clean, reset, or stash them. If execution halts on blockers, preserve affected artifacts and report. Assigned workspaces are retained during same-ticket review/fixes and resumption (Stage 3), not deleted until goal lands.
