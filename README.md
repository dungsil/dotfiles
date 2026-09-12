# DUNGSIL's dotfiles

개인 설정 파일 저장소

## 시작하기

**윈도우:**
```powershell
sudo pwsh .\install.ps1 # 혹은 관리자 권한의 파워셀에서 실행

sudo pwsh .\install.ps1 -Force # 강제 재생성
```

## 스킬 관리

외부 스킬은 `skills-lock.json`으로 관리하고, 직접 작성하는 스킬은 `skills-raw/<skill-name>/`에 한국어로 저장합니다.
`install.ps1`은 `pnpm dlx skills experimental_install`로 외부 스킬을 복원하고 로컬 스킬을 번역 없이 복사합니다.
복원 결과를 확인한 뒤 `.agents/skills/`에 배포하며, 이 디렉터리는 Git으로 추적하지 않습니다.
사용자 경로인 `$HOME/.agents/skills`는 전체 설치 시 생성하는 정션으로 연결합니다.

스킬 복원에는 Git, Node.js, pnpm과 원격 저장소 접근이 필요합니다. 외부 스킬은 잠금 파일에 기록된 목록과 원본을 기준으로 가져오며,
`experimental_install`은 `computedHash`에 해당하는 과거 버전을 고정하여 복원하는 명령은 아닙니다.

```powershell
pwsh .\install.ps1 -SkillsOnly # 다른 설정을 변경하지 않고 스킬만 동기화
syncsk                        # 설치된 PowerShell 프로필에서 같은 동기화를 실행
```

외부 스킬을 추가할 때는 저장소 루트에서 `pnpm dlx skills add <owner/repo> -a universal -y --skill <name>`을 실행하고
변경된 `skills-lock.json`을 커밋합니다. 로컬 스킬과 외부 스킬에는 서로 다른 이름을 사용합니다.
목록에 없는 기존 스킬은 자동 삭제하지 않습니다.

## 라이선스
이 프로젝트는 [MIT License](./LICENSE)에 따라 배포됩니다.

### 크레딧

이 프로젝트는 아래의 프로젝트에서 코드 혹은 문서 일부를 발췌했습니다.

| 프로젝트 이름          | 라이선스  | 대상 파일                                                |
| ---------------------- | :-------: | -------------------------------------------------------- |
| [snflkd/fluent-korean] | MIT       | [omp/agent/PERSONALITY.md]                               |
| [ayghri/i-have-adhd]   | MIT       | [omp/agent/APPEND_SYSTEM.md]                             |
| [Conventional Commits] | CC BY 3.0 | [skills-raw/duninit/assets/COMMIT_MESSAGE_CONVENTION.md] |


<!-- 링크 -->
[snflkd/fluent-korean]: https://github.com/snflkd/fluent-korean
[ayghri/i-have-adhd]: https://github.com/ayghri/i-have-adhd
[Conventional Commits]: https://www.conventionalcommits.org/en/v1.0.0/

[omp/agent/PERSONALITY.md]: ./omp/agent/PERSONALITY.md
[omp/agent/APPEND_SYSTEM.md]: ./omp/agent/APPEND_SYSTEM.md
[skills-raw/duninit/assets/COMMIT_MESSAGE_CONVENTION.md]: ./skills-raw/duninit/assets/COMMIT_MESSAGE_CONVENTION.md
