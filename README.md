# DUNGSIL's dotfiles

개인 설정 파일 저장소

## 시작하기

**윈도우:**
```powershell
sudo pwsh .\install.ps1 # 혹은 관리자 권한의 파워셀에서 실행

sudo pwsh .\install.ps1 -Force # 강제 재생성
```

## Projects 폴더

`install.ps1`은 숨겨진 `$HOME\Projects` 폴더를 가리키는 `$HOME\프로젝트` 정션을 만들고, `desktop.ini`로 탐색기 표시 이름을 "프로젝트"로 바꾸고 폴더 아이콘을 지정합니다.

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
