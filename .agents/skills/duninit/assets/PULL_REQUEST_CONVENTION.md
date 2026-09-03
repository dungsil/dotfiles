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

### Example

PR title:

```text
feat(agent): PR 작성 규칙 추가
```

PR body:

```markdown
## 요약

공통 에이전트 지침에 PR 작성 규칙을 추가합니다.

## 수정 내역

- PR 제목 및 본문 작성 규칙 추가
- duninit 워크플로우에 PR 규칙 반영 단계 추가

## 검증 사항

- PR 규칙이 기존 지침과 중복되지 않음을 확인
- 문서가 마지막 줄바꿈으로 끝나는지 확인

## Ref

- #10

## Closes

Closes #11
```
