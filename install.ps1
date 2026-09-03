# dotfiles 저장소의 설정 파일을 $HOME 하위 실제 경로로 심볼릭 링크, 정션, 복사(Copy) 또는 설정 병합 패치(Patch)로 연결합니다.
# 심볼릭 링크 생성에는 관리자 권한 또는 개발자 모드가 필요하며, 권한이 없으면 정션, 복사, 패치 항목만 처리하고 심볼릭 링크는 건너뜁니다.
#
# 사용법:
#   scripts/install.ps1            # 누락되었거나 대상이 다른 링크만 (재)생성
#   scripts/install.ps1 -Force     # 기존 링크/파일을 모두 지우고 다시 생성
#
# 주의: -Force로 다시 생성하면 omp가 쓴 최신 설정(.omp 쪽)이 저장소 파일로 덮어쓰기 전에 유실될 수 있으니
#       커밋 후에 실행하는 것을 권장합니다.

[CmdletBinding()]
param(
    # 기존 링크가 올바르더라도 전부 지우고 다시 생성합니다.
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

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
    @{ Source = 'omp\agent\i-have-adhd.json';          Dest = '.omp\agent\i-have-adhd.json' }
    @{ Source = 'pwsh\Microsoft.PowerShell_profile.ps1';  Dest = 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1' }
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
# TargetText에만 존재하는 키/섹션(예: 로컬 머신의 [projects])은 그대로 보존됩니다.
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

    $srcRootKeys = [ordered]@{}
    foreach ($line in $src.Root) {
        if ($line -match $keyPattern) {
            $srcRootKeys[$Matches[1]] = $line
        }
    }

    $newTgtRoot = [System.Collections.Generic.List[string]]::new()
    $updatedKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($line in $tgt.Root) {
        if ($line -match $keyPattern -and $srcRootKeys.Contains($Matches[1])) {
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

    $srcSecMap = [ordered]@{}
    foreach ($sec in $src.Sections) {
        $srcSecMap[$sec.Header] = $sec.Lines
    }

    $newSecs = [System.Collections.Generic.List[psobject]]::new()
    $handledSrcSecs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($sec in $tgt.Sections) {
        if ($srcSecMap.Contains($sec.Header)) {
            $newSecs.Add([PSCustomObject]@{ Header = $sec.Header; Lines = $srcSecMap[$sec.Header] })
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

$canCreateSymlinks = Test-CanCreateSymbolicLink
if (-not $canCreateSymlinks) {
    Write-Host '알림: 관리자 권한이나 개발자 모드가 아니므로 정션(Junction) 항목만 생성하고 심볼릭 링크는 건너뜁니다.' -ForegroundColor Yellow
}

$created = 0
$skipped = 0
$failed = 0

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
if ($failed -gt 0) { exit 1 }

# OMP 플러그인 설치 및 등록 상태를 점검하여 미설치 항목을 설치합니다.
function Install-OmpPlugins {
    if (-not (Get-Command omp -ErrorAction SilentlyContinue)) {
        Write-Host '건너뜀 (omp 명령어를 찾을 수 없음)  OMP 플러그인 설치' -ForegroundColor Yellow
        return
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

    foreach ($mp in $OmpMarketplaces) {
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

    foreach ($p in $OmpPlugins) {
        if ($installedPlugins -notcontains $p.Target) {
            Write-Host "플러그인 설치: $($p.Target) (Scope: $($p.Scope))"
            omp plugin install --scope $p.Scope $p.Target
        } else {
            Write-Host "건너뜀 (이미 설치된 플러그인)  $($p.Target)"
        }
    }
}

Install-OmpPlugins
