function Get-NativeSkillCliContent([string]$Content, [string]$RelativePath) {
    $path = $RelativePath.Replace('\', '/')
    if ($path -notmatch '\.(md|json)$' -or $path -match '(^|/)gg(/|$)' -or
        $Content -cnotmatch '(?<![A-Za-z0-9_])gg(?![A-Za-z0-9_])') {
        return $Content
    }

    $fileCli = switch -Regex ($path) {
        '(^|/)issue-tracker-github\.md$' { 'gh'; break }
        '(^|/)issue-tracker-gitlab\.md$' { 'glab'; break }
        default { '' }
    }

    # API 응답의 필드 선택 정책만 남기고 CLI의 기능이 없다는 주장은 제거합니다.
    $Content = $Content.Replace(
        '(`gg api`에는 `--jq` 플래그가 없어 파이프로 넘긴다)',
        '(API 응답은 파이프로 `jq`에 넘겨 필요한 필드를 선택한다)'
    )

    if ($path -match '(^|/)vibe-init/SKILL\.md$') {
        $Content = $Content.Replace(
            '`gg issue create`를 호출할지',
            '`gh issue create` 또는 `glab issue create`를 호출할지'
        )
    }

    $Content = $Content.Replace(
        '두 트래커 모두 `gg api`로',
        '두 트래커 모두 `gh api` 또는 `glab api`로'
    )

    $blockCli = $fileCli
    $result = [Text.StringBuilder]::new()
    foreach ($line in [regex]::Split($Content, '(\r\n|\n|\r)')) {
        if ($line -match '^(\r\n|\n|\r)$') {
            [void]$result.Append($line)
            continue
        }

        # 혼합 문서는 제공자별 목록과 평가 항목의 문맥을 다음 줄에도 유지합니다.
        if (-not $fileCli) {
            if ($line -match '^\s*(?:#{1,6}\s+|[-*]\s+\*\*)(?<provider>GitHub|GitLab)\b') {
                $blockCli = if ($Matches.provider -eq 'GitLab') { 'glab' } else { 'gh' }
            } elseif ($line -match '"id"\s*:\s*"(?<id>[^"\\]*)"') {
                $blockCli = switch -Regex ($Matches.id) {
                    '(^|-)github(-|$)' { 'gh'; break }
                    '(^|-)gitlab(-|$)' { 'glab'; break }
                    default { '' }
                }
            }
        }

        $converted = [regex]::Replace($line, '(?<![A-Za-z0-9_])gg(?![A-Za-z0-9_])', {
            param($match)

            $cli = if ($fileCli) { $fileCli } elseif ($blockCli) { $blockCli } else { 'gh' }
            $prefix = $line.Substring(0, $match.Index)
            $suffix = $line.Substring($match.Index + $match.Length)
            $command = [regex]::Match($suffix, '^\s+(?<command>[^`\r\n]*)').Groups['command'].Value

            if (-not $fileCli) {
                $providers = [regex]::Matches($prefix, '(?i)(?<![A-Za-z0-9_])(GitHub|GitLab)(?![A-Za-z0-9_])')
                if ($providers.Count -gt 0) {
                    $cli = if ($providers[-1].Value -ieq 'GitLab') { 'glab' } else { 'gh' }
                }
            }

            # 명령 자체가 제공자를 확정하면 주변의 비교 설명보다 우선합니다.
            if ($command -match '^(?:status|diff|log|show|add|commit|push|pull|fetch|clone|init|remote|branch|switch|checkout|restore|reset|rebase|merge|rev-parse|rev-list|ls-remote|ls-files|worktree|config|tag|stash|cherry-pick|reflog|clean|rm|mv|submodule|grep|bisect|blame|describe|cat-file|update-index|symbolic-ref)(?:\s|$)') {
                $cli = 'git'
            } elseif ($command -match '^pr(?:\s|$)') {
                $cli = 'gh'
            } elseif ($command -match '^mr(?:\s|$)') {
                $cli = 'glab'
            } elseif ($command -match '^api\b.*?(?<endpoint>repos/|projects/)') {
                $cli = if ($Matches.endpoint -eq 'projects/') { 'glab' } else { 'gh' }
            } elseif ($command -match '^issue\s+(?:update|note)(?:\s|$)') {
                $cli = 'glab'
            } elseif ($command -match '^issue\s+(?:edit|comment)(?:\s|$)') {
                $cli = 'gh'
            } elseif ($command -match '^issue\b.*\s(?:--description|--message|-F)(?:[=\s]|$)') {
                $cli = 'glab'
            } elseif ($command -match '^issue\b.*\s(?:--body|--comment|--json)(?:[=\s]|$)') {
                $cli = 'gh'
            }

            return $cli
        })
        [void]$result.Append($converted)
    }

    return $result.ToString()
}
