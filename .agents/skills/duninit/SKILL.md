---
name: duninit
description: 현재 작업 공간 루트의 AGENTS.md에 공통 지침을 추가하거나 갱신한다.
disable-model-invocation: true
---

# /duninit

Add or update the default agent instructions in `AGENTS.md` in the current workspace.
Do not modify existing instructions that are not included in the assets.

## Workflow

1. Use the current workspace where the agent is running as the root.
2. If `AGENTS.md` does not exist in the current workspace or the file is empty, add `# Repository Guidelines` to the first line.
3. Read `AGENTS.md` and check whether it contains a `## Commit Message Convention` section.
   If it does not, append the contents of [`COMMIT_MESSAGE_CONVENTION.md`](./assets/COMMIT_MESSAGE_CONVENTION.md) to the end of the file.
4. Check whether it contains a `## Pull Request Convention` section.
   If it does not, append the contents of [`PULL_REQUEST_CONVENTION.md`](./assets/PULL_REQUEST_CONVENTION.md) to the end of the file.
5. After making changes, verify the following:
   - Instructions included in the assets are not duplicated.
   - Existing instructions that are not included in the assets remain unchanged.
   - The file ends with a final newline.
