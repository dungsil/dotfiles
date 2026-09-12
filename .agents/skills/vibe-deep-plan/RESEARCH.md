# Research Tickets

Research tickets involve two actors: **AFK Research**, which returns findings citing sources, and the **calling session**, which owns all writes, saved records, pointers, and resolutions.

## AFK Research

- Investigates ticket questions using primary sources where available — official docs, source code, specifications, public read-only APIs — citing sources for every meaningful conclusion.
- May inspect local read-only resources and return findings, constraints, unknowns, and safe human-executable checklists for external work.
- Must not write files, branches, commits, artifacts, maps, tickets, or comments; must not use credentials, push, publish, or cause any external side effects. Does not resolve tickets or speak on behalf of humans.

## Calling Session Persistence

The calling session preserves all returned findings before charting or work sessions end. Storage varies by tracker.

### Local Markdown

The research ticket and canonical findings record reside in a single file:

```
.agents/plans/<effort>/research/<ticket-stem>.md
```

The file contains `Type: 조사`, `Status`, question, and source-aware full findings under `## Research`. The final decision is added under `## Answer`. Human-driven interview records use a separate `.agents/plans/<effort>/interviews/<ticket-stem>.md` directory.

In local Markdown, do not create separate `.agents/research/` notes or pointer comments. Keep repository ignore policies intact. Do not create, checkout, commit, or push research-only branches. These records are local handoff artifacts, not shippable changes.

### Hosted or Other External Issue Trackers

The calling session saves full findings on the same research ticket. The default is a single dedicated issue comment or note, prefixed with a stable marker so future sessions can find it even if titles change:

```
<!-- vibe-deep-plan research: <map-identity>/<ticket-identity> -->
```

If provider comment limits are too small, preserve full findings across ordered comments (`Research record 1/N`, `2/N`...). If unable to fit in comments, use a persistent artifact owned by the tracker or repository (snippets, wiki pages, attachments, or equivalents) and link its URL in a ticket comment. Never truncate findings or leave them only in unpushed local files. Record the persistent location as follows:

```
Research record: <comment, note, or artifact URL>
```

Hosted persistence has no `Branch`, `Commit`, or `Path` pointers, and never creates `research/...` branches. If no persistent external surface exists, leave the ticket claimed and report save failure without discarding findings.

## Charting and Reuse

When charting initiates AFK research, use the configured tracker's claim operation. In local Markdown, change the record to `Status: claimed` before dispatch, await findings, and save using the local rules above. Revert to `Status: open` after writing the record. In hosted trackers, assign or claim the issue before dispatch, await findings, save using the hosted rules above, and unassign/release only this session's claim after record and pointer are in place. If saving fails or a session passes an incomplete handoff, leave local Markdown records in `Status: claimed` and hosted issues assigned/open, reporting save failure.

Charting leaves tickets open. In local Markdown, successfully saved research records have `Status: open`; in hosted trackers, issues remain open after claim release. Charting never adds map gists. If saving fails, leave local Markdown records `Status: claimed` and hosted issues assigned/open so findings are not lost.

Subsequent sessions inspect canonical local research records or hosted comments/artifacts before researching anew. Reuse if belonging to this ticket; recover hosted pointers where possible. Re-run read-only research only when canonical records are missing, unusable, or belong to a different ticket.

## Resolution and Authority

Once a decision is reached, record `Decision: <decision>` and complete tracker-specific resolution. In local Markdown, append the canonical research record path to the final `## Answer` and set `Status: resolved`. In hosted trackers, append the hosted research record URL to the resolution comment or note, and close the issue if the tracker supports close operations. Finally, add only a one-line gist to the map. Research records or pointers alone are not resolutions.

There are no research branches to push or publish. External comments or persistent artifacts must adhere to configured tracker workflows and approval rules.

Never store raw credential values in findings, branches, tickets, maps, comments, commands, or logs. Record only credential types and secure vault references.
