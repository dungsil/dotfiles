# 실행: pwsh -NoProfile -File tests/install-skills.Tests.ps1
# 실제 사용자 설정과 네트워크에 접근하지 않고 임시 디렉터리에서 검증합니다.
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $repositoryRoot 'install.ps1'), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
$syncFunction = $ast.Find({
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Sync-AgentSkills'
}, $true)
. ([scriptblock]::Create($syncFunction.Extent.Text))

function Assert-Result($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$fixture = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-skills-test-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path (Join-Path $fixture 'skills-raw/local/assets'),
    (Join-Path $fixture '.agents/skills/remote'), (Join-Path $fixture '.agents/skills/manual') -Force | Out-Null
$lockPath = Join-Path $fixture 'skills-lock.json'
$originalLock = '{"version":1,"skills":{"remote":{"source":"owner/repo","sourceType":"github","skillPath":"skills/remote/SKILL.md","computedHash":"original"}}}'
[IO.File]::WriteAllText($lockPath, $originalLock)
[IO.File]::WriteAllText((Join-Path $fixture 'skills-raw/local/SKILL.md'), "---`nname: local`ndescription: 한국어 스킬`n---`n한국어 원본을 유지합니다.`n")
[IO.File]::WriteAllBytes((Join-Path $fixture 'skills-raw/local/assets/data.bin'), [byte[]](0, 1, 2, 255))
[IO.File]::WriteAllText((Join-Path $fixture '.agents/skills/remote/stale.txt'), 'stale')
[IO.File]::WriteAllText((Join-Path $fixture '.agents/skills/manual/SKILL.md'), 'manual')

$script:mockMode = 'success'
$script:cliCalls = 0
function pnpm {
    Assert-Result (($args -join ' ') -eq 'dlx skills experimental_install') 'Unexpected CLI arguments.'
    $script:cliCalls++
    $global:LASTEXITCODE = 0
    if ($script:mockMode -eq 'nonzero') { $global:LASTEXITCODE = 7; return }
    if ($script:mockMode -eq 'missing') { return }
    New-Item -ItemType Directory -Path '.agents/skills/remote' -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path (Get-Location) '.agents/skills/remote/SKILL.md'), 'restored')
    Set-Content -LiteralPath 'skills-lock.json' -Value '{"changed-by-cli":true}'
}

$originalLocation = (Get-Location).Path
Sync-AgentSkills $fixture
Assert-Result ((Get-Location).Path -eq $originalLocation) 'Working directory changed.'
Assert-Result ((Get-Content -LiteralPath $lockPath -Raw) -ceq $originalLock) 'Repository lock changed.'
Assert-Result (-not (Test-Path -LiteralPath (Join-Path $fixture '.agents/skills/remote/stale.txt'))) 'Stale managed file remains.'
Assert-Result ((Get-Content -LiteralPath (Join-Path $fixture '.agents/skills/manual/SKILL.md') -Raw) -ceq 'manual') 'Unmanaged skill changed.'
foreach ($relativePath in @('SKILL.md', 'assets/data.bin')) {
    $sourceHash = (Get-FileHash -LiteralPath (Join-Path $fixture "skills-raw/local/$relativePath")).Hash
    $installedHash = (Get-FileHash -LiteralPath (Join-Path $fixture ".agents/skills/local/$relativePath")).Hash
    Assert-Result ($sourceHash -ceq $installedHash) 'Local source bytes changed.'
}
Sync-AgentSkills $fixture
Assert-Result ($script:cliCalls -eq 2) 'Repeated synchronization failed.'

foreach ($mode in @('nonzero', 'missing')) {
    $script:mockMode = $mode
    $installedSkill = Join-Path $fixture '.agents/skills/remote/SKILL.md'
    [IO.File]::WriteAllText($installedSkill, 'preserve-existing')
    $rejected = $false
    try { Sync-AgentSkills $fixture } catch { $rejected = $true }
    Assert-Result $rejected "Failure was not reported: $mode"
    Assert-Result ((Get-Content -LiteralPath $installedSkill -Raw) -ceq 'preserve-existing') 'Failure replaced an existing skill.'
    Assert-Result ((Get-Location).Path -eq $originalLocation) 'Failure changed working directory.'
}

foreach ($invalidLock in @('{"version":1,"skills":{"../outside":{}}}',
    '{"version":1,"skills":{"local":{}}}', '{"version":2,"skills":{}}')) {
    [IO.File]::WriteAllText($lockPath, $invalidLock)
    $rejected = $false
    try { Sync-AgentSkills $fixture } catch { $rejected = $true }
    Assert-Result $rejected 'Invalid lock was accepted.'
}
[IO.File]::WriteAllText($lockPath, '{"version":1,"skills":{}}')
Sync-AgentSkills $fixture
Assert-Result ($script:cliCalls -eq 4) 'Local-only synchronization unexpectedly used the CLI.'
'PASS: installation, repeated sync, local byte parity, lock preservation, unmanaged skills, stale files, CLI failures, partial restores, invalid inputs, local-only sync'
