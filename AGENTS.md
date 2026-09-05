# Repository Guidelines

## Project Overview

This repository manages personal dotfiles and settings for Windows. The execution script is `install.ps1`, and it includes Git, VS Code, PowerShell, OMP, Codex, and agent skills.

## Architecture & Data Flow

- Settings are stored in tool-specific directories. `install.ps1` links them to their actual usage paths under `$HOME`.
- General settings are installed as Symbolic Links, `.agents/skills/` as a Directory Junction, and machine-dependent settings (such as `codex/config.toml`) as Patches (merging dotfiles changes while preserving local settings like `[projects]`). Existing valid targets are skipped, and `-Force` recreates them.
- The original Korean skills in `skills-raw/` are translated into English distributions in `.agents/skills/`.

## Key Directories

- `git/`, `vscode/`, `pwsh/`, `codex/`: User settings for each tool.
- `omp/agent/`: Defines OMP behavior, models, MCP, language, and response rules.
- `skills-raw/`: Stores the original Korean skills and translation guidelines.
- `.agents/skills/`: Stores the English-translated skills for installation.

## Development Commands

```powershell
pwsh .\install.ps1         # Keeps valid links and creates only missing links
pwsh .\install.ps1 -Force  # Removes existing targets and recreates links
udcheck                    # Checks for Scoop and WinGet updates
udall                      # Updates Scoop, WinGet packages, and OMP plugins
syncplugins                # Updates OMP plugin marketplaces and installed plugins
syncsk                     # Synchronizes external agent skills using pnpm
```

## Testing & QA

- After translating agent skills, check the frontmatter, asset paths, relative links, unintended mixed languages, and the trailing newline.

## Commit Message Convention

- Follow the Conventional Commits format: `<type>(<scope>): <subject>`
- The allowed `type` values are `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`, and `revert`.
- Write the `subject` in Korean as a declarative sentence, limit it to 80 characters, and do not end it with a period.
- The `scope` is optional. Use an English lowercase module or domain name (for example, `auth`, `api`, or `ui`).
- Do not include issue numbers in the commit title.
- In the `body`, explain why the change is necessary instead of listing files, and wrap lines at 120 characters. Omit the `body` when the `subject` is sufficient.
- For a breaking change, add `!` after the `type` (for example, `feat!:`) and explain the migration procedure in the `body`.
- A `revert` commit must include the original commit hash in the `body`.

## Pull Request Convention

- Follow [Commit Message Convention](#commit-message-convention) for the PR title.
- Write the PR body in Korean.
- Organize the PR body in this order: `요약`, `수정 내역`, `검증 사항`, `Ref`, and `Closes`.
- In `요약`, concisely explain the purpose of the PR and its main changes.
- In `수정 내역`, list the actual changes by item.
- In `검증 사항`, describe the verification methods performed and the results confirmed.
- In `Ref`, provide related issues, PRs, documents, or other references.
- In `Closes`, identify each issue closed by the PR using `Closes #<issue-number>`.
- Omit sections that have no applicable content.
