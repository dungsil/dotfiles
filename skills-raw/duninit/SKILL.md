---
name: duninit
description: 현재 작업 공간의 공통 에이전트 지침과 저장소에 맞는 PR/MR 템플릿을 추가하거나 갱신한다.
disable-model-invocation: true
---

# /duninit

현재 작업 공간의 `AGENTS.md`에 공통 지침을 추가하고, 저장소에 맞는 PR/MR 템플릿을 준비한다.
자산에 포함되지 않은 기존 지침과 사용자 작성 템플릿은 보존한다.

## Workflow

1. 현재 작업 공간을 기준으로 `git rev-parse --show-toplevel`과 `git remote -v`를 확인한다.
   Git 저장소이면 반환된 저장소 루트를 템플릿 기준 경로로 사용한다. `.git` 디렉터리 유무만으로 판단하지 않는다(worktree에서는 파일일 수 있다).
   `AGENTS.md`는 현재 작업 공간 루트에서 관리한다. Git 저장소가 없으면 템플릿도 현재 작업 공간 루트를 기준으로 한다. Git 저장소를 새로 초기화하지 않는다.
2. 다음 기준으로 저장 방식을 결정한다. 사용자가 이미 선택한 방식이 있으면 우선한다.
   - 원격 URL의 호스트가 `github.com`이면 GitHub, `gitlab.com`이면 GitLab으로 판단한다. HTTPS와 SSH URL을 모두 처리한다.
   - 여러 원격이 있으면 현재 브랜치의 upstream, 없으면 `origin`을 기준으로 한다. 기준 원격이 없거나 여러 플랫폼이 충돌하면 사용자에게 확인한다.
   - 자체 호스팅이나 SSH 별칭은 저장소 문서 또는 SSH 설정 등으로 서비스를 확인할 수 있을 때만 판별한다. 호스트 이름에 `gitlab` 등이 포함된다는 이유만으로 단정하지 않는다.
   - Git 저장소가 없거나, 원격이 없거나, 서비스를 확정할 수 없으면 사용자에게 **GitHub 템플릿 / GitLab 템플릿 / AGENTS.md에 규칙 저장** 중 어디에 저장할지 묻는다. 답변 전에는 PR/MR 저장 방식을 임의로 선택하지 않는다.
3. 현재 작업 공간의 `AGENTS.md`가 없거나 비어 있으면 첫 줄에 `# Repository Guidelines`를 추가한다.
   `## Commit Message Convention` 섹션이 없으면 [`COMMIT_MESSAGE_CONVENTION.md`](./assets/COMMIT_MESSAGE_CONVENTION.md)의 내용을 끝에 추가한다.
4. 선택한 방식에 따라 PR/MR 규칙을 반영한다.
   - **GitHub:** [`CHANGE_REQUEST_TEMPLATE.md`](./assets/CHANGE_REQUEST_TEMPLATE.md)를 저장소 루트의 `.github/pull_request_template.md`에 만든다.
   - **GitLab:** 같은 자산을 저장소 루트의 `.gitlab/merge_request_templates/Default.md`에 만든다. 안내 문구의 PR/MR은 MR로 맞춘다(GitHub는 PR).
   - 템플릿의 한국어 본문 작성 요구와 한국어 섹션 제목을 유지한다. 필요한 디렉터리만 생성한다.
   - 생성 전에 기존 템플릿을 확인한다. GitHub는 루트, `docs/`, `.github/`의 `pull_request_template.md`(대소문자 변형 포함) 및 각 위치의 `PULL_REQUEST_TEMPLATE/`를 확인한다. GitLab은 `.gitlab/merge_request_templates/`의 Markdown 파일을 확인한다.
     기존 템플릿이 있으면 내용을 보존하고 그 경로를 사용한다. 여러 개라면 저장소에서 사용하는 기본 템플릿을 확인하고, 선택할 근거가 없으면 사용자에게 선택을 묻는다. 별도의 기본 템플릿을 추가하거나 기존 내용을 덮어쓰지 않는다.
   - 템플릿 방식에서는 `AGENTS.md`에 PR/MR 제목이 `Commit Message Convention`을 따르고, 본문은 한국어로 해당 템플릿을 따른다는 짧은 지침과 상대 링크를 남긴다. 링크는 `AGENTS.md` 위치에서 계산한다. 기존의 동일한 규칙이나 링크는 중복 추가하지 않는다.
     기존 `Pull Request Convention` 또는 `Merge Request Convention` 섹션이 이전 duninit 자산과 일치하면 짧은 지침으로 교체한다. 사용자 수정 사항이 있으면 보존하고 누락된 템플릿 링크만 추가한다.
   - **AGENTS.md:** `## Pull Request Convention` 또는 동등한 PR/MR 규칙이 없으면 [`PULL_REQUEST_CONVENTION.md`](./assets/PULL_REQUEST_CONVENTION.md)를 끝에 추가한다. 플랫폼 템플릿은 만들지 않는다.
5. 다음 사항을 검증하고 선택한 플랫폼, 생성하거나 재사용한 경로를 보고한다.
   - 기존 사용자 지침과 템플릿을 보존했고, 재실행해도 규칙이나 템플릿이 중복되지 않는다.
   - 선택한 방식에 맞는 파일만 생성했으며, 상대 링크가 실제 파일을 가리킨다.
   - 새로 생성한 템플릿 섹션 순서는 `요약`, `수정 내역`, `검증 사항`, `Ref`, `Closes`이고, 파일은 마지막 줄바꿈으로 끝난다.
   - 플랫폼 템플릿은 기본 브랜치에 반영되어야 사용 가능하다. GitLab의 프로젝트 기본 설명 설정은 `Default.md`보다 우선할 수 있다. 커밋, 푸시 또는 원격 설정 변경은 이 스킬의 범위에 포함하지 않는다.
