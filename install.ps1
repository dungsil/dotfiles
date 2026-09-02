# dotfiles 저장소의 설정 파일을 $HOME 하위 실제 경로로 심볼릭 링크 또는 정션으로 연결합니다.
# 심볼릭 링크 생성에는 관리자 권한 또는 개발자 모드가 필요하며, 권한이 없으면 정션 항목만 생성하고 심볼릭 링크는 건너뜁니다.
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
    @{ Source = 'omp\agent\APPEND_SYSTEM.md';  Dest = '.omp\agent\APPEND_SYSTEM.md' }
    @{ Source = 'omp\agent\PERSONALITY.md';    Dest = '.omp\agent\PERSONALITY.md' }
    @{ Source = 'omp\agent\RULES.md';          Dest = '.omp\agent\RULES.md' }
    @{ Source = 'omp\agent\WATCHDOG.yml';      Dest = '.omp\agent\WATCHDOG.yml' }
    @{ Source = 'omp\agent\config.yml';        Dest = '.omp\agent\config.yml' }
    @{ Source = 'omp\agent\models.yml';        Dest = '.omp\agent\models.yml' }
    @{ Source = 'omp\agent\mcp.json';         Dest = '.omp\agent\mcp.json' }
    @{ Source = 'pwsh\Microsoft.PowerShell_profile.ps1';  Dest = 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1' }
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

    # 기존 항목 제거 (실패해도 계속 진행)
    if (Test-Path $destPath) {
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
        New-Item -ItemType $linkType -Path $destPath -Value $sourcePath | Out-Null
        Write-Host "생성됨          $($link.Dest) -> $($link.Source)"
        $created++
    } catch {
        Write-Warning "생성 실패: $($link.Dest) — $($_.Exception.Message)"
        $failed++
    }
}

Write-Host ''
Write-Host "완료: 생성 $created / 건너뜀 $skipped / 실패 $failed"
if ($failed -gt 0) { exit 1 }
