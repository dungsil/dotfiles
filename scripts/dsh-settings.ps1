$script:CordisMergeScript = Join-Path $PSScriptRoot 'merge-cordis-patch.cjs'

function Get-DshProfileName {
    if ([string]::IsNullOrWhiteSpace($env:DSH_PROFILE)) { return 'desktop' }
    if ($env:DSH_PROFILE -notmatch '^[a-zA-Z0-9_-]+$') { throw 'DSH_PROFILE에는 프로필 이름만 지정하십시오.' }
    return $env:DSH_PROFILE
}

function Get-DshProfileHome {
    $override = Get-PathOverride 'DSH_PROFILE_DIR'
    if ($null -ne $override) { return $override }
    return Join-Path (Get-ToolHome 'DSH_HOME' '.dsh') ('profiles\' + (Get-DshProfileName))
}

# 설치된 DSH의 실행 환경과 YAML 라이브러리를 재사용합니다.
function Get-DshYamlRuntime {
    foreach ($root in @(
        (Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness'),
        (Join-Path $env:ProgramFiles 'DeepSeek Harness')
    )) {
        $executable = Join-Path $root 'DeepSeek Harness.exe'
        if (Test-Path -LiteralPath $executable -PathType Leaf) {
            return @{
                Executable = $executable
                Anchor = Join-Path $root 'resources\app.asar\dsh\node_modules\@deepseek-ai\dsh\package.json'
                Electron = $true
            }
        }
    }
    $dsh = Get-Command dsh -ErrorAction SilentlyContinue
    $node = Get-Command node -ErrorAction SilentlyContinue
    if ($dsh -and $node) {
        return @{ Executable = $node.Source; Anchor = $dsh.Source; Electron = $false }
    }
    throw 'DSH 설정 병합에 필요한 실행 환경을 찾지 못했습니다. DeepSeek Harness 설치를 확인하십시오.'
}

function Merge-CordisPatchContent([string]$SourceText, [string]$TargetText) {
    $runtime = Get-DshYamlRuntime
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $runtime.Executable
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.StandardInputEncoding = [Text.UTF8Encoding]::new($false)
    $start.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    $start.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
    if ($runtime.Electron) {
        $start.Environment['ELECTRON_RUN_AS_NODE'] = '1'
        $start.ArgumentList.Add('--expose-internals')
    }
    $start.ArgumentList.Add($script:CordisMergeScript)
    $start.ArgumentList.Add($runtime.Anchor)
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    try {
        $null = $process.Start()
        $output = $process.StandardOutput.ReadToEndAsync()
        $errorOutput = $process.StandardError.ReadToEndAsync()
        $process.StandardInput.Write((@{ source = $SourceText; target = $TargetText } | ConvertTo-Json -Compress))
        $process.StandardInput.Close()
        $process.WaitForExit()
        $merged = $output.GetAwaiter().GetResult()
        $details = $errorOutput.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw "DSH 설정 병합에 실패했습니다: $($details.Trim())" }
        return $merged
    } finally {
        $process.Dispose()
    }
}

# JSON 병합 함수: SourceText에 정의된 키를 TargetText에 패치합니다.
# mappings는 재귀 병합하고, 일반 배열과 스칼라는 SourceText 값으로 교체합니다.
# TargetText에만 존재하는 키는 보존합니다.
function Merge-JsonNode($Source, $Target) {
    foreach ($key in @($Source.Keys)) {
        $sourceValue = $Source[$key]
        if (-not $Target.Contains($key)) {
            $Target.Add($key, $sourceValue)
            continue
        }
        $targetValue = $Target[$key]
        if ($sourceValue -is [System.Collections.IDictionary] -and $targetValue -is [System.Collections.IDictionary]) {
            Merge-JsonNode $sourceValue $targetValue
            continue
        }
        $Target[$key] = $sourceValue
    }
}

function Merge-JsonContent([string]$SourceText, [string]$TargetText) {
    $source = $SourceText | ConvertFrom-Json -AsHashtable
    $target = $TargetText | ConvertFrom-Json -AsHashtable
    if ($source -isnot [System.Collections.IDictionary] -or $target -isnot [System.Collections.IDictionary]) {
        throw 'JSON 패치는 최상위 객체여야 합니다.'
    }
    Merge-JsonNode $source $target
    return ($target | ConvertTo-Json -Depth 32).TrimEnd() + [Environment]::NewLine
}

function Merge-PatchContent([string]$SourcePath, [string]$SourceText, [string]$TargetText) {
    switch ([System.IO.Path]::GetExtension($SourcePath)) {
        '.toml' { return Merge-TomlContent -SourceText $SourceText -TargetText $TargetText }
        '.yml' { return Merge-CordisPatchContent -SourceText $SourceText -TargetText $TargetText }
        '.yaml' { return Merge-CordisPatchContent -SourceText $SourceText -TargetText $TargetText }
        '.json' { return Merge-JsonContent -SourceText $SourceText -TargetText $TargetText }
        default { throw "지원하지 않는 패치 형식입니다: $SourcePath" }
    }
}

function Install-SettingsPatch([string]$SourcePath, [string]$DestPath) {
    $source = [System.IO.Path]::GetFullPath($SourcePath)
    $destination = [System.IO.Path]::GetFullPath($DestPath)
    if ($source -ieq $destination) { throw '패치 원본과 대상은 다른 파일이어야 합니다.' }
    $item = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.PSIsContainer -or ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint))) {
        throw "패치 대상은 링크가 아닌 일반 파일이어야 합니다: $destination"
    }
    $sourceText = [System.IO.File]::ReadAllText($source)
    $targetText = if ($item) { [System.IO.File]::ReadAllText($destination) } else { $sourceText }
    $merged = Merge-PatchContent -SourcePath $source -SourceText $sourceText -TargetText $targetText
    if ($item -and $merged -ceq $targetText) { return }
    $temporary = $destination + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    try {
        [System.IO.File]::WriteAllText($temporary, $merged, [System.Text.UTF8Encoding]::new($false))
        if ($item) {
            if ([System.IO.File]::ReadAllText($destination) -cne $targetText) {
                throw '패치 도중 대상 파일이 바뀌었습니다. 응용 프로그램을 닫고 다시 실행하십시오.'
            }
            $backup = $destination + '.' + [guid]::NewGuid().ToString('N') + '.bak'
            [System.IO.File]::Copy($destination, $backup)
            Write-Host "패치 백업: $backup"
        }
        [System.IO.File]::Move($temporary, $destination, [bool]$item)
    } finally {
        if ([System.IO.File]::Exists($temporary)) { [System.IO.File]::Delete($temporary) }
    }
}

