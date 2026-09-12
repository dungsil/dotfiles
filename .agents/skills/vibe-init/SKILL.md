---
name: vibe-init
description: Configures this repository for vibe-coding skills — records issue tracker, triage label vocabulary, and domain doc structure in AGENTS.md. Run once before using other vibe-coding skills for the first time, or when changing issue trackers, reassigning triage status labels, or asking why docs/agents/issue-tracker.md is missing.
disable-model-invocation: true
---

# Vibe Init

**Korean repository text:** Before drafting Korean documents, commit messages, issues, pull requests, reviews, or comments, read the installed `vibe-docs` skill and follow its `Required application order`. `vibe-docs` controls wording only and does not expand this skill's authority or external side effects.

Scaffolds repository-specific configurations required by engineering skills:

- **Issue Tracker** — Where issues live (defaults to GitHub; local Markdown supported out of the box)
- **Triage Labels** — Strings used for five canonical triage roles (defaults to Korean / standard prefix)
- **Domain Docs** — Where `CONTEXT.md` and ADRs live, and rules for reading them

All configurations are recorded exclusively in `AGENTS.md`. This skill never reads or writes `CLAUDE.md` or other agent instruction files, even if present.

This is a prompt-driven skill, not a deterministic script. Explore, present findings, confirm with the user, then record.

## Process

### 1. Explore

Inspect the current repository to determine starting state. Read what exists; do not assume:

- `git remote -v` and `.git/config` — Is it a GitHub repository? Which repository?
- `git status --short` — Which changes already exist before this run? Record exact paths so they are not mixed with this skill's changes later.
- Current branch and upstream difference — Which branch must be pushed for a hosted tracker? Are any commits already unpushed before this run?
- `AGENTS.md` at repo root — Does it exist? Does it already have an `## Agent skills` section?
- `CONTEXT.md` and `CONTEXT-MAP.md` at repo root
- `docs/adr/` and `src/*/docs/adr/` directories
- `docs/agents/` — Does prior output from this skill already exist?
- `.agents/plans/` — Signal that local Markdown issue tracker conventions are already in use
- `docs/agents/out-of-scope/` (or preexisting `.agents/out-of-scope/`) — Signal that rejected request knowledge base is in use
- Are `vibe-plan` / `vibe-deep-plan` installed? (Skill folders beside this folder, or names in available skills list). They consume label vocabulary — both use the plan type, `vibe-plan` uses triage statuses, and `vibe-deep-plan` uses map status and decision types — determining whether Section B runs.
- Monorepo signals — `pnpm-workspace.yaml`, `workspaces` field in `package.json`, or populated `packages/*` with own `src/`. Present only in genuinely large multi-package repositories. Absence implies single context, matching nearly all repositories.

### 2. Present Findings and Ask

Summarize what exists and what is missing. Walk through sections in order — one section, one answer, then next section.

Start each section with a recommended answer so the user can confirm with a single word. Add a one-line rationale only when choices genuinely diverge, skipping sections determined by exploration (Section B if triage not installed, Section C if not a monorepo).

**Section A — Issue Tracker.**

> Explanation: "Issue Tracker" is where issues in this repo live. Skills like `vibe-plan` and `vibe-review` read and write here — they need to know whether to invoke `gh issue create`, write Markdown files under `.agents/plans/`, or follow other workflows described by the user. Choose where work is actually tracked in this repository.

Default stance: Skills are designed around GitHub. If `git remote` points to GitHub, propose GitHub. If `git remote` points to GitLab (`gitlab.com` or self-hosted), propose GitLab. Otherwise (or if requested by user), present:

