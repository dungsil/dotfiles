# Run: pwsh -NoProfile -File tests/gg-guard.Tests.ps1
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$guardPath = Join-Path $repositoryRoot 'hooks/gg-guard.ps1'
. $guardPath -LibraryOnly

$advised = @(
    'git status', 'gh pr list', 'glab mr list', 'tea issues list',
    'GIT.EXE status', 'gh.cmd pr list', '/usr/bin/git status',
    '"/usr/bin/git" status', 'command "/usr/bin/git" status',
    'C:\Tools\Git\bin\git.exe status', '& "C:\Program Files\Git\bin\git.exe" status',
    'gg status; git diff', "gg status`ngh pr list", 'gg status && glab mr list',
    'gg status | git log', 'echo $(git status)', 'Write-Output "$(gh pr list)"',
    'if ($true) { git status }', 'foreach ($x in 1..2) { gh pr list }',
    'env GIT_PAGER=cat git log', 'env -u GIT_DIR git status', 'GIT_PAGER=cat git log',
    'command git status', 'command -- gh pr list', 'sudo -u tester git status',
    'nohup git status', 'exec git status',
    'bash -lc "git status && echo done"', "pwsh -NoProfile -Command 'gh pr list'",
    'cmd /c git status', 'cmd /c "glab mr list"', 'Invoke-Expression "tea issues list"',
    'Start-Process git -ArgumentList status', 'Start-Process -FilePath "C:\Git\git.exe"',
    'Start-Process -filepath gh',
    'Start-Process -Wait git', 'cd /tmp && env X=1 "git" status',
    "python -c 'subprocess.run([""git"", ""status""])'",
    "node -e 'require(""child_process"").execSync(""git status"")'"
)
$quiet = @(
    'gg status', 'gg pr list', 'gg diff -- git/README.md', 'gg -v',
    'gg commit -m "docs: explain git status and gh pr list"',
    'rg "git status|gh pr" README.md', 'Write-Output "git status"',
    "Write-Output 'gh pr list; git status'", 'Get-Content .agents/skills/gg/SKILL.md',
    'Get-Command git', 'where.exe git', 'echo git', 'git-lfs version', 'github-tool --help',
    'Get-Content ./git', '# git status', "# git status`ngg status",
    '$message = "git status"; Write-Output $message',
    "Write-Output @'`ngit status`n'@", 'gg status && gg diff',
    'bash -lc "gg status"', "pwsh -Command 'Write-Output ""git status""'",
    'env GIT_PAGER=cat gg log', 'Start-Process gg -ArgumentList status',
    "python -c 'print(""git status"")'"
)
$failed = [Collections.Generic.List[string]]::new()
function Assert-PassiveAdvice($Response) {
    if ((($Response.Keys | Sort-Object) -join ',') -ne 'hookSpecificOutput' -or
        (($Response.hookSpecificOutput.Keys | Sort-Object) -join ',') -ne 'additionalContext,hookEventName' -or
        $Response.hookSpecificOutput.hookEventName -ne 'PreToolUse' -or
        [string]::IsNullOrWhiteSpace($Response.hookSpecificOutput.additionalContext)) {
        $failed.Add('Expected passive context only, without permission decisions or input changes.')
    }
}
foreach ($command in $advised) {
    if (-not (Find-ForgeShellCommand $command)) { $failed.Add("Missed: $command") }
    Assert-PassiveAdvice (Get-GgGuardAdvice @{ tool_name = 'Bash'; tool_input = @{ command = $command } })
}
foreach ($command in $quiet) {
    if (Find-ForgeShellCommand $command) { $failed.Add("False positive: $command") }
}

$advisedCode = @(
    'subprocess.run(["git", "status"])',
    'subprocess.check_output("gh pr list", shell=True)',
    'os.system("glab mr list")',
    'await exec("tea issues list")',
    'const result = child_process.spawnSync("git", ["status"]);',
    'await Bun.spawn(["gh", "pr", "list"]);'
)
foreach ($code in $advisedCode) {
    if (-not (Find-ForgeProcessCall $code)) { $failed.Add("Missed process call: $code") }
}
foreach ($code in @('print("git status")', 'console.log("gh pr list")',
    'subprocess.run(["gg", "status"])', '# subprocess.run(["git", "status"])',
    'print(''subprocess.run(["git", "status"])'')')) {
    if (Find-ForgeProcessCall $code) { $failed.Add("False positive in code: $code") }
}

$advice = Get-GgGuardAdvice @{ tool_name = 'Bash'; tool_input = @{ command = 'git status' } }
if ($advice.hookSpecificOutput.additionalContext -notmatch '\$gg' -or
    $advice.hookSpecificOutput.additionalContext -notmatch 'SKILL.md' -or
    $advice.hookSpecificOutput.additionalContext -notmatch 'Do not repeat an already-completed operation') {
    $failed.Add('Missing skill guidance or duplicate-execution warning.')
}
foreach ($payload in @(
    @{ tool_name = 'Bash'; tool_input = @{ command = 'gg status' } },
    @{ tool_name = 'apply_patch'; tool_input = @{ command = 'git status' } },
    @{ hook_event_name = 'PostToolUse'; tool_name = 'Bash'; tool_input = @{ command = 'git status' } }
)) {
    if ((Get-GgGuardAdvice $payload).Count -ne 0) { $failed.Add('Advised an unrelated or quiet tool call.') }
}

# Exercise stdin/stdout exactly as Codex and the OMP adapter do, without running
# any candidate command or modifying the user's hook trust state.
function Invoke-Guard([string]$Json) {
    $startInfo = [Diagnostics.ProcessStartInfo]::new('pwsh')
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @('-NoProfile', '-NonInteractive', '-File', $guardPath)) {
        $startInfo.ArgumentList.Add($argument)
    }
    $process = [Diagnostics.Process]::Start($startInfo)
    $process.StandardInput.Write($Json)
    $process.StandardInput.Close()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0 -or $stderr) { throw "Hook failed: $stderr" }
    $process.Dispose()
    return $stdout | ConvertFrom-Json -AsHashtable
}
foreach ($json in @(
    '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git status"}}',
    '{"tool_name":"eval","tool_input":{"code":"subprocess.run([''gh'', ''pr'', ''list''])"}}',
    '{"tool_name":"Bash","tool_input":{}}', '{broken', 'null'
)) {
    Assert-PassiveAdvice (Invoke-Guard $json)
}
if ((Invoke-Guard '{"tool_name":"Bash","tool_input":{"command":"gg status"}}').Count -ne 0) {
    $failed.Add('Hook added advice for gg.')
}

if ($failed.Count) { throw ($failed -join "`n") }
"PASS: $($advised.Count + $quiet.Count) shell cases, process calls, passive advice, nonblocking errors, tool filtering and hook stdin/stdout"
