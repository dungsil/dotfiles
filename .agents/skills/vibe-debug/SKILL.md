---
name: vibe-debug
description: Diagnostic loop for difficult bugs and performance regressions. Use when the user says "diagnose"/"debug" or reports that something is broken.
---

# Vibe Debug

Rules for difficult bugs. Steps are skipped only with explicit justification.

When exploring the codebase, read `CONTEXT.md` (if present) to build a clear model of relevant modules, and check ADRs for the area you intend to modify.

## Intent and Authority Boundary

Classify the requested action before starting the loop:

- **Remediation mode** applies only when the user explicitly requests fixing, repairing, modifying, or restoring (including unambiguous equivalents). Allows permanent product changes and regression test modifications. Follow all steps below.
- **Diagnostic-only mode** applies to requests solely for diagnosing, debugging, investigating, or determining root causes, and is the default for ambiguous requests. Never infer a fix from bug reports, urgency, or requests to continue.

Diagnostic-only mode stays within the **authority boundary**: read-only inspection of source code, configuration, history, and read-only runtime observations are permitted, but permanent modifications to products, tests, configurations, or artifacts are not.

If a diagnostic-only task requires temporary instrumentation, a one-off reproduction, a prototype/harness, or a failing test:

1. Before writing anything, preview the exact changes to be made in an isolated workspace: paths, diffs or full contents, purpose, and a cleanup plan specifying all artifacts to be removed.
2. Request and await explicit approval. General diagnosis requests, silence, or rejections are not approvals.
3. Only after approval, perform the temporary writes in an **isolated workspace**, never in the user's working checkout. One-off reproductions, prototypes, harnesses, and all their local source files, dependency manifests/lockfiles, fixtures, scratch data, route configs, execution metadata, and run instructions must reside under `.agents/prototype/<name>/` inside the approved isolated workspace. You may inspect production source in read-only mode, but must not import or modify production source, nor edit project root manifests, task runners, routes, configs, or shared components. This location rule applies only to prototype-like artifacts; standard permanent regression tests and debug scripts retain their normal locations. Remove all approved artifacts before reporting; do not retain them as product or test changes.

## Phase 1 — Build the Feedback Loop

**This is the core.** Everything else is mechanical. If you have a tight pass/fail signal on the bug — a signal that turns red on *this* bug — you can find the root cause; bisection, hypothesis testing, and instrumentation merely consume it. Without a signal, staring at the code will not solve the issue.

Invest extraordinary effort here. **Be aggressive. Be creative. Do not give up.**

### How to Build a Loop — Try in Roughly This Order

1. **Failing test** at whatever boundary reaches the bug — unit, integration, or e2e.
2. **Curl / HTTP script** against a running development server.
3. **CLI invocation** with fixture input, diffing stdout against a known good snapshot.
4. **Headless browser script** (Playwright / Puppeteer) — drive the UI, verify DOM/console/network.
5. **Replay captured trace.** Save actual network requests / payloads / event logs to disk; replay against an isolated code path.
6. **One-off harness.** In diagnostic-only mode, treat this as a one-off prototype: after obtaining required approval, place it and all local source, dependency manifests/lockfiles, fixtures, scratch data, route configs, execution metadata, and run instructions under `.agents/prototype/<name>/` in the approved isolated workspace; production source may be inspected in read-only mode, but do not import or modify it, nor edit project root manifests, task runners, routes, configs, or shared components. Spin up a minimal subset of the system (a single service, mocked dependencies) to execute the buggy code path via a single function call.
7. **Property / fuzz loop.** If the bug is "intermittently incorrect output", run 1000 random inputs and search for failure modes.
8. **Bisection harness.** If the bug appeared between two known states (commits, datasets, versions), automate "boot state X, check, repeat" to enable `git bisect run`.
9. **Differential loop.** Run the same input against the old and new version (or two configurations) and diff the outputs.
10. **HITL bash script.** Last resort. If a human must click, drive *them* using `scripts/hitl-loop.template.sh` so the loop remains structured. Captured output feeds back to you.

In diagnostic-only mode, construct the loop using existing tests, scripts, commands, and read-only observations. Do not create or modify tests, harnesses, traces, scripts, instrumentation, configuration, or product code unless explicit temporary write approval has been granted. All commands must avoid permanent product state changes.

Building the right feedback loop solves 90% of the bug.

### Polish the Loop

Treat the loop like a product. Once you have *a* loop, **polish it**:

- Can it run faster? (Cache configuration, skip irrelevant initialization, narrow test scope.)
- Can the signal be sharpened? (Verify the specific symptom, not just "didn't crash".)
- Can it be made more deterministic? (Freeze time, seed RNG, isolate filesystem, freeze network.)

A flaky loop taking 30 seconds is barely better than no loop; a 2-second deterministic loop is tight — a debugging superpower.

### Non-Deterministic Bugs

The goal is not a clean reproduction, but a **higher reproduction rate**. Repeat triggers 100×, parallelize, add stress, narrow timing windows, inject sleep. A bug with a 50% occurrence rate is debuggable; a 1% rate is not — keep raising the reproduction rate until it becomes debuggable.

### When a Loop Really Cannot Be Built

Stop explicitly and state so. List what was attempted. Ask the user for (a) access to a reproducing environment, (b) captured artifacts (HAR files, log dumps, core dumps, timestamped screen recordings), or (c) explicit approval after previewing exact isolated workspace temporary diagnostic changes and cleanup. Do **not** proceed to hypothesis generation without a loop.

### Completion Criteria — A Tight Red-Capable Loop

Phase 1 is complete when the loop is **tight** and **red-capable**: you can state **a single command** — script path, test invocation, curl — that has **already been run at least once** (paste invocation and output), and that is:

