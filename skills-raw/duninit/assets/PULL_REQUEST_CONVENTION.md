## Pull Request Convention

- PR 제목은 [Commit Message Convention](#commit-message-convention)을 따릅니다.
- PR 본문은 한국어로 작성합니다.
- PR 본문은 요약, 수정 내역, 검증 사항, Ref, Closes 이슈 번호 순서로 작성합니다.
- 요약에는 PR의 목적과 주요 변경 사항을 간결하게 설명합니다.
- 수정 내역에는 실제 변경 사항을 항목별로 작성합니다.
- 검증 사항에는 실행한 검증 방법과 확인한 결과를 작성합니다.
- Ref에는 참고할 관련 이슈, PR, 문서 등을 작성합니다.
- Closes에는 이 PR로 종료할 이슈를 `Closes #<이슈 번호>` 형식으로 작성합니다.
- 해당 내용이 없는 섹션은 생략할 수 있습니다.

### Example

PR 제목:

```text
feat(agent): PR 작성 규칙 추가
```

PR 본문:

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
