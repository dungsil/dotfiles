# dotfiles 저장소의 설정 파일을 $HOME 하위 실제 경로로 심볼릭 링크, 정션, 복사(Copy) 또는 설정 병합 패치(Patch)로 연결합니다.
# 심볼릭 링크 생성에는 관리자 권한 또는 개발자 모드가 필요하며, 권한이 없으면 정션, 복사, 패치 항목만 처리하고 심볼릭 링크는 건너뜁니다.
#
# 사용법:
#   ./install.ps1                 # 스킬 동기화 및 누락되었거나 대상이 다른 링크 (재)생성
#   ./install.ps1 -Force          # 기존 링크/파일을 모두 지우고 다시 생성
#   ./install.ps1 -SkillsOnly     # 스킬만 동기화
#   ./install.ps1 -Capture        # 도구가 쓴 설정과 OMP 플러그인 의도를 저장소에 캡처
#
# 주의: -Force로 다시 생성하면 omp가 쓴 최신 설정(.omp 쪽)이 저장소 파일로 덮어쓰기 전에 유실될 수 있으니
#       커밋 후에 실행하는 것을 권장합니다.

[CmdletBinding()]
param(
    # 기존 링크가 올바르더라도 전부 지우고 다시 생성합니다.
    [switch]$Force,
    [switch]$SkillsOnly,
    [switch]$Capture
)

$ErrorActionPreference = 'Stop'

if ($Capture -and $Force) {
    Write-Error '오류: -Capture와 -Force는 함께 사용할 수 없습니다.' -ErrorAction Continue
    exit 1
}

# 저장소 기준 경로
$DotfilesRoot = $PSScriptRoot