- [ ] **Red-capable** — Drives the actual bug code path and verifies the **user's exact symptom**, so it turns red on this bug and green when fixed. Not "runs without error" — it must be able to *catch this specific bug*.
- [ ] **Deterministic** — Yields the same verdict on every run (for flaky bugs: a consistently high reproduction rate as described above).
- [ ] **Fast** — Seconds, not minutes.
- [ ] **Agent-executable** — Can run unattended; humans remain in the loop only via `scripts/hitl-loop.template.sh`.

If you are reading code and forming theories before this command exists, **stop — jumping straight to hypotheses is the exact failure mode this skill is designed to prevent.** Without a red-capable command, Phase 2 does not exist.

## Phase 2 — Reproduce + Minimize

Run the loop. Watch it turn red — the bug appears.

Verify:

- [ ] The loop produces the failure mode described by the **user** — not a different failure nearby. Wrong bug = wrong fix.
- [ ] Reproducible across multiple runs (or, for non-deterministic bugs, a high enough reproduction rate to debug).
- [ ] Captured the exact symptom (error message, wrong output, slow timing) so later phases can verify the fix actually resolves it.

### Minimize

Once red, reduce the reproduction to the **smallest scenario that remains red**. Strip inputs, callers, configs, data, and steps **one at a time**, re-running the loop after each cut — retain only what is essential for the failure.

Why bother: Minimal reproduction shrinks the hypothesis space in Phase 3 (fewer suspect components remain) and becomes a clean regression test in Phase 5.

Complete when **every remaining element is essential** — removing any one of them turns the loop green.

Do not proceed until you have reproduced **and** minimized.

## Phase 3 — Hypothesize

Form **3–5 ranked hypotheses** before testing any of them. Generating a single hypothesis anchors you to the first plausible thought.

Each hypothesis must be **falsifiable**: state the prediction it makes.

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make the bug worse."

If you cannot state a prediction, the hypothesis is mere intuition — discard or sharpen it.

**Show the ranked list to the user before testing.** They often possess domain knowledge that immediately reshuffles rankings ("we just deployed a change to #3") or already rules out hypotheses. A cheap checkpoint, a huge time saver. Do not get blocked here — if the user is away, proceed with your own rankings.

## Phase 4 — Instrument

Each probe must map to a specific prediction from Phase 3. **Vary only one variable at a time.**

Tool preferences:

1. **Debugger / REPL read-only inspection** if supported by the environment. One breakpoint is worth ten logs.
2. **Targeted logs** at boundaries that differentiate hypotheses.
3. Do not "log everything and grep".

In diagnostic-only mode, begin with debugger/REPL inspection and existing observational data. Targeted logs or other temporary writes are permitted only after prior preview and approval, and must be removed from the isolated workspace before reporting.

Tag **every debug log** with a unique prefix, e.g., `[DEBUG-a4f2]`. Final cleanup becomes a single grep. Untagged logs linger; tagged logs get removed cleanly.

**Performance branch.** For performance regressions, logs are usually misleading. Instead: establish baseline measurements (timing harness, `performance.now()`, profiler, query plans), then bisect. Measure first, fix second.

## Diagnostic-Only Conclusion

Once the root cause is confirmed, stop here in diagnostic-only mode; do not enter the remediation phase. Report:

- Confirmed root cause, and why the evidence establishes it rather than merely suggesting a theory.
- Minimal reproduction command and observed results, or exact reproduction limits, attempted steps, and missing access/artifacts.
- Collected evidence: red-loop output, read-only debugger values, existing logs, source facts, or measurements.
- Smallest proposed fix and why it addresses the root cause. Propose; do not implement.
- When approved temporary writes were used, confirm that all artifacts have been removed prior to this report.

If evidence does not confirm the root cause or a red-capable command cannot be constructed, report a bounded diagnosis instead of elevating a theory to a confirmed cause or applying a fix.

## Phase 5 — Remediation: Fix + Regression Test

Execute this phase only in remediation mode. Diagnostic-only reporting ends above.

Write a regression test **before** fixing — only when the **correct test boundary** exists for it.

The correct boundary means the test exercises the **actual bug pattern** occurring at the call site. If the available boundary is too shallow (a single-caller test when the bug requires multiple callers, a unit test that cannot reproduce the chain causing the bug), a regression test there provides false confidence.

**If there is no proper boundary, that is a finding in itself.** Note it down. The codebase structure prevents locking down the bug. Flag this for subsequent steps.

If a proper boundary exists:

1. Turn the minimized reproduction into a failing test at that boundary.
2. Observe the failure.
3. Apply the smallest fix that addresses the confirmed cause; do not refactor adjacent code.
4. Observe the pass.
5. Re-run the Phase 1 feedback loop on the original (non-minimized) scenario.

## Phase 6 — Fix Cleanup + Post-Mortem

Execute this phase only in remediation mode. In diagnostic-only mode, the sole cleanup is removing all approved temporary diagnostic artifacts, including prototypes under `.agents/prototype/<name>/`, prior to reporting.

Mandatory before declaring completion:

- [ ] Original reproduction no longer reproduces (re-run Phase 1 loop)
- [ ] Regression test passes (or lack of a test boundary is documented)
- [ ] All `[DEBUG-...]` instrumentation removed (`grep` for prefix)
- [ ] One-off prototypes deleted, or preserved only under `.agents/prototype/<name>/`
- [ ] Confirmed hypothesis stated in commit / PR message — so the next debugger can learn

**And ask: What could have prevented this bug?** If the answer involves structural changes (lack of a good test boundary, tangled callers, hidden coupling), hand off with specific details to the `/vibe-refactor` skill. Make recommendations **after** the fix lands, not beforehand — you possess far more information now than when you started.
