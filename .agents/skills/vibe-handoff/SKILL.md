---
name: vibe-handoff
description: Compresses the current conversation into a handoff document that another agent can pick up. Use when the context window is nearly full, or when the user requests a handoff, pause, or continuing work in a new session.
disable-model-invocation: true
metadata:
  argument-hint: "What will the next session be used for?"
---

# Vibe Handoff

Write a handoff document summarizing the current conversation so a fresh agent can continue the work. Save it to the user's OS temporary directory, not in the current workspace.

Include a "Suggested Skills" section in the document, recommending skills the incoming agent should invoke.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact all sensitive information such as API keys, passwords, and personally identifiable information.

If the user provided an argument, treat it as instructions on what the next session should focus on and reflect it in the document.
