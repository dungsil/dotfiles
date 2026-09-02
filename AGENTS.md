# Repository Guidelines

## Project Overview

This repository manages personal dotfiles and settings for Windows. The execution script is `install.ps1`, and it includes Git, VS Code, PowerShell, OMP, and agent skills.

## Architecture & Data Flow

- Settings are stored in tool-specific directories. `install.ps1` links them to their actual usage paths under `$HOME`.
- General settings are installed as Symbolic Links, and `.agents/skills/` as a Directory Junction. Existing valid links are skipped, and `-Force` recreates them.
- The original Korean skills in `skills-raw/` are translated into English distributions in `.agents/skills/`.

## Key Directories

- `git/`, `vscode/`, `pwsh/`: User settings for each tool.
- `omp/agent/`: Defines OMP behavior, models, MCP, language, and response rules.
- `skills-raw/`: Stores the original Korean skills and translation guidelines.
- `.agents/skills/`: Stores the English-translated skills for installation.

## Development Commands

```powershell
pwsh .\install.ps1         # Keeps valid links and creates only missing links
pwsh .\install.ps1 -Force  # Removes existing targets and recreates links
udcheck                    # Checks for Scoop and WinGet updates
udall                      # Updates Scoop and WinGet packages
syncsk                     # Synchronizes external agent skills using pnpm
```

## Testing & QA

- After translating agent skills, check the frontmatter, asset paths, relative links, unintended mixed languages, and the trailing newline.

## Commit message convention

- Follow the Conventional Commits format: `<type>(<scope>): <subject>`
- The allowed `type` values are `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`, and `revert`.
- Write the `subject` in Korean as a declarative sentence, limit it to 80 characters, and do not end it with a period.
- The `scope` is optional. Use an English lowercase module or domain name (for example, `auth`, `api`, or `ui`).
- In the `body`, explain why the change is necessary instead of listing files, and wrap lines at 120 characters. Omit the `body` when the `subject` is sufficient.
- For a breaking change, add `!` after the `type` (for example, `feat!:`) and explain the migration procedure in the `body`.
- A `revert` commit must include the original commit hash in the `body`.