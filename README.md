# DUNGSIL's dotfiles

개인 설정 파일 저장소

## 시작하기

**윈도우:**
```powershell
sudo pwsh .\install.ps1 # 혹은 관리자 권한의 파워셀에서 실행

sudo pwsh .\install.ps1 -Force # 강제 재생성
```

## 스킬 관리

외부 스킬은 `skills-lock.json`으로 관리하고, 직접 작성하는 스킬은 `skills/`에 연결한 [dungsil/skills](https://github.com/dungsil/skills) Git 서브모듈에서 관리합니다.

```powershell
pwsh .\install.ps1 -SkillsOnly # 다른 설정을 변경하지 않고 스킬만 동기화
syncsk                        # 설치된 PowerShell 프로필에서 같은 동기화를 실행
```
 * `install.ps1`은 `pnpm dlx skills experimental_install`로 외부 스킬을 복원하고 로컬 스킬을 번역 없이 복사합니다.
서브모듈이 없으면 부모 저장소에 기록된 커밋으로 초기화하고, `skills/skills/` 아래의 언어별 하위 디렉터리까지 스킬을 탐색합니다.

## 라이선스
이 프로젝트는 [MIT License](./LICENSE)에 따라 배포됩니다.

### 크레딧

이 프로젝트는 아래의 프로젝트에서 코드 혹은 문서 일부를 발췌했습니다.

| 프로젝트 이름          | 라이선스  | 대상 파일                                                |
| ---------------------- | :-------: | -------------------------------------------------------- |
| [snflkd/fluent-korean] | MIT       | [omp/agent/PERSONALITY.md]                               |
| [ayghri/i-have-adhd]   | MIT       | [omp/agent/APPEND_SYSTEM.md]                             |


<!-- 링크 -->
[snflkd/fluent-korean]: https://github.com/snflkd/fluent-korean
[ayghri/i-have-adhd]: https://github.com/ayghri/i-have-adhd

[omp/agent/PERSONALITY.md]: ./omp/agent/PERSONALITY.md
[omp/agent/APPEND_SYSTEM.md]: ./omp/agent/APPEND_SYSTEM.md
