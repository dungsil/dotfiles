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

## 코딩 에이전트 설정

`omp/`와 `pi/`가 각각 oh-my-pi와 pi 설정을 담습니다. `pi/`는 omp 설정을 기준으로 옮긴 것이며, 옮긴 항목과 옮기지 않은 항목은 [pi/README.md](./pi/README.md)에 정리했습니다.

## 라이선스
이 프로젝트는 [MIT License](./LICENSE)에 따라 배포됩니다.

### 크레딧

이 프로젝트는 아래의 프로젝트에서 코드 혹은 문서 일부를 발췌했습니다.

| 프로젝트 이름          | 라이선스  | 대상 파일                                               |
| ---------------------- | :-------: | ------------------------------------------------------- |
| [snflkd/fluent-korean] | MIT       | [omp/agent/PERSONALITY.md], [pi/agent/AGENTS.md]        |
| [ayghri/i-have-adhd]   | MIT       | [omp/agent/APPEND_SYSTEM.md], [pi/agent/APPEND_SYSTEM.md] |


<!-- 링크 -->
[snflkd/fluent-korean]: https://github.com/snflkd/fluent-korean
[ayghri/i-have-adhd]: https://github.com/ayghri/i-have-adhd

[omp/agent/PERSONALITY.md]: ./omp/agent/PERSONALITY.md
[omp/agent/APPEND_SYSTEM.md]: ./omp/agent/APPEND_SYSTEM.md
[pi/agent/AGENTS.md]: ./pi/agent/AGENTS.md
[pi/agent/APPEND_SYSTEM.md]: ./pi/agent/APPEND_SYSTEM.md
