[CmdletBinding()]
param([switch]$LibraryOnly)

# Inspect tool inputs only. Never execute the command being checked or intercept
# child processes: gg itself needs to invoke Git and the provider CLIs.
function Get-ForgeExecutable([string]$Name) {
    if ($Name -match '(?i)(?:^|[\\/])(git|gh|glab|tea)(?:\.(?:exe|cmd|bat|com))?$') {
        return $Matches[1].ToLowerInvariant()
    }
}

function Get-LiteralArgument($Element) {
    if ($Element -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
        return $Element.Value
    }
    if ($Element -is [System.Management.Automation.Language.ExpandableStringExpressionAst] -and
        $Element.NestedExpressions.Count -eq 0) {
        return $Element.Value
    }
    if ($Element -is [System.Management.Automation.Language.CommandParameterAst]) {
        return '-' + $Element.ParameterName
    }
    return $null
}

function Find-ForgeProcessCall([string]$Code, [int]$Depth = 0) {
    # Common literal Python/JavaScript process calls in OMP eval/python and -c/-e.
    # This is deliberately not a general evaluator or a security boundary.
    $callPattern = '(?m)^\s*(?:(?:const|let|var)\s+)?(?:[\w.]+\s*=\s*)?(?:await\s+)?(?:subprocess\.(?:run|Popen|call|check_call|check_output)|os\.(?:system|popen)|(?:(?:[\w.]+|require\(["''](?:node:)?child_process["'']\))\.)?(?:exec|execSync|execFile|execFileSync|spawn|spawnSync))\s*\(\s*(?<array>\[\s*)?(?<literal>"(?:\\.|[^"\\])*"|''(?:\\.|[^''\\])*'')'
    foreach ($match in [regex]::Matches($Code, $callPattern)) {
        $literal = $match.Groups['literal'].Value
        $value = $literal.Substring(1, $literal.Length - 2)
        $value = $value -replace '\\([\\"''])', '$1'
        $found = Get-ForgeExecutable $value
        if (-not $found -and -not $match.Groups['array'].Success) {
            $found = Find-ForgeShellCommand $value ($Depth + 1)
        }
        if ($found) { return $found }
    }
}

