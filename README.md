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

### DeepSeek Harness

[dsh/cordis.patch.yml](<dsh/cordis.patch.yml>)은 현재 Desktop 프로필의 설정 사본입니다. 설치 스크립트는 이 파일을 심볼릭 링크가 아닌 Patch로 설치합니다.

DSH 설정을 설치하기 전에 YAML 모듈을 설치하십시오.

```powershell
Install-Module powershell-yaml -RequiredVersion 0.4.12 -Scope CurrentUser
pwsh .\install.ps1
```

- 기본 대상은 `$HOME/.dsh/profiles/desktop/cordis.patch.yml`입니다. `DSH_PROFILE_DIR`을 우선 적용합니다. 이 값이 없으면 `DSH_HOME`과 `DSH_PROFILE`을 적용합니다.
- `dsh` 명령이나 Desktop 실행 파일이 있는 경우에만 설치합니다.
- 같은 `id`의 매핑을 재귀 병합합니다. 저장소의 값이 우선하며, 대상에만 있는 플러그인과 설정 키는 보존합니다.
- `insert`와 `group: true`의 항목은 `id`로 병합합니다. 모델 목록과 같은 일반 배열은 저장소 값으로 교체합니다.
- 중복된 패치 항목이나 다른 플러그인을 가리키는 같은 `id`가 있으면 파일을 바꾸지 않고 오류를 표시합니다.
- `!!js` 태그는 평가하지 않고 보존합니다. 설정이 바뀌면 YAML 서식과 주석은 달라질 수 있으며, 원본은 대상 파일 옆의 `.bak` 파일에 보관합니다.
- `-Force`도 로컬 설정을 보존합니다. `-Capture`는 현재 프로필의 설정을 저장소로 복사합니다. 인증 정보와 세션 기록은 복사하지 않습니다.

이 사본은 플러그인 패키지를 설치하지 않습니다. 같은 패키지를 설치한 프로필에서 설정을 적용하십시오.

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