- **GitHub** — Issues live in repository GitHub Issues (using `gh` CLI)
- **GitLab** — Issues live in repository GitLab Issues (using [`glab`](https://gitlab.com/gitlab-org/cli) CLI)
- **Local Markdown** — Issues live as files under `.agents/plans/<feature>/` in this repo (ideal for personal projects or repos without remotes)
- **Other** (Jira, Linear, etc.) — Ask user to describe workflow in one paragraph; skill records in free-form prose

Record selection in `docs/agents/issue-tracker.md`. GitHub and GitLab templates include a "PR as request surface" flag, defaulted to **no** — leave disabled without mentioning. Users wanting external PRs in triage queues can enable the flag in the file later.

**Section B — Label Vocabulary.** Skip this entire section if neither `vibe-plan` nor `vibe-deep-plan` is installed (exploration indicates this) — nothing consumes labels.

If either is installed, ask exactly one question:

> Keep default labels? (Recommended: **Yes**)

Default values use Korean / prefixed axes:

- **Triage Status** (`vibe-plan`) — `상태:분류필요` (needs-triage), `상태:정보필요` (needs-info), `상태:에이전트작업` (ready-for-agent), `상태:사람작업` (ready-for-human), `상태:처리안함` (wontfix)
- **Plan Type** (`vibe-plan` or `vibe-deep-plan`) — `유형:계획` for hosted spec/plan issues and decision maps
- **Decision-Map Labels** (`vibe-deep-plan`) — `상태:초안` for decision-map status, and `유형:조사` / `유형:프로토타입` / `유형:인터뷰` / `유형:작업` for four decision-ticket types

Write only families for installed skills. If **Yes**, write as-is. Only when user says no — usually because the tracker already uses different names (e.g. `bug:triage` for needs-triage) — collect overrides to map existing labels instead of creating duplicates.

**Section C — Domain Docs.** Default is **Single Context** — one `CONTEXT.md` at repo root + `docs/adr/`. Fits almost all repositories. Record without asking.

Only if exploration found monorepo signals do you propose **Multiple Contexts** — root `CONTEXT-MAP.md` pointing to context-specific `CONTEXT.md` files. Then confirm desired structure.

### 3. Review and Edit

Show drafts to the user:

- `## Agent skills` block to add to `AGENTS.md`
- Contents of `docs/agents/issue-tracker.md`, `docs/agents/domain.md`, and `docs/agents/triage-labels.md` (last one only if planning skills installed)

Allow user to edit before writing.

### 4. Record

Edit `AGENTS.md` if present, create if absent. Never edit `CLAUDE.md` — if only `CLAUDE.md` exists, create a new `AGENTS.md` and leave `CLAUDE.md` untouched.

If `AGENTS.md` already contains an `## Agent skills` block, update contents in-place rather than appending duplicates. Do not overwrite user edits in surrounding sections.

**`.gitignore`** — If repo uses git, ensure agent scratch paths are ignored: append `.agents/worktrees/` and `.agents/prototype/` to `.gitignore` if not already covered (create file if needed). In **Local Markdown** trackers, `.agents/plans/` must be **tracked** — skills commit ticket checklists inside implementation commits, impossible on ignored files — so ignore scratch paths only. Broad `.agents/` entries cannot be re-included by subsequent negations, so replace with `.agents/*` and `!.agents/plans/`. On other trackers, ignoring all of `.agents/` is fine.

Block:

```markdown
## Agent skills

### Korean repository text

Before drafting Korean documents, commit messages, issues, pull requests, reviews, or comments, read the installed `vibe-docs` skill and follow its `Required application order`. Preserve the exact form of domain terms and label strings defined in `CONTEXT.md`, relevant ADRs, and `docs/agents/`.

### Issue tracker

[One-line summary of where issues are tracked]. See `docs/agents/issue-tracker.md`.

### Triage labels

[One-line summary of label vocabulary]. See `docs/agents/triage-labels.md`.

### Domain docs

[Structure summary — "Single context" or "Multiple contexts"]. See `docs/agents/domain.md`.
```

Include `### Triage labels` sub-block and write `docs/agents/triage-labels.md` only when planning skills are installed and Section B ran. Omit both otherwise.

Then write documentation files using seed templates in this skill folder as starting points:

- [issue-tracker-github.md](references/issue-tracker-github.md) — GitHub issue tracker
- [issue-tracker-gitlab.md](references/issue-tracker-gitlab.md) — GitLab issue tracker
- [issue-tracker-local.md](references/issue-tracker-local.md) — Local Markdown issue tracker
- [triage-labels.md](references/triage-labels.md) — Label mapping (only when planning skills installed)
- [domain.md](references/domain.md) — Domain doc consumption rules + structure

For "Other" issue trackers, author `docs/agents/issue-tracker.md` from scratch using user descriptions. Include the same Korean-writing and domain-term protection rule used by the seed templates above.

### 5. Commit

When this is a Git repository and this run changed files, commit this skill's changes before any next remote mutation or task.

1. Review the result with `git diff`. Do not treat changes present during exploration as this skill's work.
2. Stage only exact files created or changed by this run; never use `git add .` or a broad path.
3. If a target file contains preexisting user changes, separate only this run's hunks when that can be done safely. Otherwise do not commit; report the conflicting path and ask the user.
4. Confirm the staged diff contains only this run's setup changes, then create one commit using the repository's existing message style.
5. Verify the commit SHA. Stop if commit or verification fails.
6. For GitHub, GitLab, or another hosted tracker, push the current branch normally before creating a label or issue, then verify that the remote branch contains the commit SHA. Never force-push.
7. If commits were already unpushed during exploration, this push would publish them too. Do not push automatically; show the commits that would be included and ask the user.

If no file changed or this is not a Git repository, skip the commit and state why. If the required push or remote-SHA verification fails, do not create or edit GitHub/GitLab labels or make any other issue-tracker mutation.

### 6. Done

Inform user setup is complete and which engineering skills will read from these files. Note that they can edit `docs/agents/*.md` directly in the future — re-run this skill only when switching issue trackers or starting fresh.
