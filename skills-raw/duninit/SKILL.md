---
name: duninit
description: 현재 작업 공간 루트의 AGENTS.md에 공통 지침을 추가하거나 갱신한다.
disable-model-invocation: true
---

# /duninit

현재 작업 공간의 `AGENTS.md`에 기본 에이전트 지침을 추가하거나 갱신한다.
자산에 포함되지 않은 기존 지침은 변경하지 않는다.

## Workflow

1. 에이전트가 실행된 현재 작업 공간을 루트로 사용한다.
2. 현재 작업 공간에 `AGENTS.md`가 없거나 파일이 비어 있으면 첫번째 줄에 `# Repository Guidelines`를 추가한다.
3. `AGENTS.md` 파일을 읽고 `## Commit Message Convention` 섹션이 포함되어 있는지 확인하고,
   없다면 가장 마지막 위치에 [`COMMIT_MESSAGE_CONVENTION.md`](./assets/COMMIT_MESSAGE_CONVENTION.md)의 내용을 추가한다.
4. `## Pull Request Convention` 섹션이 포함되어 있는지 확인하고,
   없다면 가장 마지막 위치에 [`PULL_REQUEST_CONVENTION.md`](./assets/PULL_REQUEST_CONVENTION.md)의 내용을 추가한다.
5. 작업 후 다음 사항을 확인한다.
   - 자산에 포함된 지침이 중복되지 않는다.
   - 자산에 포함되지 않은 기존 지침은 변경되지 않는다.
   - 파일은 마지막 줄바꿈으로 끝난다.