# 저장소 파일 -> 실제 설치 경로 매핑
$Links = @(
    @{ Source = 'git\.gitconfig';               Dest = '.gitconfig' }
    @{ Source = 'vscode\settings.json';         Dest = 'AppData\Roaming\Code\User\settings.json' }
    @{ Source = '.agents\skills';               Dest = '.agents\skills';                        Type = 'Junction' }
    @{ Source = 'omp\agent\TITLE_SYSTEM.md';   Dest = '.omp\agent\TITLE_SYSTEM.md' }
    @{ Source = 'omp\agent\APPEND_SYSTEM.md';       Dest = '.omp\agent\APPEND_SYSTEM.md' }
    @{ Source = 'omp\agent\PERSONALITY.md';         Dest = '.omp\agent\PERSONALITY.md' }
    @{ Source = 'omp\agent\RULES.md';               Dest = '.omp\agent\RULES.md' }
    @{ Source = 'omp\agent\WATCHDOG.yml';           Dest = '.omp\agent\WATCHDOG.yml' }
    @{ Source = 'omp\agent\config.yml';             Dest = '.omp\agent\config.yml' }
    @{ Source = 'omp\agent\models.yml';             Dest = '.omp\agent\models.yml' }
    @{ Source = 'omp\agent\mcp.json';              Dest = '.omp\agent\mcp.json' }
    @{ Source = 'omp\agent\extensions\vibe-prompt.ts'; Dest = '.omp\agent\extensions\vibe-prompt.ts' }
    @{ Source = 'omp\agent\extensions\session-header.ts'; Dest = '.omp\agent\extensions\session-header.ts' }
    @{ Source = 'omp\agent\extensions\eval-guard.ts'; Dest = '.omp\agent\extensions\eval-guard.ts' }
    @{ Source = 'omp\agent\i-have-adhd.json';          Dest = '.omp\agent\i-have-adhd.json' }
    @{ Source = 'pwsh\Microsoft.PowerShell_profile.ps1';  Dest = 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1' }
    @{ Source = 'codex\AGENTS.md';                       Dest = '.codex\AGENTS.md' }
    @{ Source = 'codex\agents\researcher.toml';          Dest = '.codex\agents\researcher.toml' }
    @{ Source = 'codex\agents\planner.toml';             Dest = '.codex\agents\planner.toml' }
    @{ Source = 'codex\models_tailscale.json';            Dest = '.codex\models_tailscale.json' }
    @{ Source = 'codex\tailscale.config.toml';             Dest = '.codex\tailscale.config.toml' }
    @{ Source = 'codex\config.toml';                       Dest = '.codex\config.toml'; Type = 'Patch' }
)

# OMP 마켓플레이스 및 플러그인 목록
$OmpMarketplaces = @(
    @{ Name = 'i-have-adhd'; Source = 'ayghri/i-have-adhd' }
)

$OmpPlugins = @(
    @{ Target = 'i-have-adhd@i-have-adhd'; Scope = 'user' }
)

# 심볼릭 링크 생성이 가능한 환경(관리자 권한 또는 개발자 모드)인지 판정합니다.
function Test-CanCreateSymbolicLink {
    $identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if ($identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { return $true }

    $devMode = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction SilentlyContinue
    if ($devMode -and $devMode.AllowDevelopmentWithoutDevLicense -eq 1) { return $true }

    $probeDir = Join-Path ([System.IO.Path]::GetTempPath()) ("symlink-probe-" + [guid]::NewGuid())
    try {
        New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
        $targetFile = Join-Path $probeDir 'target.txt'
        $linkFile = Join-Path $probeDir 'link.txt'
        Set-Content -LiteralPath $targetFile -Value 'probe'
        New-Item -ItemType SymbolicLink -Path $linkFile -Value $targetFile -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    } finally {
        if (Test-Path $probeDir) {
            Remove-Item -LiteralPath $probeDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# TOML 병합 함수: SourceText에 정의된 키 및 섹션을 TargetText에 패치합니다.
# 같은 섹션 안에서도 TargetText에만 존재하는 키는 보존합니다.
# 관리 대상 값은 한 줄 값(스칼라, 배열, 인라인 테이블)으로 제한하며 배열 테이블은 로컬에만 둡니다.
function Test-TomlSingleLineValue([string]$valueText) {
    $v = $valueText.TrimStart()
    if ($v -match '^("{3}|''{3})') { return $false }
    if ($v.StartsWith('[')) { return $v.Contains(']') }
    if ($v.StartsWith('{')) { return $v.Contains('}') }
    return $true
}
function Merge-TomlContent([string]$SourceText, [string]$TargetText) {
    $headerPattern = '^\s*(\[+[^\]]+\]+)\s*$'
    $keyPattern = '^\s*([a-zA-Z0-9_\-\.]+)\s*=\s*(.*)$'

    function Parse-Blocks([string]$text) {
        $lines = $text -split '\r?\n'
        $rootLines = [System.Collections.Generic.List[string]]::new()
        $sections = [System.Collections.Generic.List[psobject]]::new()
        $currentHeader = $null
        $currentLines = [System.Collections.Generic.List[string]]::new()

        foreach ($line in $lines) {
            if ($line -match $headerPattern) {
                if ($null -eq $currentHeader) {
                    $rootLines.AddRange($currentLines)
                } else {
                    $sections.Add([PSCustomObject]@{ Header = $currentHeader; Lines = [string[]]$currentLines })
                }
                $currentHeader = $Matches[1].Trim()
                $currentLines = [System.Collections.Generic.List[string]]::new()
                $currentLines.Add($line)
            } else {
                $currentLines.Add($line)
            }
        }
        if ($null -eq $currentHeader) {
            $rootLines.AddRange($currentLines)
        } else {
            $sections.Add([PSCustomObject]@{ Header = $currentHeader; Lines = [string[]]$currentLines })
        }
        return @{ Root = $rootLines; Sections = $sections }
    }

    $src = Parse-Blocks $SourceText
    $tgt = Parse-Blocks $TargetText

    $srcRootKeys = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
    foreach ($line in $src.Root) {
        if ($line -match $keyPattern) {
            if (-not (Test-TomlSingleLineValue $Matches[2])) {
                throw 'TOML 패치는 한 줄 값(스칼라, 배열, 인라인 테이블)만 지원합니다.'
            }
            $srcRootKeys[$Matches[1]] = $line
        }
    }

    $newTgtRoot = [System.Collections.Generic.List[string]]::new()
    $updatedKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

    foreach ($line in $tgt.Root) {
        if ($line -match $keyPattern -and $srcRootKeys.Contains($Matches[1])) {
            if (-not (Test-TomlSingleLineValue $Matches[2])) {
                throw '여러 줄 값은 한 줄 값으로 교체할 수 없습니다.'
            }
            $newTgtRoot.Add($srcRootKeys[$Matches[1]])
            [void]$updatedKeys.Add($Matches[1])
        } else {
            $newTgtRoot.Add($line)
        }
    }

    $missingKeys = [System.Collections.Generic.List[string]]::new()
    foreach ($k in $srcRootKeys.Keys) {
        if (-not $updatedKeys.Contains($k)) {
            $missingKeys.Add($k)
        }
    }
    if ($missingKeys.Count -gt 0) {
        while ($newTgtRoot.Count -gt 0 -and [string]::IsNullOrWhiteSpace($newTgtRoot[$newTgtRoot.Count - 1])) {
            $newTgtRoot.RemoveAt($newTgtRoot.Count - 1)
        }
        foreach ($k in $missingKeys) {
            $newTgtRoot.Add($srcRootKeys[$k])
        }
        $newTgtRoot.Add('')
    }

    $srcSecMap = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
    foreach ($sec in $src.Sections) {
        if ($sec.Header.StartsWith('[[')) {
            throw '배열 테이블은 TOML 패치의 관리 대상으로 지원하지 않습니다.'
        }
        $srcSecMap[$sec.Header] = $sec.Lines
    }

    $newSecs = [System.Collections.Generic.List[psobject]]::new()
    $handledSrcSecs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

    foreach ($sec in $tgt.Sections) {
        if ($srcSecMap.Contains($sec.Header)) {
            $sourceBody = ($srcSecMap[$sec.Header] | Select-Object -Skip 1) -join "`n"
            $targetBody = ($sec.Lines | Select-Object -Skip 1) -join "`n"
            $mergedBody = Merge-TomlContent -SourceText $sourceBody -TargetText $targetBody
            $newSecs.Add([PSCustomObject]@{ Header = $sec.Header; Lines = [string[]](@($sec.Lines[0]) + ($mergedBody.TrimEnd() -split '\r?\n')) })
            [void]$handledSrcSecs.Add($sec.Header)
        } else {
            $newSecs.Add($sec)
        }
    }

    foreach ($hdr in $srcSecMap.Keys) {
        if (-not $handledSrcSecs.Contains($hdr)) {
            $newSecs.Add([PSCustomObject]@{ Header = $hdr; Lines = $srcSecMap[$hdr] })
        }
    }

    $resultLines = [System.Collections.Generic.List[string]]::new()
    $resultLines.AddRange($newTgtRoot)

    foreach ($sec in $newSecs) {
        if ($resultLines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($resultLines[$resultLines.Count - 1])) {
            $resultLines.Add('')
        }
        $resultLines.AddRange($sec.Lines)
    }

    return ($resultLines -join [System.Environment]::NewLine).Trim() + [System.Environment]::NewLine
}

# 심볼릭 링크 또는 정션이 가리키는 실제 대상 경로를 정규화해서 반환합니다.
function Resolve-LinkTarget([System.IO.FileSystemInfo]$Item) {
    if ($Item.LinkType -notin @('SymbolicLink', 'Junction')) { return $null }
    $target = $Item.Target
    if ($target -is [array]) { $target = $target[0] }
    if ([string]::IsNullOrEmpty($target)) { return $null }
    if ([System.IO.Path]::IsPathRooted($target)) { return $target }
    return $Item.Directory.FullName + [System.IO.Path]::DirectorySeparatorChar + $target
}

# 기존 항목이 지정된 유형과 대상으로 연결된 유효한 링크인지 판정합니다.
function Test-UpToDate([string]$SourcePath, [string]$DestPath, [string]$LinkType) {
    if (-not (Test-Path $DestPath)) { return $false }
    if ($LinkType -eq 'Copy') { return $true }
    if ($LinkType -eq 'Patch') {
        $srcText = Get-Content -LiteralPath $SourcePath -Raw -Encoding utf8
        $tgtText = Get-Content -LiteralPath $DestPath -Raw -Encoding utf8
        $merged = Merge-TomlContent -SourceText $srcText -TargetText $tgtText
        return ($merged.Trim() -eq $tgtText.Trim())
    }
    $item = Get-Item $DestPath -Force
    if ($item.LinkType -ne $LinkType) { return $false }
    $resolved = Resolve-LinkTarget $item
    return ($resolved -and
            [System.IO.Path]::GetFullPath($SourcePath) -ieq [System.IO.Path]::GetFullPath($resolved) -and
            (Test-Path $resolved))
}

# 외부 스킬은 잠금 파일에서 복원하고 로컬 스킬은 한국어 원본 그대로 배포합니다.
# 복원 결과는 잠금 파일 해시로 관리되는 캐시에 보관하며, 잠금 파일이 변하지 않고 캐시에
# 필요한 스킬이 모두 있으면 네트워크 복원을 건너뛴 뒤 캐시에서 복제합니다.
# 임시 디렉터리에서 복원을 검증한 뒤 설치하므로 다운로드 실패 시 기존 스킬을 보존합니다.
function Sync-AgentSkills([string]$RepositoryRoot) {
    $repositoryPath = [System.IO.Path]::GetFullPath($RepositoryRoot)
    $lockPath = Join-Path $repositoryPath 'skills-lock.json'
    $lock = Get-Content -LiteralPath $lockPath -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
    if ($lock.version -ne 1 -or $lock.skills -isnot [System.Collections.IDictionary]) {
        throw '지원하지 않는 skills-lock.json 형식입니다.'
    }

    $localSkillsRoot = Join-Path $repositoryPath 'skills/skills'
    if (-not (Test-Path -LiteralPath $localSkillsRoot -PathType Container)) {
        git -C $repositoryPath submodule update --init --recursive -- skills
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $localSkillsRoot -PathType Container)) {
            throw 'skills 서브모듈을 초기화하지 못했습니다.'
        }
    }
    $localSkills = @(Get-ChildItem -LiteralPath $localSkillsRoot -Filter SKILL.md -File -Recurse |
        ForEach-Object { $_.Directory })
    if (@($localSkills | Group-Object Name | Where-Object Count -gt 1).Count -gt 0) {
        throw '서브모듈에 같은 디렉터리 이름을 가진 스킬이 여러 개 있습니다.'
    }
    $skillNames = @($lock.skills.Keys) + @($localSkills.Name)
    foreach ($name in $skillNames) {
        if ($name -cnotmatch '^[a-z0-9][a-z0-9-]*$') { throw "잘못된 스킬 디렉터리 이름: $name" }
    }
    foreach ($skill in $localSkills) {
        if ($lock.skills.Contains($skill.Name)) { throw "외부 스킬과 로컬 스킬 이름이 중복됩니다: $($skill.Name)" }
    }
    if ($lock.skills.Count -gt 0 -and -not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
        throw '스킬을 복원하려면 pnpm이 필요합니다.'
    }

    $agentsPath = Join-Path $repositoryPath '.agents'
    $destination = Join-Path $agentsPath 'skills'
    foreach ($path in @($agentsPath, $destination)) {
        $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if ($item -and (-not $item.PSIsContainer -or $item.LinkType)) {
            throw "스킬 배포 경로는 일반 디렉터리여야 합니다: $path"
        }
    }

    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $staging = Join-Path $tempRoot ('dotfiles-skills-' + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $staging | Out-Null
    try {
        Copy-Item -LiteralPath $lockPath -Destination (Join-Path $staging 'skills-lock.json')
        $stagedSkills = Join-Path $staging '.agents/skills'
        New-Item -ItemType Directory -Path $stagedSkills -Force | Out-Null
        $lockHash = (Get-FileHash -LiteralPath $lockPath -Algorithm SHA256).Hash
        $cacheRoot = Join-Path $tempRoot 'dotfiles-external-skills-cache'
        if ($lock.skills.Count -eq 0) {
            Write-Host '외부 스킬이 없어 네트워크 복원을 건너뜁니다.'
        } elseif ((Test-Path -LiteralPath (Join-Path $cacheRoot $lockHash)) -and
            (@($lock.skills.Keys | Where-Object {
                    $cachedSkillPath = Join-Path $cacheRoot $lockHash "$_"
                    (-not (Test-Path -LiteralPath $cachedSkillPath -PathType Container)) -or
                    (-not (Test-Path -LiteralPath (Join-Path $cachedSkillPath 'SKILL.md') -PathType Leaf))
                })).Count -eq 0) {
            $cachedSkills = Join-Path $cacheRoot $lockHash
            foreach ($name in $lock.skills.Keys) {
                Copy-Item -LiteralPath (Join-Path $cachedSkills $name) -Destination (Join-Path $stagedSkills $name) -Recurse
            }
            Write-Host ('외부 스킬 캐시를 사용합니다 (네트워크 복원 건너뜀): ' + $lockHash)
        }
        else {
            Push-Location -LiteralPath $staging
            try {
                pnpm dlx skills experimental_install
                if ($LASTEXITCODE -ne 0) { throw "스킬 복원 명령이 실패했습니다: 종료 코드 $LASTEXITCODE" }
            } finally {
                Pop-Location
            }
            # CLI가 일부 설치 실패에도 종료 코드 0을 반환할 수 있으므로 결과를 확인합니다.
            foreach ($name in $lock.skills.Keys) {
                if (-not (Test-Path -LiteralPath (Join-Path $stagedSkills "$name/SKILL.md") -PathType Leaf)) {
                    throw "잠금 파일에 등록된 스킬을 복원하지 못했습니다: $name"
                }
            }
            New-Item -ItemType Directory -Path (Join-Path $cacheRoot $lockHash) -Force | Out-Null
            foreach ($name in $lock.skills.Keys) {
                $cachedSkill = Join-Path $cacheRoot $lockHash $name
                $item = Get-Item -LiteralPath $cachedSkill -Force -ErrorAction SilentlyContinue
                if ($item -and (-not $item.PSIsContainer -or $item.LinkType)) {
                    Remove-Item -LiteralPath $cachedSkill -Recurse -Force
                }
                Copy-Item -LiteralPath (Join-Path $stagedSkills $name) -Destination $cachedSkill -Recurse
            }
            foreach ($stale in (Get-ChildItem -LiteralPath $cacheRoot -Directory -ErrorAction SilentlyContinue)) {
                if ($stale.Name -cne $lockHash) { Remove-Item -LiteralPath $stale.FullName -Recurse -Force }
            }
            Write-Host ('외부 스킬을 복원했습니다 (캐시 기록 완료): ' + $lockHash)
        }
        foreach ($skill in $localSkills) {
            Copy-Item -LiteralPath $skill.FullName -Destination (Join-Path $stagedSkills $skill.Name) -Recurse
        }

        # 배포 대상 전체를 먼저 확인합니다. 별도로 설치된 다른 스킬은 건드리지 않습니다.
        foreach ($name in $skillNames) {
            $target = [System.IO.Path]::GetFullPath((Join-Path $destination $name))
            if (-not $target.StartsWith($destination + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "스킬 배포 범위를 벗어난 경로입니다: $target"
            }
            $item = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
            if ($item -and (-not $item.PSIsContainer -or $item.LinkType)) {
                throw "기존 스킬 경로는 일반 디렉터리여야 합니다: $target"
            }
        }
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        foreach ($name in $skillNames) {
            $target = Join-Path $destination $name
            if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
            Copy-Item -LiteralPath (Join-Path $stagedSkills $name) -Destination $target -Recurse
        }
        Write-Host "스킬 동기화 완료: 외부 $($lock.skills.Count) / 로컬 $($localSkills.Count)"
    } finally {
        $stagingPath = [System.IO.Path]::GetFullPath($staging)
        if ($stagingPath.StartsWith($tempRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $stagingPath -Recurse -Force
        }
    }
}

if ($Capture) {
    $CapturePairs = @(
        @{ Repo = 'omp\agent\config.yml'; Live = Join-Path $HOME '.omp\agent\config.yml' }
        @{ Repo = 'codex\config.toml';     Live = Join-Path $HOME '.codex\config.toml' }
    )

    $captured = 0
    $skipped = 0
    foreach ($pair in $CapturePairs) {
        $repoPath = Join-Path $DotfilesRoot $pair.Repo
        if (Test-Path -LiteralPath $pair.Live -PathType Leaf) {
            [System.IO.Directory]::CreateDirectory((Split-Path -Parent $repoPath)) | Out-Null
            $liveText = Get-Content -LiteralPath $pair.Live -Raw -Encoding utf8
            [System.IO.File]::WriteAllText($repoPath, $liveText, [System.Text.Encoding]::UTF8)
            Write-Host "캡처됨          $($pair.Repo) <- $($pair.Live)"
            $captured++
        } else {
            Write-Host "건너뜀 (라이브 파일 없음)  $($pair.Repo)"
            $skipped++
        }
    }

    $marketplaces = @()
    $marketplacesPath = Join-Path $HOME '.omp\marketplaces.json'
    if (Test-Path -LiteralPath $marketplacesPath -PathType Leaf) {
        $marketplacesText = Get-Content -LiteralPath $marketplacesPath -Raw -Encoding utf8
        if (-not [string]::IsNullOrWhiteSpace($marketplacesText)) {
            $marketplacesJson = $marketplacesText | ConvertFrom-Json
            $marketplaces = @(
                $marketplacesJson.marketplaces | ForEach-Object {
                    [ordered]@{
                        name = $_.name
                        source = $_.sourceUri
                    }
                }
            )
        }
    }

    $plugins = @()
    $installedPluginsPath = Join-Path $HOME '.omp\plugins\installed_plugins.json'
    if (Test-Path -LiteralPath $installedPluginsPath -PathType Leaf) {
        $installedPluginsText = Get-Content -LiteralPath $installedPluginsPath -Raw -Encoding utf8
        if (-not [string]::IsNullOrWhiteSpace($installedPluginsText)) {
            $installedPluginsJson = $installedPluginsText | ConvertFrom-Json
            if ($null -ne $installedPluginsJson.plugins) {
                $plugins = @(
                    foreach ($property in $installedPluginsJson.plugins.PSObject.Properties) {
                        $entries = @($property.Value)
                        if ($entries.Count -gt 0 -and $null -ne $entries[0]) {
                            [ordered]@{
                                target = $property.Name
                                scope = $entries[0].scope
                            }
                        }
                    }
                )
            }
        }
    }

    $pluginsCapturePath = Join-Path $DotfilesRoot 'omp\plugins.json'
    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $pluginsCapturePath)) | Out-Null
    $pluginsCapture = [ordered]@{
        marketplaces = @($marketplaces)
        plugins = @($plugins)
    }
    $pluginsText = $pluginsCapture | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($pluginsCapturePath, $pluginsText, [System.Text.Encoding]::UTF8)
    Write-Host '캡처됨          omp\plugins.json <- OMP 플러그인 메타데이터'
    $captured++

    Write-Host ''
    Write-Host "캡처 완료: 반영 $captured / 건너뜀 $skipped"
    exit 0
}

Sync-AgentSkills -RepositoryRoot $DotfilesRoot
if ($SkillsOnly) { return }

$canCreateSymlinks = Test-CanCreateSymbolicLink
if (-not $canCreateSymlinks) {
    Write-Host '알림: 관리자 권한이나 개발자 모드가 아니므로 정션(Junction) 항목만 생성하고 심볼릭 링크는 건너뜁니다.' -ForegroundColor Yellow
}

$created = 0
$skipped = 0
$failed = 0
$backupDir = $null
$backedUp = 0


foreach ($link in $Links) {
    $sourcePath = Join-Path $DotfilesRoot $link.Source
    $destPath = Join-Path $HOME $link.Dest
    $linkType = if ($link.ContainsKey('Type')) { $link.Type } else { 'SymbolicLink' }

    if ($linkType -eq 'SymbolicLink' -and -not $canCreateSymlinks) {
        Write-Host "건너뜀 (권한 필요: SymbolicLink)  $($link.Dest)"
        $skipped++
        continue
    }
    if (-not $Force -and (Test-UpToDate $sourcePath $destPath $linkType)) {
        Write-Host "건너뜀 (이미 유효)  $($link.Dest)"
        $skipped++
        continue
    }

    # 기존 항목 제거 (Patch 타입이 아닌 경우에만 삭제 후 재생성)
    if ($linkType -ne 'Patch' -and (Test-Path $destPath)) {
        if ($Force) {
            if ($null -eq $backupDir) {
                $runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
                $backupDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dotfiles-backup-" + $runTimestamp)
                [System.IO.Directory]::CreateDirectory($backupDir) | Out-Null
            }
            $backupPath = Join-Path $backupDir ($link.Dest -replace '[:/\\]', '_')
            Copy-Item -LiteralPath $destPath -Destination $backupPath -Recurse -Force
            $backedUp++
        }
        Remove-Item -LiteralPath $destPath -Force -ErrorAction SilentlyContinue
        if (Test-Path $destPath) {
            Write-Warning "기존 항목 제거 실패: $destPath"
            $failed++
            continue
        }
    }

    $destDir = Split-Path -Parent $destPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    try {
        if ($linkType -eq 'Patch') {
            if (-not (Test-Path $destPath)) {
                Copy-Item -Path $sourcePath -Destination $destPath -Force
                Write-Host "생성됨          $($link.Dest) <- $($link.Source)"
            } else {
                $srcText = Get-Content -LiteralPath $sourcePath -Raw -Encoding utf8
                $tgtText = Get-Content -LiteralPath $destPath -Raw -Encoding utf8
                $merged = Merge-TomlContent -SourceText $srcText -TargetText $tgtText
                [System.IO.File]::WriteAllText($destPath, $merged, [System.Text.Encoding]::UTF8)
                Write-Host "패치됨          $($link.Dest) (로컬 설정 보존 및 변경점 반영)"
            }
        } elseif ($linkType -eq 'Copy') {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "복사됨          $($link.Dest) <- $($link.Source)"
        } else {
            New-Item -ItemType $linkType -Path $destPath -Value $sourcePath | Out-Null
            Write-Host "생성됨          $($link.Dest) -> $($link.Source)"
        }
        $created++
    } catch {
        Write-Warning "생성 실패: $($link.Dest) — $($_.Exception.Message)"
        $failed++
    }
}

Write-Host ''
Write-Host "완료: 생성 $created / 건너뜀 $skipped / 실패 $failed"

# OMP 플러그인 설치 및 등록 상태를 점검하여 미설치 항목을 설치합니다.
function Install-OmpPlugins {
    if (-not (Get-Command omp -ErrorAction SilentlyContinue)) {
        Write-Host '건너뜀 (omp 명령어를 찾을 수 없음)  OMP 플러그인 설치' -ForegroundColor Yellow
        return
    }

    $marketplaces = @($OmpMarketplaces)
    $plugins = @($OmpPlugins)
    $pluginsConfigPath = Join-Path $DotfilesRoot 'omp\plugins.json'
    if (Test-Path -LiteralPath $pluginsConfigPath -PathType Leaf) {
        $pluginsConfig = Get-Content -LiteralPath $pluginsConfigPath -Raw -Encoding utf8 | ConvertFrom-Json
        $marketplaces = @(
            $pluginsConfig.marketplaces | ForEach-Object {
                @{ Name = $_.name; Source = $_.source }
            }
        )
        $plugins = @(
            $pluginsConfig.plugins | ForEach-Object {
                @{ Target = $_.target; Scope = $_.scope }
            }
        )
    }

    Write-Host ''
    Write-Host '--- OMP 플러그인 확인 및 설치 ---' -ForegroundColor Cyan

    $mpFile = Join-Path $HOME '.omp\marketplaces.json'
    $existingMarketplaces = @()
    if (Test-Path $mpFile) {
        try {
            $existingMarketplaces = @((Get-Content -LiteralPath $mpFile -Raw -Encoding utf8 | ConvertFrom-Json).marketplaces.name)
        } catch {}
    }

    foreach ($mp in $marketplaces) {
        if ($existingMarketplaces -notcontains $mp.Name) {
            Write-Host "마켓플레이스 추가: $($mp.Name) ($($mp.Source))"
            omp plugin marketplace add $mp.Source
        } else {
            Write-Host "건너뜀 (이미 등록된 마켓플레이스)  $($mp.Name)"
        }
    }

    $pluginsFile = Join-Path $HOME '.omp\plugins\installed_plugins.json'
    $installedPlugins = @()
    if (Test-Path $pluginsFile) {
        try {
            $json = Get-Content -LiteralPath $pluginsFile -Raw -Encoding utf8 | ConvertFrom-Json
            if ($json.plugins) {
                $installedPlugins = @($json.plugins.PSObject.Properties.Name)
            }
        } catch {}
    }

    foreach ($p in $plugins) {
        if ($installedPlugins -notcontains $p.Target) {
            Write-Host "플러그인 설치: $($p.Target) (Scope: $($p.Scope))"
            omp plugin install --scope $p.Scope $p.Target
        } else {
            Write-Host "건너뜀 (이미 설치된 플러그인)  $($p.Target)"
        }
    }
}

if ($failed -eq 0) {
    Install-OmpPlugins
}
if ($backedUp -gt 0) {
    Write-Host "백업 위치: $backupDir"
}
if ($failed -gt 0) { exit 1 }
