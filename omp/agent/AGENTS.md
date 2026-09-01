# AGENTS.md

## Commit message convention

- Follow Conventional Commits: `<type>(<scope>): <subject>`
- Allowed types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`, `revert`
- Subject: Korean, imperative-free plain statement, max 80 chars, no trailing period.
- Scope: optional; use a module or domain name in English lowercase (e.g. `auth`, `api`, `ui`).
- Body: explain WHY the change is needed (not a file list), wrapped at 120 chars per line. Omit if the subject is self-explanatory.
- Breaking change: add `!` after the type (`feat!:`) and describe the migration path in the body.
- `revert` commits must reference the original commit hash in the body.
- When the repository's existing history follows a different convention, the repository's convention wins; check `git log` before committing.