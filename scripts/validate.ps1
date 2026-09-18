[CmdletBinding()]
param(
    [switch]$SkipYaml
)

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$yamlFiles = @(
    'omp/agent/config.yml',
    'omp/agent/models.yml',
    'omp/agent/WATCHDOG.yml'
)
$requiredJsonFiles = @(
    'skills-lock.json',
    'omp/agent/mcp.json',
    'omp/agent/i-have-adhd.json',
    'codex/models_tailscale.json',
    'pi/agent/models.json',
    'pi/agent/settings.json',
    'vscode/settings.json'
)
$script:passedCount = 0
$script:failedCount = 0

function Add-Passed {
    [void]($script:passedCount += 1)
}

function Add-Failure {
    param(
        [string]$Check,
        [string]$File,
        [string]$Detail
    )

    [void]($script:failedCount += 1)
    Write-Host "검사 실패: $Check — $($File): $Detail"
}

function Get-RepositoryRelativePath {
    param([string]$Path)

    return ([IO.Path]::GetRelativePath($repositoryRoot, $Path) -replace '\\', '/')
}

function Get-RepositoryPath {
    param([string]$RelativePath)

    return (Join-Path $repositoryRoot $RelativePath)
}

function Read-Utf8Text {
    param([string]$Path)

    return [IO.File]::ReadAllText($Path, $utf8NoBom)
}

function Get-FrontmatterInfo {
    param([string]$Content)

    $lines = [regex]::Split($Content, "`r?`n")
    $closingIndex = -1

    for ($index = 1; $index -lt $lines.Count; $index += 1) {
        if ($lines[$index] -ceq '---') {
            $closingIndex = $index
            break
        }
    }

    $frontmatterLines = @()
    if ($closingIndex -gt 1) {
        $frontmatterLines = @($lines[1..($closingIndex - 1)])
    }

    return [PSCustomObject]@{
        Lines            = $lines
        HasOpening       = $lines.Count -gt 0 -and $lines[0] -ceq '---'
        ClosingIndex     = $closingIndex
        FrontmatterLines = $frontmatterLines
    }
}

function Get-SkillFiles {
    $skillRoots = @(
        (Join-Path $repositoryRoot 'skills/skills'),
        (Join-Path $repositoryRoot 'skills-raw'),
        (Join-Path $repositoryRoot '.agents/skills')
    )
    $files = @()

    foreach ($skillRoot in $skillRoots) {
        if (Test-Path -LiteralPath $skillRoot -PathType Container) {
            $files += Get-ChildItem -LiteralPath $skillRoot -Filter 'SKILL.md' -File -Recurse -ErrorAction Stop
        }
    }

    return @($files | Sort-Object -Property FullName -Unique)
}

function Test-SkillFrontmatter {
    param([IO.FileInfo]$SkillFile)

    $relativePath = Get-RepositoryRelativePath $SkillFile.FullName

    try {
        $frontmatter = Get-FrontmatterInfo (Read-Utf8Text $SkillFile.FullName)
    } catch {
        Add-Failure 'SKILL.md 프런트매터' $relativePath $_.Exception.Message
        return
    }

    $passed = $true
    if (-not $frontmatter.HasOpening) {
        Add-Failure 'SKILL.md 프런트매터' $relativePath '첫 줄이 정확히 ---가 아닙니다.'
        $passed = $false
    }

    if ($frontmatter.ClosingIndex -lt 0) {
        Add-Failure 'SKILL.md 프런트매터' $relativePath '닫는 --- 구분자가 없습니다.'
        $passed = $false
    }

    if ($frontmatter.HasOpening -and $frontmatter.ClosingIndex -ge 0) {
        $frontmatterText = $frontmatter.FrontmatterLines -join "`n"
        if (-not [regex]::IsMatch($frontmatterText, '(?m)^\s*name\s*:')) {
            Add-Failure 'SKILL.md 프런트매터' $relativePath 'name: 키가 없습니다.'
            $passed = $false
        }

        if (-not [regex]::IsMatch($frontmatterText, '(?m)^\s*description\s*:')) {
            Add-Failure 'SKILL.md 프런트매터' $relativePath 'description: 키가 없습니다.'
            $passed = $false
        }
    }

    if ($passed) {
        Add-Passed
    }
}

