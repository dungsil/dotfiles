# Issue Tracker: GitLab

Issues and PRDs in this repository are managed as GitLab Issues. Use the [`glab`](https://gitlab.com/gitlab-org/cli) CLI for all operations.

## Korean writing

Before drafting Korean issues, merge requests, reviews, or comments, read the installed `vibe-docs` skill and follow its `Required application order`. Preserve the exact form of domain terms and label strings defined in `CONTEXT.md`, relevant ADRs, and `docs/agents/`; do not translate, generalize, or neutralize them.

## Rules

- **Create Issue**: `glab issue create --title "..." --description "..."`. Use heredocs for multi-line descriptions. Passing `--description -` opens an editor.
- **Read Issue**: `glab issue view <number> --comments`. Use `-F json` for machine-readable output.
- **List Issues**: `glab issue list -F json`, applying appropriate `--label` filters.
- **Comment on Issue**: `glab issue note <number> --message "..."`. GitLab calls comments "notes".
- **Apply / Remove Labels**: `glab issue update <number> --label "..."` / `--unlabel "..."`. Separate multiple labels with commas or repeat flags.
- **Close**: `glab issue close <number>`. `glab issue close` does not accept closing comments, so post notes first via `glab issue note <number> --message "..."` before closing.
- **Merge Requests**: GitLab calls PRs "merge requests". Use `glab mr create`, `glab mr view`, `glab mr note`, etc. — identical to `gh pr ...` patterns substituting `mr` for `pr` and `note`/`--message` for `comment`/`--body`.

Repository is inferred from `git remote -v` — running `glab` inside a clone handles this automatically.

## Merge Requests as Triage Surface

**MRs as request surface: no.** _(Set to `yes` if this repository treats external merge requests as feature requests. The triage stage of `vibe-plan` reads this flag.)_

When set to `yes`, MRs share labels and statuses with issues, using equivalent `glab mr` commands:

- **Read MR**: `glab mr view <number> --comments` and `glab mr diff <number>` for diffs.
- **List External MRs for Triage**: `glab mr list -F json`, retaining only MRs where authors are not project members/owners (contributor MRs rather than maintainer in-progress work).
- **Comment / Label / Close**: `glab mr note`, `glab mr update --label`/`--unlabel`, `glab mr close`.

Unlike GitHub, GitLab numbers issues and MRs separately, so `#42` is unambiguous once the maintainer knows the surface.

## When a Skill Says "Post to Issue Tracker"

Create a GitLab Issue.

## When a Skill Says "Fetch Relevant Tickets"

Run `glab issue view <number> --comments`.

## Publishing MRs with Auto-Close References

Used when standalone `/vibe-implement` publishes an MR. A human pressing **Merge** in the UI is the close approval — passing review is not approval.

**Eligibility.** Use a closing pattern only when all six hold:

1. This repository uses a hosted tracker (GitLab Issues).
2. The MR target branch is the **merge-target project's** default branch. Resolve the target project from the MR URL that `glab mr create` prints when you publish — the URL's `<group>/<project>/-/merge_requests/<iid>` is the target project and MR IID. With the target project pinned from the URL's path, run `glab mr view <IID> -R <target-project> -F json --jq '{target_branch, target_project_id}'` to confirm the target, then `glab api projects/<target_project_id> | jq '{path_with_namespace, default_branch, autoclose_referenced_issues}'` for the default branch and auto-close setting. Never run `glab mr view` before the target project is known — in a fork clone `git remote -v` resolves to the source (fork), which cannot see the target project's MR. Do not use `projects/:id` for fork MRs: it points at the fork.
3. Auto-close is enabled on the **project owning the target issue**. Pin the issue project in an API-path-ready form first — record the numeric `<issue-project-id>`, or use the namespaced path URL-encoded as `<group>%2F<project>`. Never put `<group>/<project>` raw in the path — the `/` is parsed as a path separator and hits the wrong endpoint. Same project: `<issue-project-id>` is `target_project_id` from 2, and read `autoclose_referenced_issues` from the `projects/<target_project_id>` response obtained there. Different project: query that project separately and record the numeric id and the setting together — `glab api projects/<group>%2F<project> | jq '{id, autoclose_referenced_issues}'` (`glab api` has no `--jq` flag; pipe to `jq`). Every subsequent issue / members / commits API call uses the numeric id or the `%2F`-encoded path only.
   Separately from the numeric id / encoded path used for the API, also record the issue-owning project's raw `path_with_namespace` full path `<issue-project>` for manual tracker writes. `-R` accepts only this raw path, so never give it a numeric id or a `%2F`-encoded path. For a different project, include `path_with_namespace` in the lookup — `glab api projects/<group>%2F<project> | jq '{id, path_with_namespace, autoclose_referenced_issues}'`.
4. The person who will press Merge is decided, and their **permission to close the target issue** is proven in advance. Prove either: (a) they are the target issue's author or an assignee — `glab api projects/<issue-project-id>/issues/<iid> | jq '{author: .author.username, assignees: [.assignees[].username]}'`. (b) their access level in the issue project is Planner (15) or above — `glab api "users?username=<user>" | jq '.[0].id'`, then `glab api projects/<issue-project-id>/members/all/<user-id> | jq '{access_level}'`. An author or assignee is eligible even without a membership lookup or when it fails — project membership is not required. If the merger is undecided or neither (a) nor (b) is proven, you are not eligible. Never assume permission you cannot prove.
5. There is **exactly one** implementation ticket whose acceptance is complete at merge.
6. Before any native eligible handoff you have confirmed this instance's **exact issue-closing regex** and recorded it verbatim. GitLab.com (SaaS) uses GitLab.com's default regex; a self-managed instance takes the exact regex from the instance config (Omnibus: `gitlab_rails['gitlab_issue_closing_pattern']` in `/etc/gitlab/gitlab.rb`; source installs: `issue_closing_pattern` in `gitlab.yml`) or from an administrator. When it is unknown this is a **hard stop**: do not publish with a closing keyword, and do not proceed with the merge or the manual-close handoff either. If a keyword is already published, do not proceed to merge or to `glab issue close` until a direct scan with that exact regex proves the residual auto-close risk is zero.

Conditions 2 and 3 can involve different projects, so always check them separately: read the default branch in the MR's merge-target project and the auto-close setting in the issue's own project. When `autoclose_referenced_issues` is `false`, references stay but nothing closes.

**Record and pin the project at publish time.** When you publish the MR, record two values — the **target project** (the `path_with_namespace` full path `<group>/<project>` and the numeric `target_project_id`, both read from the `glab api projects/<target_project_id>` response in 2 above) and the **MR IID**. Append `-R <target-project>` to every subsequent `glab mr view`, `glab mr issues`, and `glab mr update`. In a clone checked out from the fork, running without `-R` makes `glab` pick the source (fork) project from `git remote -v`, so it reads and edits the fork instead of the project the MR merges into. `-R` accepts only a path (`<group>/<project>`), so use the numeric id in `glab api projects/<target_project_id>/...` paths — `glab api` has no `-R`. The recorded IID is the MR IID as seen in the target project, not a source-project number.
**Record the issue project too.** For the same project and cross-project alike, record the raw `path_with_namespace` `<issue-project>` of the project that owns the issue. This value is used in `glab issue ... -R <issue-project>`, and it is never omitted even when it is the same as the target project.

**Reference Syntax**

- Same project: one `Closes #<iid>` line in the MR description.
- Different project: prefix the full path or the full URL with the closing keyword — `Closes <group>/<project>#<iid>` or `Closes https://gitlab.example.com/<group>/<project>/-/issues/<iid>`. A keyword-less URL alone leaves a bare link and closes nothing.
- Default closing keywords are `Close(s/d)`/`Closing`, `Fix(es/ed)`/`Fixing`, `Resolve(s/d)`/`Resolving`, `Implement(s/ed)`/`Implementing`. Unlike GitHub, the `implement` family closes too.
- The default pattern closes every reference listed on one line (`Closes #4, #6`) — put exactly one ticket on the closing line.
- The parent spec issue is never a closing target — write only `Part of #<parent>`.
- References you do not want closed carry no keyword: `Related to #<n>` / `Refs #<n>`.
- Research / prototype / interview tickets, and tickets whose acceptance continues after merge (deploy, manual verification, and so on), are not closing targets.
- Commit messages carry no closing keyword, and the **MR title carries no issue reference at all** — drop `#<iid>`, `<group>/<project>#<iid>`, and full issue URLs from the title regardless of keyword (any reference in a title is banned, not just keyword-bearing ones). The instance closing pattern scans the MR description and the branch commit messages together, so a keyword left in a commit creates an unintended close outside the description. Squash merge uses the MR title as the commit subject, so a reference left in the title becomes the commit message of the merged commit after post-publish verification has already finished, and it is caught by the default or the instance's custom pattern no matter how it was written. The title check therefore counts references — it is decidable without knowing the pattern. Put ticket numbers in the description instead.

**Target Verification After Publishing.** Run right after publishing and re-confirm every condition. Pin every `glab mr` command to the target project with the recorded `-R <target-project>` and MR IID:

```bash
glab mr view <IID> -R <target-project> -F json --jq '{state, target_branch, target_project_id, title, description}'
glab api projects/<target_project_id> | jq '{path_with_namespace, default_branch, autoclose_referenced_issues}'
glab api projects/<issue-project-id> | jq '.autoclose_referenced_issues'   # only when the issue is in another project (numeric id or <group>%2F<project>)
glab api projects/<issue-project-id>/issues/<iid> | jq '{author: .author.username, assignees: [.assignees[].username]}'
glab api projects/<issue-project-id>/members/all/<merger-user-id> | jq '{access_level}'   # only when the merger is neither author nor assignee
glab api --paginate "projects/<target_project_id>/merge_requests/<IID>/commits?per_page=100" | jq -r '.[] | .title, .message'
glab mr issues <IID> -R <target-project>
```

Check `target_branch` matches the target project's default branch / auto-close is on for the issue project / the merger is the target issue's author or an assignee, or failing that their access level in the issue project is Planner (15) or above / the MR is still open. Once author/assignee status is confirmed, the membership lookup result is unnecessary. The commits endpoint pages at 20 by default, so fetch with `--paginate` through the last page — reading a single page misses keywords in later commits.

**The direct description scan is primary.** Apply the confirmed exact closing regex to the `description` from `glab mr view -F json` and count the closing matches — there must be **exactly one** match, that reference must be the single intended ticket (same-project `#<iid>`, cross-project path `<group>/<project>#<iid>`, or full URL), and **extra closing matches must be zero**. The MR title carries zero issue references (decided by the reference count alone, so it holds even without a keyword), and every commit message has zero closing matches. Keep the exactly-one `glab mr issues <IID> -R <target-project>` list as **supplementary provider evidence only** — this list is under-reported by both permission filtering and the eligibility gate, so never trust it alone as proof that the intended ticket is the only one. Go to the fallback when the description is not exactly one intended match + zero extra, or when you cannot tell whether an empty list is empty because of permission or because of the pattern.

**Fallback.** In these cases skip auto-close and close manually with landing proof + an exact preview + separate approval:

- Auto-close is off for the issue project (`autoclose_referenced_issues: false`).
- The target branch is not the target project's default branch.
- The person who will press Merge is undecided, or their permission to close the target issue cannot be proven — they are neither the target issue's author nor an assignee, and their access level in the issue project is below Planner (15) or unverifiable.
- The MR was closed without merging — auto-close never fires and the issue stays open.

**Pin manual-close writes to the issue-owning project too.** A manual close's comment and close are written to the **project that owns the issue**, not the MR's project — pass the recorded raw `<issue-project>` (the `path_with_namespace` from 3) to `-R`. State it for the same project and cross-project alike, with no exception:

- `glab issue note <iid> -R <issue-project> --message "..."`
- `glab issue close <iid> -R <issue-project>`

Without `-R`, the clone resolved from `git remote -v` (the fork or the target) is picked, so you can comment on or close a same-numbered issue in a different project. The issue IID is the number in the recorded `<issue-project>`.
- `glab mr issues <IID> -R <target-project>` returns an error or not exactly one ticket. Causes may be an instance custom closing pattern (instance setting) or insufficient permission (GitLab skips the close when the merger lacks permission), but do not diagnose the cause from CLI output alone. This list is subject to both permission filtering and the eligibility gate — with the gate off or permission short it comes back empty or reduced even while the pattern is still there, so never use the list itself as a pattern scan.
- There is not exactly one ticket eligible for closing (zero, several, or only the parent issue).
- **The direct description scan does not satisfy exactly one intended match + zero extra** — zero closing matches (the intended close may not fire, or the regex may be wrong), the reference is not the intended ticket, or there is even one extra closing match (risk of an unintended close).

**On fallback, remove auto-close completely.** If `glab mr issues` surfaces an extra issue or any fallback condition above holds, finish the following before moving to manual close. Use the recorded `-R <target-project>` and MR IID in every `glab mr` command:

1. Strip every issue reference from the MR **title** entirely, and remove only the closing **keyword** from the description — update the title with `glab mr update <IID> -R <target-project> --title "<new title>"` and the description with `glab mr update <IID> -R <target-project> --description "<new body>"`. The title becomes the commit subject under squash merge, so removing just the keyword is not enough: take `#<iid>`, `<group>/<project>#<iid>`, and full issue URLs out of the title to reach zero references, and keep any ticket number only in the description. In the description, turn every `Close(s/d)`/`Closing`, `Fix(es/ed)`/`Fixing`, `Resolve(s/d)`/`Resolving`, `Implement(s/ed)`/`Implementing` into `Refs` — and convert every known custom closing keyword of this instance the same way, keyword-only (if the custom pattern is unknown, abort per 4 below). Preserve each reference in its original form — same-project `#<iid>`, cross-project full path `<group>/<project>#<iid>`, and full URLs all stay verbatim (`Closes <group>/<project>#12` → `Refs <group>/<project>#12`, `Closes https://gitlab.example.com/<group>/<project>/-/issues/12` → `Refs https://gitlab.example.com/<group>/<project>/-/issues/12`). Never drop, merge, or shorten the description's references to same-project shorthand, and when one line lists several references keep **every** one. Leave `Part of #<parent>` untouched.
2. Remove **all** closing patterns from commit messages too. Again convert only the keyword to `Refs` — including every known custom closing keyword (unknown custom pattern: abort per 4 below) — and preserve every reference, including cross-project paths and URLs. Rewrite the branch commit messages (`git rebase -i`, or `git commit --amend` if it is only the last commit) and push with `git push --force-with-lease`.
3. Confirm the removal with a **direct scan**. Fetch the target-project MR's title, description, and every commit message, and require **zero issue references in the title** and **zero (closing keyword) + (issue reference) combinations in the description and every commit message**:

   ```bash
   glab mr view <IID> -R <target-project> -F json --jq '{title, description}'
   glab api --paginate "projects/<target_project_id>/merge_requests/<IID>/commits?per_page=100" | jq -r '.[] | .title, .message'
   ```

   The commits endpoint pages at 20 by default, so fetch with `--paginate` through the last page — reading a single page misses keywords in later commits. The title check only counts references, so it is decidable without knowing the pattern. The description and commit scan applies the full default keyword family **and the instance's custom closing pattern**. There is no API to look it up — on gitlab.com (SaaS) the default pattern stands; on a self-managed instance get the **exact regex** from the instance config (Omnibus: `gitlab_rails['gitlab_issue_closing_pattern']` in `/etc/gitlab/gitlab.rb`; source installs: `issue_closing_pattern` in `gitlab.yml`) or from an administrator, record it verbatim, and use it in the scan. The default pattern also matches a `:` or `issue`/`issues` word between keyword and reference (`Closes: #4`, `Fixes issue #4`), and accepts all three reference forms — `#<iid>`, `<group>/<project>#<iid>`, full issue URL — so check all three.
4. If the custom pattern is unknown — on a self-managed instance the instance config is unreadable and no administrator confirms the exact regex — **do not treat the direct scan as complete and abort the merge handoff.** Never present a default-pattern-only scan as proof of removal in the description or commits. The title's zero-reference check is independent of the pattern, so it still stands apart from this abort.
5. Only when the eligibility gate was actually live (target branch = the target project's default branch **and** `autoclose_referenced_issues: true` on the issue project) may you use an **empty** `glab mr issues <IID> -R <target-project>` list as supplementary evidence. When the gate is off, the list is empty even with patterns remaining, so never claim removal from an empty list alone — the direct scan in 3 is the only evidence then.
6. If a safe rewrite is impossible — you would have to rewrite others' commits, the branch is protected, force-push is blocked, or you lack push access to the fork — **abort the merge handoff.** Report the residual auto-close risk to the human; never hand off a merge with unverified auto-close still live.

**Merge when pipeline succeeds** locks the list of issues to be closed — finish the verification above before enabling it.

## Wayfinding Operations

Used by `/vibe-deep-plan`. A **map** is a single issue with tickets as **sub-issues**.

- **Map**: Single issue labeled `상태:초안` and `유형:계획` with Notes / Decisions-so-far / Fog body: `glab issue create --label "상태:초안" --label "유형:계획"`. (In GitLab tiers with native Epics, Epics can replace maps. Labeled issues work anywhere.)
- **Child Tickets**: Issues with `Part of #<map>` at top of description, labeled `유형:조사` / `유형:프로토타입` / `유형:인터뷰` / `유형:작업`. Assign to the acting developer upon claiming.
- **Blocking**: Add via the links API — `glab api --method POST "projects/:id/issues/<child>/links" -F target_project_id=<id> -F target_issue_iid=<blocker> -F link_type=is_blocked_by`. **Do not use quick actions**: `/blocked_by` is unrecognized on tiers without native blocking and posts as a literal comment. If that call returns `HTTP 400 link_type does not have a valid value`, the instance has no native blocking (Free/CE) — record blockers as a `#<n>` list in the description's "Prerequisites" section only. A ticket unblocks when all blocking issues close.
- **Frontier Query**: Fetch `glab issue list -F json` restricted to map children, excluding those with open blockers (native `is_blocked_by` links to open issues via `glab api projects/:id/issues/:iid/links` or open issues in the "Prerequisites" section) or assignees, ordered by map position.
- **Claim**: `glab issue update <n> --assignee @me` — first record of session.
- **Release Research Claim**: After saving full findings and research record pointer during charting, run `glab issue update <n> --assignee=-@me` (replacing `@me` with actual session username if needed). Leave research issue open without adding map gist. Retain assignee if save fails or session passes incomplete work.
- **Resolve**: `glab issue note <n> --message "<answer>"`, then `glab issue close <n>`, and append context pointer (gist + link) to map's Decisions-so-far.

## Research Record Persistence

- Calling session posts full findings with source citations in a single dedicated note on the same research issue, starting with `<!-- vibe-deep-plan research: <map-issue>/<ticket-issue> -->` for immutable identity lookup.
- If notes exceed provider limits, use ordered notes (`Research record 1/N`, `2/N`...) or project wikis, snippets, attachments, or equivalent persistent artifacts, linking that record from the issue note. Never truncate findings or leave only in local files.
- Record `Research record: <note or artifact URL>` on ticket. Hosted research has no `Branch`, `Commit`, or `Path` pointers, and never creates or pushes `research/...` branches.
- Keep research issues open during charting without map gists. Release claim after successful save with `glab issue update <n> --assignee=-@me` (replacing `@me` with actual username if needed). Retain claim if save fails. Inspect existing notes and linked artifacts before re-running.