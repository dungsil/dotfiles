---
name: duninit
description: 현재 작업 공간의 공통 에이전트 지침과 저장소에 맞는 PR/MR 템플릿을 추가하거나 갱신한다.
disable-model-invocation: true
---

# /duninit

Add shared instructions to the current workspace's `AGENTS.md` and prepare a PR/MR template appropriate for the repository.
Preserve existing instructions not covered by the assets and user-written templates.

## Workflow

1. Run `git rev-parse --show-toplevel` and `git remote -v` from the current workspace.
   In a Git repository, use the returned repository root as the template base. Do not rely solely on a `.git` directory check (worktrees may use a file).
   Manage `AGENTS.md` at the current workspace root. Without a Git repository, use the workspace root for templates too. Do not initialize a Git repository.
2. Select the destination as follows. Honor a destination the user has already chosen.
   - Identify GitHub from the remote URL host `github.com` and GitLab from `gitlab.com`. Handle both HTTPS and SSH URLs.
   - With multiple remotes, use the current branch's upstream, or `origin` if there is no upstream. Ask the user if there is no reference remote or platforms conflict.
   - Identify self-hosted services or SSH aliases only with evidence such as repository documentation or SSH configuration. Do not infer the service merely from a hostname containing `gitlab` or similar text.
   - If there is no Git repository, no remote, or no conclusive provider identification, ask the user to choose **GitHub template / GitLab template / rules in AGENTS.md**. Do not choose a PR/MR destination before receiving an answer.
3. If the current workspace's `AGENTS.md` is missing or empty, add `# Repository Guidelines` as its first line.
   If it has no `## Commit Message Convention` section, append [`COMMIT_MESSAGE_CONVENTION.md`](./assets/COMMIT_MESSAGE_CONVENTION.md).
4. Apply PR/MR rules according to the selected destination.
   - **GitHub:** Create `.github/pull_request_template.md` at the repository root from [`CHANGE_REQUEST_TEMPLATE.md`](./assets/CHANGE_REQUEST_TEMPLATE.md).
   - **GitLab:** Create `.gitlab/merge_request_templates/Default.md` at the repository root from the same asset. Replace PR/MR in the guidance with MR (PR for GitHub).
   - Preserve the requirement to write the body in Korean and the Korean section headings. Create only the necessary directories.
   - Check for existing templates first. For GitHub, inspect `pull_request_template.md` (including case variants) and `PULL_REQUEST_TEMPLATE/` in the root, `docs/`, and `.github/`. For GitLab, inspect Markdown files in `.gitlab/merge_request_templates/`.
     Preserve existing templates and reuse their paths. If there are several, identify the repository's default; ask the user to choose if there is no evidence for a selection. Do not add a separate default template or overwrite existing contents.
   - For template destinations, add brief instructions to `AGENTS.md` requiring PR/MR titles to follow `Commit Message Convention` and bodies to follow the linked template in Korean. Compute the relative link from the location of `AGENTS.md`. Do not duplicate equivalent rules or links.
     If an existing `Pull Request Convention` or `Merge Request Convention` section matches a previous duninit asset, replace it with the brief instructions. Preserve user modifications and add only a missing template link.
   - **AGENTS.md:** Append [`PULL_REQUEST_CONVENTION.md`](./assets/PULL_REQUEST_CONVENTION.md) only if there is no `## Pull Request Convention` section or equivalent PR/MR guidance. Do not create a platform template.
5. Verify the following and report the selected platform and created or reused paths.
   - Existing user instructions and templates are preserved, and rerunning does not duplicate rules or templates.
   - Only files appropriate to the selected destination were created, and relative links resolve to actual files.
   - Newly created template sections are ordered `요약`, `수정 내역`, `검증 사항`, `Ref`, `Closes`, and files end with a final newline.
   - Platform templates must be on the default branch to be available. GitLab project default description settings may take precedence over `Default.md`. Committing, pushing, and changing remote settings are outside this skill's scope.
