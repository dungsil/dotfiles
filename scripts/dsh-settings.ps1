# DSH 프로필의 YAML 노드를 병합하여 로컬 항목과 !!js 태그를 보존합니다.
function Import-DshYaml {
    $loaded = Get-Module powershell-yaml
    if ($loaded -and $loaded.Version -ne [version]'0.4.12') {
        throw '새 PowerShell에서 powershell-yaml 0.4.12를 사용하십시오.'
    }
    if (-not $loaded) {
        if (-not (Get-Module -ListAvailable powershell-yaml)) {
            throw 'DSH 설정 패치에는 powershell-yaml이 필요합니다. Install-Module powershell-yaml -RequiredVersion 0.4.12 -Scope CurrentUser 명령을 실행하십시오.'
        }
        Import-Module powershell-yaml -RequiredVersion 0.4.12 -ErrorAction Stop
    }
}

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

function Read-CordisPatch([string]$Text) {
    Import-DshYaml
    $stream = [YamlDotNet.RepresentationModel.YamlStream]::new()
    $reader = [System.IO.StringReader]::new($Text)
    try { $stream.Load($reader) } finally { $reader.Dispose() }
    if ($stream.Documents.Count -ne 1 -or
        $stream.Documents[0].RootNode -isnot [YamlDotNet.RepresentationModel.YamlSequenceNode]) {
        throw 'Cordis 패치는 단일 YAML 배열이어야 합니다. 빈 패치는 []로 작성하십시오.'
    }
    return ,$stream.Documents[0].RootNode
}

function Get-CordisField($Node, [string]$Name) {
    if ($Node -isnot [YamlDotNet.RepresentationModel.YamlMappingNode]) { return $null }
    $key = [YamlDotNet.RepresentationModel.YamlScalarNode]::new($Name)
    if ($Node.Children.ContainsKey($key)) { return ,$Node.Children[$key] }
    return $null
}

function Get-CordisIdentity($Node) {
    if ($Node -isnot [YamlDotNet.RepresentationModel.YamlMappingNode]) {
        throw 'Cordis 패치의 각 항목은 YAML 매핑이어야 합니다.'
    }
    $id = Get-CordisField $Node 'id'
    $insert = Get-CordisField $Node 'insert'
    if ($null -ne $id -and $id -isnot [YamlDotNet.RepresentationModel.YamlScalarNode]) {
        throw 'Cordis 항목의 id는 문자열이어야 합니다.'
    }
    if ($null -ne $insert) {
        if ($insert -isnot [YamlDotNet.RepresentationModel.YamlSequenceNode]) {
            throw 'Cordis 항목의 insert는 배열이어야 합니다.'
        }
        return 'insert:' + $id.Value
    }
    if ([string]::IsNullOrWhiteSpace($id.Value)) { throw 'Cordis 항목에는 id 또는 insert가 필요합니다.' }
    return 'id:' + $id.Value
}

function Assert-CordisEntries($Entries) {
    $identities = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($entry in $Entries.Children) {
        $identity = Get-CordisIdentity $entry
        if (-not $identities.Add($identity)) {
            throw "동일한 Cordis 패치 항목이 여러 개여서 병합할 수 없습니다: $identity"
        }
        $insert = Get-CordisField $entry 'insert'
        if ($null -ne $insert) { Assert-CordisEntries $insert }
        $group = Get-CordisField $entry 'group'
        $config = Get-CordisField $entry 'config'
        if ($group.Value -ceq 'true' -and $config -is [YamlDotNet.RepresentationModel.YamlSequenceNode]) {
            Assert-CordisEntries $config
        }
    }
}

function Merge-CordisEntries($Source, $Target) {
    foreach ($sourceEntry in $Source.Children) {
        $identity = Get-CordisIdentity $sourceEntry
        $targetEntry = $null
        foreach ($entry in $Target.Children) {
            if ((Get-CordisIdentity $entry) -ceq $identity) { $targetEntry = $entry; break }
        }
        if ($null -eq $targetEntry) {
            $Target.Add($sourceEntry)
        } else {
            $sourceName = Get-CordisField $sourceEntry 'name'
            $targetName = Get-CordisField $targetEntry 'name'
            if ($null -ne $sourceName -and $null -ne $targetName -and $sourceName.Value -cne $targetName.Value) {
                throw "동일한 Cordis id가 다른 플러그인을 가리킵니다: $identity"
            }
            Merge-CordisMapping $sourceEntry $targetEntry -IsEntry $true
        }
    }
}

function Merge-CordisMapping($Source, $Target, [bool]$IsEntry = $false) {
    foreach ($pair in $Source.Children.GetEnumerator()) {
        $key = $pair.Key
        $sourceValue = $pair.Value
        if ($Target.Children.ContainsKey($key)) {
            $targetValue = $Target.Children[$key]
            if ($sourceValue -is [YamlDotNet.RepresentationModel.YamlMappingNode] -and
                $targetValue -is [YamlDotNet.RepresentationModel.YamlMappingNode]) {
                Merge-CordisMapping $sourceValue $targetValue
                continue
            }
            $group = Get-CordisField $Source 'group'
            if ($IsEntry -and ($key.Value -ceq 'insert' -or ($key.Value -ceq 'config' -and $group.Value -ceq 'true')) -and
                $sourceValue -is [YamlDotNet.RepresentationModel.YamlSequenceNode] -and
                $targetValue -is [YamlDotNet.RepresentationModel.YamlSequenceNode]) {
                Merge-CordisEntries $sourceValue $targetValue
                continue
            }
            $Target.Children[$key] = $sourceValue
        } else {
            $Target.Add($key, $sourceValue)
        }
    }
}

function ConvertTo-CordisText($Root) {
    $stream = [YamlDotNet.RepresentationModel.YamlStream]::new()
    $stream.Add([YamlDotNet.RepresentationModel.YamlDocument]::new($Root))
    $writer = [System.IO.StringWriter]::new()
    try {
        $stream.Save($writer, $false)
        $merged = $writer.ToString().TrimEnd() + [Environment]::NewLine
    } finally { $writer.Dispose() }
    return $merged
}

function Merge-CordisPatchContent([string]$SourceText, [string]$TargetText) {
    $source = Read-CordisPatch $SourceText
    $target = Read-CordisPatch $TargetText
    Assert-CordisEntries $source
    Assert-CordisEntries $target
    $original = ConvertTo-CordisText $target
    Merge-CordisEntries $source $target
    $merged = ConvertTo-CordisText $target
    # 따옴표와 태그까지 비교하여 문자열과 불리언의 구분을 보존합니다.
    if ($merged -ceq $original) { return $TargetText }
    return $merged
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
