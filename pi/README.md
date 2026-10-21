# Pi 설정

`pi`(pi-coding-agent) 설정을 저장합니다. `install.ps1`이 이 디렉터리 파일을 pi 에이전트 디렉터리(기본 `~/.pi/agent`)에 심볼릭 링크로 연결하고, `settings.json`의 `packages` 선언을 `pi update --extensions`로 맞춥니다.

OMP 설정을 기준으로 옮겼으므로, omp(oh-my-pi)와 pi를 병행해서 씁니다. 대응 기능이 없는 omp 전용 설정은 옮기지 않았습니다.

## 파일 대응

| Pi 파일 | OMP 원본 | 비고 |
| --- | --- | --- |
| `agent/AGENTS.md` | `omp/agent/RULES.md` + `omp/agent/PERSONALITY.md` | Pi에는 별도 규칙 파일이 없어 사용자 지침 파일 하나로 합쳤습니다. |
| `agent/APPEND_SYSTEM.md` | `omp/agent/APPEND_SYSTEM.md` | 동일합니다. |
| `agent/settings.json` | `omp/agent/config.yml`의 Pi 지원 항목 | 아래 "옮긴 설정" 참고. |
| `agent/models.json` | `omp/agent/models.yml` | `tailscale` 엔드포인트와 모델 22개를 옮겼습니다. |
| `agent/i-have-adhd.json` | `omp/agent/i-have-adhd.json` | i-have-adhd 확장이 `getAgentDir()` 아래에서 읽습니다. |
| `agent/extensions/gg-guard.ts` | `omp/agent/extensions/gg-guard.ts` | Pi의 셸 도구는 `bash`, `powershell`입니다. |
| `agent/extensions/session-header.ts` | `omp/agent/extensions/session-header.ts` | Pi에는 `session_switch`/`session_branch` 이벤트가 없어 `session_start`/`session_tree`만 처리하고, 세션 ID는 세션 파일 이름에서 얻습니다. |

## 옮긴 설정

`settings.json`은 omp `config.yml`과 `models.yml` 중 Pi에 대응 항목이 있는 설정만 담습니다.

- `packages`: 문자열 배열로 선언합니다. `pi install`이 설정을 다시 쓸 때도 이 형태를 유지하므로 파일이 불필요하게 바뀌지 않습니다. Pi는 설치 상태를 따로 기록하지 않고 이 선언을 기준으로 checkout을 맞추므로, 존재 여부를 읽기만 하는 방법은 없습니다(`pi list`조차 복원을 수행합니다). 그래서 동기화는 `pi update --extensions`로 합니다.
- `defaultProvider`, `defaultModel`, `defaultThinkingLevel`, `modelThinkingLevels`: omp `modelRoles.default`(기본 모델과 그 추론 레벨)를 옮겼습니다. Pi는 `defaultModel`을 모델 ID로만 읽으므로 공급자는 `defaultProvider`에 따로 적습니다. `tailscale/claude-opus-5-5`처럼 공급자를 붙여 적으면 Pi가 기본 모델을 찾지 못하고 목록의 첫 모델로 시작합니다. `modelThinkingLevels`에는 `models.yml`의 모델별 `thinking.defaultLevel`도 옮겼습니다. Pi에는 omp의 모델 역할 개념이 없어 `smol`, `slow`, `plan`을 포함한 나머지 역할 12개의 모델은 옮기지 않았습니다.
- `defaultTools`: omp에서 기본 켜짐인 검색 도구(`grep`, `glob`)를 Pi의 `grep`, `find`로 옮겼습니다. 기본 셸 도구는 Pi 기본값인 `bash`를 그대로 두었습니다. Windows에서 PowerShell을 쓰려면 `["-bash", "+powershell"]`로 바꿉니다.
- `hideThinkingBlock`, `steeringMode`, `compaction.keepRecentTokens`, `images.autoResize`, `terminal.showImages`, `retry.maxRetries`: 같은 이름의 omp 값 그대로입니다.

`settings.json`은 심볼릭 링크이므로 `pi install`이 패키지 선언을 추가하거나 Pi가 `lastChangelogVersion` 같은 키를 기록하면 저장소 파일에도 그대로 반영됩니다. 그 변경을 정리해 두려면 `install.ps1 -Capture`로 다시 캡처한 뒤 커밋합니다.

`models.json`에는 `id`, `name`, `reasoning`, `maxTokens`, `contextWindow`, `input`, 모델별 `api`, `cost`와 추론 설정을 옮겼습니다. `apiKey`는 Pi가 사용자 정의 엔드포인트를 `/model`에 노출하려면 값이 반드시 필요하므로, omp의 `auth: none` 대신 더미 값 `"none"`을 넣었습니다. 게이트웨이는 이 값을 무시합니다.