function Find-ForgeShellCommand([string]$Command, [int]$Depth = 0) {
    if ($Depth -gt 8) { throw 'Nested command inspection exceeded the depth limit.' }
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Command, [ref]$tokens, [ref]$parseErrors)
    # Bash permits a quoted executable without PowerShell's call operator.
    # Only inspect such positions in partial ASTs, not valid string expressions.
    if ($parseErrors.Count) {
        for ($i = 0; $i -lt $tokens.Count - 1; $i++) {
            if ($i -gt 0 -and $tokens[$i - 1].Kind -notin @('Semi', 'NewLine', 'AndAnd', 'OrOr', 'Pipe')) { continue }
            if ($tokens[$i] -is [System.Management.Automation.Language.StringToken]) {
                $found = Get-ForgeExecutable $tokens[$i].Value
                if ($found) { return $found }
            }
        }
    }
    # Partial ASTs also cover common Bash command chains. Unsupported syntax,
    # dynamically constructed commands and script-file contents are not resolved.
    $commands = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst]
    }, $true)
    foreach ($node in $commands) {
        $name = $node.GetCommandName()
        $found = Get-ForgeExecutable $name
        if ($found) { return $found }
        if (-not $name) { continue }
        $executable = ($name -split '[\\/]')[-1] -replace '(?i)\.(exe|cmd|bat|com)$', ''
        $arguments = @($node.CommandElements | Select-Object -Skip 1 | ForEach-Object { Get-LiteralArgument $_ })

        if ($executable -in @('env', 'command', 'exec', 'sudo', 'nohup', 'time', 'call', 'then', 'do', 'else') -or
            $name -match '^\w+=') {
            $index = 0
            while ($index -lt $arguments.Count) {
                $argument = $arguments[$index]
                if ($null -eq $argument) { break }
                if ($argument -match '^\w+=' -or $argument -eq '--') { $index++; continue }
                if ($argument -match '^-') {
                    if ($argument -in @('-u', '--unset', '-C', '--chdir', '-g', '--group', '--user')) { $index++ }
                    $index++
                    continue
                }
                $found = Get-ForgeExecutable $argument
                if ($found) { return $found }
                # Reuse the AST extent to preserve quoting in the remaining command.
                $remaining = $node.CommandElements[($index + 1)..($node.CommandElements.Count - 1)]
                $found = Find-ForgeShellCommand (($remaining | ForEach-Object Extent | ForEach-Object Text) -join ' ') ($Depth + 1)
                if ($found) { return $found }
                break
            }
        }

        if ($executable -in @('start-process', 'saps', 'start')) {
            $targetIndex = -1
            for ($i = 0; $i -lt $arguments.Count; $i++) {
                if ($arguments[$i] -ieq '-FilePath') { $targetIndex = $i; break }
            }
            $targetIndex = if ($targetIndex -ge 0) { $targetIndex + 1 } else { 0 }
            while ($targetIndex -lt $arguments.Count -and
                $arguments[$targetIndex] -in @('-Wait', '-NoNewWindow', '-PassThru', '-LoadUserProfile', '-UseNewEnvironment')) {
                $targetIndex++
            }
            if ($targetIndex -lt $arguments.Count) {
                $found = Get-ForgeExecutable $arguments[$targetIndex]
                if ($found) { return $found }
            }
        }

        if ($executable -in @('invoke-expression', 'iex') -and $arguments.Count -gt 0 -and $arguments[0]) {
            $found = Find-ForgeShellCommand $arguments[0] ($Depth + 1)
            if ($found) { return $found }
        }

        if ($executable -in @('pwsh', 'powershell', 'bash', 'sh', 'zsh', 'cmd', 'python', 'python3', 'node')) {
            for ($i = 0; $i -lt $arguments.Count - 1; $i++) {
                $flag = $arguments[$i]
                if ($flag -notmatch '^(?i:-[a-z]*c|-command|/c|/k|-e|--eval|-encodedcommand|-enc)$') { continue }
                $nested = $arguments[$i + 1]
                if (-not $nested) { break }
                if ($flag -in @('-EncodedCommand', '-enc')) {
                    $nested = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($nested))
                }
                if ($executable -in @('python', 'python3', 'node')) {
                    $found = Find-ForgeProcessCall $nested ($Depth + 1)
                } else {
                    $found = Find-ForgeShellCommand $nested ($Depth + 1)
                }
                if ($found) { return $found }
                break
            }
        }
    }
}

function Get-GgGuardAdvice($Payload) {
    if ($Payload.hook_event_name -and $Payload.hook_event_name -ne 'PreToolUse') { return @{} }
    $toolName = $Payload.tool_name
    $inputData = $Payload.tool_input
    $found = $null
    switch ($toolName) {
        { $_ -in @('Bash', 'bash', 'exec_command', 'shell_command') } {
            $command = $inputData.command
            if (-not $command) { $command = $inputData.cmd }
            if ($command -isnot [string]) { throw 'Shell input has no command string.' }
            $found = Find-ForgeShellCommand $command
        }
        { $_ -in @('eval', 'python') } {
            $code = $inputData.code
            if ($code -is [string]) { $found = Find-ForgeProcessCall $code }
        }
    }
    if (-not $found) { return @{} }
    $skillPath = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.agents/skills/gg/SKILL.md'
    $advice = "gg-guard advisory: direct '$found' invocation detected. Prefer gg for subsequent Git and Forge operations. Read the entire `$gg skill at '$skillPath' and check 'gg --help' and the relevant subcommand help. Do not mechanically rename commands: 'gg config' is not 'git config'. Respect explicit tool requests and the skill's unsupported-operation guidance. This hook does not block or rewrite the current call; normal permission checks still apply. Do not repeat an already-completed operation just to use gg."
    return @{
        hookSpecificOutput = @{
            hookEventName = 'PreToolUse'
            additionalContext = $advice
        }
    }
}

if (-not $LibraryOnly) {
    $ErrorActionPreference = 'Stop'
    try {
        $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $payload) { throw 'Missing hook input.' }
        $result = Get-GgGuardAdvice $payload
    } catch {
        # Inspection failures are advisory too; never change permission decisions.
        $result = @{
            hookSpecificOutput = @{
                hookEventName = 'PreToolUse'
                additionalContext = 'gg-guard could not inspect this tool call. This advisory hook does not block execution or change normal permission checks. Check the hook input and installation when convenient.'
            }
        }
    }
    [Console]::Out.WriteLine(($result | ConvertTo-Json -Depth 6 -Compress))
}