function Get-RelativeMarkdownLinks {
    param([string]$Content)

    $markdown = [regex]::Replace($Content, '(?s)```.*?```|~~~.*?~~~', '')
    foreach ($match in [regex]::Matches($markdown, '\]\((?<target>[^)\r\n]+)\)')) {
        $target = $match.Groups['target'].Value.Trim()
        if ($target -match '^<(?<path>[^>]+)>$') {
            $target = $Matches.path
        }

        $targetPath = $target -replace '[?#].*$', ''
        if ([string]::IsNullOrWhiteSpace($targetPath)) {
            continue
        }

        if ($targetPath.StartsWith('/') -or $targetPath.StartsWith('\\') -or
            $targetPath -match '^[A-Za-z][A-Za-z0-9+.-]*:') {
            continue
        }

        $targetPath
    }
}

function Test-SkillLinks {
    param([IO.FileInfo]$SkillFile)

    $relativePath = Get-RepositoryRelativePath $SkillFile.FullName

    try {
        $content = Read-Utf8Text $SkillFile.FullName
        $links = @(Get-RelativeMarkdownLinks $content)
    } catch {
        Add-Failure '상대 링크' $relativePath $_.Exception.Message
        return
    }

    if ($links.Count -eq 0) {
        Add-Passed
        return
    }

    foreach ($link in $links) {
        try {
            $targetPath = [IO.Path]::GetFullPath((Join-Path $SkillFile.DirectoryName $link))
            if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
                Add-Failure '상대 링크' $relativePath "대상 파일을 찾을 수 없습니다 ($link)."
                continue
            }

            Add-Passed
        } catch {
            Add-Failure '상대 링크' $relativePath "$($link): $($_.Exception.Message)"
        }
    }
}

function Get-GitTrackedFiles {
    $trackedFiles = @(& git -C $repositoryRoot ls-files)
    if ($LASTEXITCODE -ne 0) {
        throw "git ls-files가 종료 코드 $LASTEXITCODE(으)로 끝났습니다."
    }

    return $trackedFiles
}

function Test-TrailingNewlines {
    param([string[]]$TrackedFiles)

    foreach ($relativePath in $TrackedFiles) {
        if ($relativePath -notmatch '(?i)(\.(md|json|yml|yaml|toml|ts|ps1)$|(^|/)\.editorconfig$|(^|/)\.gitconfig$)') {
            continue
        }

        try {
            $path = Get-RepositoryPath $relativePath
            $bytes = [IO.File]::ReadAllBytes($path)
            if ($bytes.Length -eq 0 -or $bytes[$bytes.Length - 1] -ne 10) {
                Add-Failure '끝줄 줄바꿈' $relativePath '마지막 바이트가 LF(0x0A)가 아닙니다.'
                continue
            }

            Add-Passed
        } catch {
            Add-Failure '끝줄 줄바꿈' $relativePath $_.Exception.Message
        }
    }
}

function Test-AgentSkillsIgnored {
    $agentSkillsPath = Join-Path $repositoryRoot '.agents/skills'
    if (-not (Test-Path -LiteralPath $agentSkillsPath -PathType Container)) {
        return $true
    }

    $null = & git -C $repositoryRoot check-ignore -q -- '.agents/skills'
    return $LASTEXITCODE -eq 0
}

function Get-EnglishDistributionFiles {
    $agentSkillsPath = Join-Path $repositoryRoot '.agents/skills'
    if (-not (Test-Path -LiteralPath $agentSkillsPath -PathType Container) -or (Test-AgentSkillsIgnored)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $agentSkillsPath -Filter '*.md' -File -Recurse -ErrorAction Stop |
        Sort-Object -Property FullName -Unique)
}

function Get-HangulInspectionText {
    param([string]$Content)

    $frontmatter = Get-FrontmatterInfo $Content
    if (-not $frontmatter.HasOpening -or $frontmatter.ClosingIndex -lt 0) {
        return $Content
    }

    $frontmatterText = $frontmatter.FrontmatterLines -join "`n"
    if (-not [regex]::IsMatch($frontmatterText, '(?im)^\s*disable-model-invocation\s*:\s*true\s*(?:#.*)?$')) {
        return $Content
    }

    $inspectionLines = @()
    for ($index = 0; $index -lt $frontmatter.Lines.Count; $index += 1) {
        $line = $frontmatter.Lines[$index]
        if ($index -gt 0 -and $index -lt $frontmatter.ClosingIndex -and
            $line -match '^\s*description\s*:') {
            continue
        }

        $inspectionLines += $line
    }

    return $inspectionLines -join "`n"
}

