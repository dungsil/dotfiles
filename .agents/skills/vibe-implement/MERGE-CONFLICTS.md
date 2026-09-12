# Resolving Merge or Rebase Conflicts

Policy for separately requested or caller-owned in-progress merges or rebases. Caller-owned ticket agents do not use this process for integration; integration is owned by callers. Standalone completions do not initiate automatic merges.

1. **Establish task and scope.** Inspect current merge or rebase state, relevant history, and all conflicting files. Trace primary intent to commit messages, pull requests, and original tickets. State intended operation and exact target paths before editing.

2. **Stop on unsafe or ambiguous states.** If unrelated tracked or untracked changes appear (including user files or secret files), or if primary intent is unclear, halt automated integration and report status. Do not guess resolutions, stage everything, clean/discard user state, force-continue, or include user/secret files. Preserve original and resulting branches and commits when work cannot finish safely.

3. **Resolve only clearly established intent.** For each named target path, preserve compatible established intent from both sides. When intents are irreconcilable, select only behaviors aligned with documented merge goals and record trade-offs. Never invent behaviors.

4. **Stage only named target paths.** Stage only exact target paths resolved in this task. Never use `git add -A`, unrelated files, user files, or secret files.

5. **Verify and complete intended operation.** Run relevant project checks. Continue only with the operation inspected in Step 1 (`git merge --continue` for merges, `git rebase --continue` for rebases) and only after passing checks. If new conflicts, unsafe states, or uncertainties arise, stop and report instead of force-continuing. Preserve original and resulting branches and commits.