omp `models.yml`의 `thinking` 블록은 아래와 같이 옮겼습니다. 이 설정이 없으면 Pi는 `xhigh`와 `max`를 숨깁니다. 그러면 Pi가 `defaultThinkingLevel: max`를 모델이 지원하는 가장 높은 레벨인 `high`로 낮춥니다.

| omp `models.yml` | Pi 설정 | 설명 |
| --- | --- | --- |
| `thinking.efforts` | `thinkingLevelMap` | Pi는 `xhigh`와 `max`를 문자열 값으로 적은 모델에만 노출합니다. `minimal`부터 `high`까지는 Pi가 기본으로 노출합니다. 그래서 이 범위에서 `efforts`에 없는 레벨은 `null`을 적어 숨깁니다. |
| `thinking.mode: anthropic-adaptive` | `compat.forceAdaptiveThinking: true` | 이 값이 없으면 Pi는 Claude 요청에 `output_config.effort` 대신 `budget_tokens`를 보냅니다. |
| `thinking.requiresEffort: true` | `thinkingLevelMap.off: null` | 추론을 끌 수 없는 모델에서 Pi가 `off`를 숨깁니다. |
| `thinking.defaultLevel` | `settings.json`의 `modelThinkingLevels` | Pi는 시작할 때와 모델을 전환할 때 이 값을 `defaultThinkingLevel`보다 먼저 적용합니다. |

`thinking` 블록이 없는 모델은 omp가 모델 ID를 보고 정한 추론 레벨 목록을 기준으로 삼았습니다. 이 목록은 `omp models tailscale --json` 출력에 있는 `thinking` 필드로 확인합니다.

Claude 모델에는 `baseUrl`을 `https://ai.gila-map.ts.net`으로 따로 지정했습니다. Pi는 이 값을 Anthropic SDK에 그대로 넘깁니다. SDK는 이 값 뒤에 `/v1/messages`를 붙여 요청합니다. 공급자의 `baseUrl`(`https://ai.gila-map.ts.net/v1`)을 그대로 쓰면 SDK가 `/v1/v1/messages`로 요청하고, 게이트웨이가 404를 반환합니다. omp는 `baseUrl` 끝의 `/v1`을 지운 뒤 경로를 붙이므로 같은 값으로도 동작합니다.

## 옮기지 않은 항목

Pi에 대응 기능이 없어 제외했습니다.

- 모델 역할과 `retry.fallbackChains`, `cycleOrder`: Pi에는 역할과 폴백 체인이 없습니다. `cycleOrder`는 순환 순서를 역할 이름으로 정하므로 그대로 옮길 수 없습니다. Pi에서 `Ctrl+P`로 순환할 모델과 그 순서는 `settings.json`의 `enabledModels`에 모델 패턴으로 적습니다.
- `TITLE_SYSTEM.md`: Pi는 세션 제목을 자동 생성하지 않습니다. `session-name.ts` 예제 확장이나 `/name`으로 대체할 수 있습니다.
- `WATCHDOG.yml`, `advisor`, `autolearn`, `memory`/`mnemopi`, `checkpoint`, `gc`, `isolation`, `task` 하위 설정: Pi에 대응 기능이 없습니다.
- `tools.approvalMode: yolo`: Pi에는 승인을 저장하는 설정이 없고 실행마다 `--auto-approve`를 써야 합니다.
- `bash.patterns` 거부 목록(`scoop install`, `winget install`, `git config set`을 포함한 패턴 8개): Pi에는 명령 패턴별 승인 설정이 없습니다.
- `eval-guard.ts`: Pi에는 `eval` 도구가 없고, `codemode` 스크립트는 Node·파일·네트워크 접근이 없는 QuickJS 샌드박스라 셸을 우회하지 못합니다.
- `vibe-prompt.ts`: omp의 `vibe_spawn` 도구와 `vibe-additional-guidelines` 흐름이 Pi에 없습니다.
- `theme.dark: titanium`: Pi 기본 제공 테마는 `system`, `dark`, `light`뿐입니다.
- `edit.mode: hashline`, `composer`, `statusLine`, `symbolPreset`, `browser`, `computer`, `python`, `speech`, `lsp`, `git`, `commit`, `power`, `dev`, `secrets`, `providers`, `exa`, `features`, `tier`, `disabledProviders`: 모두 omp 전용입니다.
- 모델별 `tokenizer`, `compat.supportsForcedToolChoice`: Pi `models.json`에 대응 필드가 없습니다. 게이트웨이가 강제 도구 선택을 받지 않는다면 `agent/extensions/` 아래에 공급자 확장을 추가해야 합니다.

`agent/models.json`의 `apiKey`는 비밀 값이 아닌 더미 문자열입니다. 실제 키가 필요하면 `$NAME` 형태로 환경 변수나 `!command`를 씁니다.