function Test-EnglishDistributionHangul {
    try {
        $distributionFiles = @(Get-EnglishDistributionFiles)
    } catch {
        Add-Failure '한글 배포본' '.agents/skills' $_.Exception.Message
        return
    }

    foreach ($file in $distributionFiles) {
        $relativePath = Get-RepositoryRelativePath $file.FullName

        try {
            $inspectionText = Get-HangulInspectionText (Read-Utf8Text $file.FullName)
            if ([regex]::IsMatch($inspectionText, '[\uAC00-\uD7AF]')) {
                Add-Failure '한글 배포본' $relativePath '허용되지 않은 한글이 포함되어 있습니다.'
                continue
            }

            Add-Passed
        } catch {
            Add-Failure '한글 배포본' $relativePath $_.Exception.Message
        }
    }
}

function Test-JsonFiles {
    param([string[]]$TrackedFiles)

    $jsonFiles = @(
        $requiredJsonFiles + ($TrackedFiles | Where-Object { $_ -match '(?i)\.json$' }) |
            Sort-Object -Unique
    )

    foreach ($relativePath in $jsonFiles) {
        try {
            $content = Read-Utf8Text (Get-RepositoryPath $relativePath)
            $previousPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Stop'
                $null = ConvertFrom-Json -InputObject $content -ErrorAction Stop
            } finally {
                $ErrorActionPreference = $previousPreference
            }

            Add-Passed
        } catch {
            Add-Failure 'JSON 구문' $relativePath $_.Exception.Message
        }
    }
}

function Test-YamlFiles {
    if ($SkipYaml -or -not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Warning '경고: powershell-yaml 모듈이 없어 YAML 검사를 건너뜁니다.'
        return
    }

    try {
        Import-Module powershell-yaml -ErrorAction Stop
    } catch {
        Add-Failure 'YAML 모듈' 'powershell-yaml' $_.Exception.Message
        return
    }

    foreach ($relativePath in $yamlFiles) {
        try {
            $content = Read-Utf8Text (Get-RepositoryPath $relativePath)
            $previousPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Stop'
                $null = $content | ConvertFrom-Yaml -ErrorAction Stop
            } finally {
                $ErrorActionPreference = $previousPreference
            }

            Add-Passed
        } catch {
            Add-Failure 'YAML 구문' $relativePath $_.Exception.Message
        }
    }
}

function Invoke-InstallSkillsTests {
    $relativePath = 'tests/install-skills.Tests.ps1'
    $testPath = Get-RepositoryPath $relativePath
    if (-not (Test-Path -LiteralPath $testPath -PathType Leaf)) {
        return
    }

    try {
        $output = @(& pwsh -NoProfile -File $testPath 2>&1)
        if ($LASTEXITCODE -ne 0) {
            $detail = ($output | Out-String).Trim()
            if ([string]::IsNullOrWhiteSpace($detail)) {
                $detail = "종료 코드 $LASTEXITCODE"
            }
            Add-Failure '단위 테스트' $relativePath $detail
            return
        }

        Add-Passed
    } catch {
        Add-Failure '단위 테스트' $relativePath $_.Exception.Message
    }
}

$trackedFiles = @()
try {
    $trackedFiles = @(Get-GitTrackedFiles)
    Add-Passed
} catch {
    Add-Failure '추적 파일 목록' 'git ls-files' $_.Exception.Message
}

try {
    $skillFiles = @(Get-SkillFiles)
} catch {
    Add-Failure 'SKILL.md 검색' 'skills' $_.Exception.Message
    $skillFiles = @()
}

foreach ($skillFile in $skillFiles) {
    Test-SkillFrontmatter $skillFile
    Test-SkillLinks $skillFile
}

Test-TrailingNewlines $trackedFiles
Test-EnglishDistributionHangul
Test-JsonFiles $trackedFiles
Test-YamlFiles
Invoke-InstallSkillsTests

Write-Host "검사 완료: 통과 $script:passedCount / 실패 $script:failedCount"
if ($script:failedCount -eq 0) {
    exit 0
}

exit 1
