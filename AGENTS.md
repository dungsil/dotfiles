# Repository Guidelines

## Project Overview

This repository manages personal dotfiles and settings for Windows. The execution script is `install.ps1`, and it includes Git, VS Code, PowerShell, OMP, Codex, and agent skills.

## Architecture & Data Flow

- Settings are stored in tool-specific directories. `install.ps1` links them to their actual usage paths under `$HOME`.
- General settings are installed as Symbolic Links, generated `.agents/skills/` as a Directory Junction, and machine-dependent settings (such as `codex/config.toml`) as Patches (merging dotfiles changes while preserving local settings like `[projects]`). Existing valid targets are skipped, and `-Force` recreates them.
- Before linking settings, `install.ps1` initializes the `skills/` Git submodule when missing, restores external skills from `skills-lock.json` into a per-lock-hash cache under the temp directory, and copies skills from `skills/skills/` without translation into the ignored `.agents/skills/` directory. A changed lock file or an incomplete cache re-runs the network restore; it discovers nested language-specific skill folders as well.

## Key Directories

- `git/`, `vscode/`, `pwsh/`, `codex/`: User settings for each tool.
- `omp/agent/`: Defines OMP behavior, models, MCP, language, and response rules.
- `skills/`: Git submodule for `dungsil/skills`; edit skill sources under `skills/skills/` and follow that repository's instructions. Keep `duninit` and its assets in Korean. Push submodule commits before pushing the parent repository's updated reference.
- `skills-lock.json`: Records external skill sources and selected skills.
- `.agents/skills/`: Generated installation output, excluded from Git. Do not edit it as source.

## Development Commands

```powershell
pwsh .\install.ps1         # Keeps valid links and creates only missing links
pwsh .\install.ps1 -Force  # Removes existing targets and recreates links
pwsh .\install.ps1 -SkillsOnly # Synchronizes external and local skills only
udcheck                    # Checks for Scoop and WinGet updates
udall                      # Updates Scoop, WinGet packages, and OMP plugins
syncplugins                # Updates OMP plugin marketplaces and installed plugins
syncsk                     # Runs install.ps1 -SkillsOnly from the installed profile
```

## Testing & QA

- After editing local skills, check the frontmatter, asset paths, relative links, and trailing newlines. Keep Korean source text unchanged during installation.

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