# Desktop의 예약 프로필을 관리할 수 있는 설치본 CLI를 우선 사용합니다.
function Get-DshCliCommand {
    foreach ($root in @(
        (Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness'),
        (Join-Path $env:ProgramFiles 'DeepSeek Harness')
    )) {
        $launcher = Join-Path $root 'resources\runtime\cli\bin\dsh.cmd'
        if (Test-Path -LiteralPath $launcher -PathType Leaf) { return $launcher }
    }
    return (Get-Command dsh -ErrorAction SilentlyContinue)
}

# 프로필의 패키지 상태는 직접 쓰지 않고 DSH CLI로 누락된 플러그인을 설치합니다.
function Install-DshPlugins([string[]]$Packages) {
    if ($Packages.Count -eq 0 -or -not (Test-AppInstalled 'dsh')) { return }

    $profile = Get-DshProfileName
    $profileHome = Get-DshProfileHome
    $manifestPath = Join-Path $profileHome 'package.json'
    $manifest = if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8 | ConvertFrom-Json
    }
    $pending = @(
        foreach ($package in $Packages) {
            $installedManifest = Join-Path $profileHome "node_modules/$package/package.json"
            if ($manifest.dependencies.PSObject.Properties.Name -ccontains $package -and
                (Test-Path -LiteralPath $installedManifest -PathType Leaf)) {
                Write-Host "건너뜀 (이미 설치됨)  DSH 플러그인: $package"
            } else {
                $package
            }
        }
    )
    if ($pending.Count -eq 0) { return }

    # CLI는 DSH_PROFILE_DIR을 읽지 않으므로 다른 프로필에 설치하지 않도록 검사합니다.
    $dshHome = Get-ToolHome 'DSH_HOME' '.dsh'
    $cliProfileHome = Join-Path $dshHome "profiles/$profile"
    $targetPath = [IO.Path]::GetFullPath($profileHome).TrimEnd('\', '/')
    $cliTargetPath = [IO.Path]::GetFullPath($cliProfileHome).TrimEnd('\', '/')
    if ($targetPath -ine $cliTargetPath) {
        throw 'DSH CLI는 임의의 DSH_PROFILE_DIR 경로를 지원하지 않습니다. DSH_HOME/profiles/DSH_PROFILE과 같은 경로를 지정하십시오.'
    }
    $command = Get-DshCliCommand
    if ($null -eq $command) { throw 'DSH 플러그인 설치에 필요한 CLI를 찾지 못했습니다. DeepSeek Harness 설치를 확인하십시오.' }

    Write-Host ''
    Write-Host '--- DSH 플러그인 설치 ---' -ForegroundColor Cyan
    $previousHome = $env:DSH_HOME
    try {
        $env:DSH_HOME = $dshHome
        foreach ($package in $pending) {
            & $command plugin --profile $profile add --yes --ignore-scripts $package
            if ($LASTEXITCODE -ne 0) { throw "DSH 플러그인 설치에 실패했습니다: $package (종료 코드 $LASTEXITCODE)" }
        }
    } finally {
        $env:DSH_HOME = $previousHome
    }
}
