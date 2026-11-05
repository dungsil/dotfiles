[CmdletBinding()]
param()

& {
    $ErrorActionPreference = 'Stop'
    $savedEnvironment = @{}
    foreach ($name in @('DSH_HOME', 'DSH_PROFILE', 'DSH_PROFILE_DIR')) {
        $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }
    $savedExitCode = Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
    $hadExitCode = $null -ne $savedExitCode
    $previousExitCode = if ($hadExitCode) { $savedExitCode.Value } else { $null }
    $temporaryParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $temporaryRoot = Join-Path $temporaryParent ('dsh-settings-tests-' + [guid]::NewGuid().ToString('N'))
    $createdTemporaryRoot = $false
    $state = @{
        Assertions = 0
        Cases = 0
        Fixture = 0
        Calls = [Collections.Generic.List[object]]::new()
        Failures = [Collections.Generic.List[string]]::new()
    }

    try {
        . (Join-Path $PSScriptRoot 'dsh-settings.ps1')

        function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
            if ($Expected -cne $Actual) {
                throw "$Name`: expected <$Expected>, got <$Actual>"
            }
            $state.Assertions += 1
        }

        function Assert-JsonNode($Expected, $Actual, [string]$Name) {
            if ($Expected -is [Collections.IDictionary]) {
                if ($Actual -isnot [Collections.IDictionary]) { throw "$Name`: expected a JSON object" }
                Assert-Equal $Expected.Count $Actual.Count "$Name key count"
                foreach ($key in $Expected.Keys) {
                    Assert-Equal $true ($Actual.Keys -ccontains $key) "$Name contains $key"
                    Assert-JsonNode $Expected[$key] $Actual[$key] "$Name.$key"
                }
            } elseif ($Expected -is [array]) {
                if ($Actual -isnot [array]) { throw "$Name`: expected a JSON array" }
                Assert-Equal $Expected.Count $Actual.Count "$Name item count"
                for ($index = 0; $index -lt $Expected.Count; $index++) {
                    Assert-JsonNode $Expected[$index] $Actual[$index] "$Name[$index]"
                }
            } else {
                Assert-Equal (ConvertTo-Json -InputObject $Expected -Compress) `
                    (ConvertTo-Json -InputObject $Actual -Compress) $Name
            }
        }

        function Assert-Throws([scriptblock]$Body, [string]$Pattern, [string]$Name) {
            $caught = $null
            try { & $Body } catch { $caught = $_ }
            if ($null -eq $caught) { throw "$Name`: expected an exception" }
            if ($caught.Exception.Message -notmatch $Pattern) {
                throw "$Name`: unexpected exception <$($caught.Exception.Message)>"
            }
            $state.Assertions += 1
        }

        function Invoke-Test([string]$Name, [scriptblock]$Body) {
            $state.Cases += 1
            try {
                & $Body
                Write-Host "PASS: $Name"
            } catch {
                $state.Failures.Add("$Name`: $($_.Exception.Message)")
                Write-Host "FAIL: $Name`: $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        function New-Fixture {
            $state.Fixture += 1
            $state.ToolHome = Join-Path $temporaryRoot "case-$($state.Fixture)/home"
            $state.ProfileName = 'fixture-desktop'
            $state.ProfileHome = Join-Path $state.ToolHome "profiles/$($state.ProfileName)"
            $state.AppInstalled = $true
            $state.CliAvailable = $true
            $state.CliExitCode = 0
            $state.Calls.Clear()
            $null = New-Item -ItemType Directory -Path $state.ProfileHome -Force
            $env:DSH_HOME = Join-Path $temporaryRoot 'previous-home'
            $env:DSH_PROFILE = $state.ProfileName
            $env:DSH_PROFILE_DIR = $state.ProfileHome
        }

        function Set-ProfileManifest([Collections.IDictionary]$Dependencies) {
            $manifest = [ordered]@{ private = $true; dependencies = $Dependencies; bundles = @('fixture-bundle') }
            $path = Join-Path $state.ProfileHome 'package.json'
            [IO.File]::WriteAllText($path, ($manifest | ConvertTo-Json -Depth 16))
        }

        function Set-InstalledPackage([string]$Package, [string]$Version) {
            $directory = Join-Path $state.ProfileHome "node_modules/$Package"
            $null = New-Item -ItemType Directory -Path $directory -Force
            $manifest = [ordered]@{ name = $Package; version = $Version }
            [IO.File]::WriteAllText((Join-Path $directory 'package.json'), ($manifest | ConvertTo-Json))
        }

        function Test-AppInstalled([string]$Name) {
            Assert-Equal 'dsh' $Name 'application lookup is for DSH'
            return $state.AppInstalled
        }
        function Get-DshProfileHome { return $state.ProfileHome }
        function Get-DshProfileName { return $state.ProfileName }
        function Get-ToolHome([string]$VariableName, [string]$DefaultPath) {
            Assert-Equal 'DSH_HOME' $VariableName 'tool home override key'
            Assert-Equal '.dsh' $DefaultPath 'tool home default'
            return $state.ToolHome
        }
        function Get-DshCliCommand {
            if ($state.CliAvailable) { return Get-Command Invoke-DshSettingsTestCli -CommandType Function }
            return $null
        }
        function Invoke-DshSettingsTestCli {
            $state.Calls.Add([pscustomobject]@{ Arguments = @($args); DshHome = $env:DSH_HOME })
            $global:LASTEXITCODE = $state.CliExitCode
        }

        function Assert-CliCall([int]$Index, [string]$Package) {
            $expected = @('plugin', '--profile', $state.ProfileName, 'add', '--yes', '--ignore-scripts', $Package)
            $call = $state.Calls[$Index]
            Assert-Equal $expected.Count $call.Arguments.Count 'CLI argument count'
            for ($index = 0; $index -lt $expected.Count; $index++) {
                Assert-Equal $expected[$index] $call.Arguments[$index] "CLI argument $index"
            }
            Assert-Equal $state.ToolHome $call.DshHome 'CLI uses the resolved DSH_HOME'
        }

        if (Test-Path -LiteralPath $temporaryRoot) { throw "Fixture path already exists: $temporaryRoot" }
        $null = New-Item -ItemType Directory -Path $temporaryRoot
        $createdTemporaryRoot = $true

        Invoke-Test 'normalization rewrites only case-sensitive custom dependency keys' {
            $source = @'
{
  "name": "fixture-profile",
  "private": true,
  "description": "Preserve metadata, Unicode: 설정",
  "dependencies": {
    "@dungsil/dsh-plugin-one": "1.2.3",
    "@dungsil/dsh-plugin-local": "link:C:/development/plugin",
    "@dungsil/dsh-plugin-ready": "latest",
    "@deepseek-ai/dsh-plugin-official": "0.2.8",
    "ordinary-package": "^3.0.0",
    "@Dungsil/dsh-plugin-case": "4.0.0",
    "@dungsil/DSH-plugin-case": "5.0.0",
    "@dungsil/not-dsh-plugin": "6.0.0"
  },
  "devDependencies": { "@dungsil/dsh-plugin-dev": "7.0.0" },
  "bundles": ["@dungsil/dsh-plugin-one", { "name": "local", "enabled": false }],
  "metadata": { "dependencies": { "@dungsil/dsh-plugin-nested": "8.0.0" }, "value": null }
}
'@
            $expected = $source | ConvertFrom-Json -AsHashtable
            foreach ($name in @('@dungsil/dsh-plugin-one', '@dungsil/dsh-plugin-local', '@dungsil/dsh-plugin-ready')) {
                $expected['dependencies'][$name] = 'latest'
            }
            $normalized = ConvertTo-DshPackageContent -Text $source
            Assert-Equal 'System.String' $normalized.GetType().FullName 'normalization returns one string'
            Assert-JsonNode $expected ($normalized | ConvertFrom-Json -AsHashtable) 'normalized package'
            $again = ConvertTo-DshPackageContent -Text $normalized
            Assert-JsonNode $expected ($again | ConvertFrom-Json -AsHashtable) 'normalization is idempotent'
        }

        Invoke-Test 'normalization preserves a package without dependencies' {
            $source = '{"private":true,"bundles":["fixture"],"metadata":{"value":42}}'
            $actual = ConvertTo-DshPackageContent -Text $source
            Assert-JsonNode ($source | ConvertFrom-Json -AsHashtable) `
                ($actual | ConvertFrom-Json -AsHashtable) 'package without dependencies'
        }

        Invoke-Test 'latest installs on both invocations even when already installed' {
            New-Fixture
            $package = '@dungsil/dsh-plugin-fixture'
            Set-ProfileManifest ([ordered]@{ $package = 'latest' })
            Set-InstalledPackage $package '9.9.9'
            $manifestPath = Join-Path $state.ProfileHome 'package.json'
            $before = [IO.File]::ReadAllText($manifestPath)
            $previousHome = $env:DSH_HOME
            $packages = [ordered]@{ $package = 'latest' }
            Install-DshPlugins -Packages $packages
            Install-DshPlugins -Packages $packages
            Assert-Equal 2 $state.Calls.Count 'latest CLI invocation count'
            Assert-CliCall 0 "${package}@latest"
            Assert-CliCall 1 "${package}@latest"
            Assert-Equal $previousHome $env:DSH_HOME 'success restores DSH_HOME'
            Assert-Equal $before ([IO.File]::ReadAllText($manifestPath)) 'installer does not rewrite the profile manifest'
            Assert-Equal 'latest' $packages[$package] 'installer preserves the requested mapping'
        }

        Invoke-Test 'exact official version skips when declared and installed at desired version' {
            New-Fixture
            $package = '@deepseek-ai/dsh-plugin-fixture'
            Set-ProfileManifest ([ordered]@{ $package = '0.2.8' })
            Set-InstalledPackage $package '0.2.8'
            $previousHome = $env:DSH_HOME
            Install-DshPlugins -Packages ([ordered]@{ $package = '0.2.8' })
            Assert-Equal 0 $state.Calls.Count 'matching exact version skips CLI'
            Assert-Equal $previousHome $env:DSH_HOME 'skip preserves DSH_HOME'
        }

        Invoke-Test 'exact official version installs when installed version mismatches' {
            New-Fixture
            $package = '@deepseek-ai/dsh-plugin-fixture'
            Set-ProfileManifest ([ordered]@{ $package = '0.2.8' })
            Set-InstalledPackage $package '0.2.7'
            Install-DshPlugins -Packages ([ordered]@{ $package = '0.2.8' })
            Assert-Equal 1 $state.Calls.Count 'mismatched exact version invokes CLI'
            Assert-CliCall 0 "${package}@0.2.8"
        }

        Invoke-Test 'exact official version installs when its installed package is missing' {
            New-Fixture
            $package = '@deepseek-ai/dsh-plugin-fixture'
            Set-ProfileManifest ([ordered]@{ $package = '0.2.8' })
            Install-DshPlugins -Packages ([ordered]@{ $package = '0.2.8' })
            Assert-Equal 1 $state.Calls.Count 'missing installed package invokes CLI'
            Assert-CliCall 0 "${package}@0.2.8"
        }

        Invoke-Test 'exact official version installs when installed but undeclared' {
            New-Fixture
            $package = '@deepseek-ai/dsh-plugin-fixture'
            Set-ProfileManifest ([ordered]@{})
            Set-InstalledPackage $package '0.2.8'
            Install-DshPlugins -Packages ([ordered]@{ $package = '0.2.8' })
            Assert-Equal 1 $state.Calls.Count 'undeclared installed package invokes CLI'
            Assert-CliCall 0 "${package}@0.2.8"
        }

        Invoke-Test 'exact official version installs when the profile manifest is missing' {
            New-Fixture
            $package = '@deepseek-ai/dsh-plugin-fixture'
            Install-DshPlugins -Packages ([ordered]@{ $package = '0.2.8' })
            Assert-Equal 1 $state.Calls.Count 'missing profile manifest invokes CLI'
            Assert-CliCall 0 "${package}@0.2.8"
        }

        Invoke-Test 'missing application skips installation' {
            New-Fixture
            $state.AppInstalled = $false
            $previousHome = $env:DSH_HOME
            Install-DshPlugins -Packages ([ordered]@{ '@dungsil/dsh-plugin-fixture' = 'latest' })
            Assert-Equal 0 $state.Calls.Count 'missing DSH skips CLI'
            Assert-Equal $previousHome $env:DSH_HOME 'missing DSH preserves DSH_HOME'
        }

        Invoke-Test 'empty package mapping skips installation' {
            New-Fixture
            $previousHome = $env:DSH_HOME
            Install-DshPlugins -Packages ([ordered]@{})
            Assert-Equal 0 $state.Calls.Count 'empty mapping skips CLI'
            Assert-Equal $previousHome $env:DSH_HOME 'empty mapping preserves DSH_HOME'
        }

        Invoke-Test 'profile path mismatch blocks CLI invocation' {
            New-Fixture
            $state.ProfileHome = Join-Path $temporaryRoot 'different-profile'
            $previousHome = $env:DSH_HOME
            Assert-Throws {
                Install-DshPlugins -Packages ([ordered]@{ '@dungsil/dsh-plugin-fixture' = 'latest' })
            } 'DSH_PROFILE_DIR' 'profile path mismatch guard'
            Assert-Equal 0 $state.Calls.Count 'profile mismatch never reaches CLI'
            Assert-Equal $previousHome $env:DSH_HOME 'profile mismatch preserves DSH_HOME'
        }

        Invoke-Test 'missing CLI fails without changing DSH_HOME' {
            New-Fixture
            $state.CliAvailable = $false
            $previousHome = $env:DSH_HOME
            Assert-Throws {
                Install-DshPlugins -Packages ([ordered]@{ '@dungsil/dsh-plugin-fixture' = 'latest' })
            } 'CLI' 'missing CLI guard'
            Assert-Equal 0 $state.Calls.Count 'missing CLI never invokes a command'
            Assert-Equal $previousHome $env:DSH_HOME 'missing CLI preserves DSH_HOME'
        }

        foreach ($homeState in @('set', 'unset')) {
            Invoke-Test "CLI failure throws and restores $homeState DSH_HOME" {
                New-Fixture
                if ($homeState -eq 'unset') { $env:DSH_HOME = $null }
                $previousHome = $env:DSH_HOME
                $state.CliExitCode = 37
                $packages = [ordered]@{
                    '@dungsil/dsh-plugin-first' = 'latest'
                    '@deepseek-ai/dsh-plugin-second' = '0.2.8'
                }
                Assert-Throws { Install-DshPlugins -Packages $packages } '37' 'CLI nonzero status propagates'
                Assert-Equal 1 $state.Calls.Count 'CLI failure stops remaining packages'
                Assert-CliCall 0 '@dungsil/dsh-plugin-first@latest'
                Assert-Equal $previousHome $env:DSH_HOME 'CLI failure restores DSH_HOME'
                if ($homeState -eq 'unset') {
                    Assert-Equal $true ($null -eq $env:DSH_HOME) 'unset DSH_HOME remains absent'
                }
            }
        }

        if ($state.Failures.Count -gt 0) {
            throw "$($state.Failures.Count) of $($state.Cases) tests failed:`n$($state.Failures -join [Environment]::NewLine)"
        }
        Write-Host "PASS: $($state.Assertions) assertions; $($state.Cases) tests; temporary fixtures and mocked CLI only."
    } finally {
        foreach ($name in $savedEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
        }
        if ($hadExitCode) {
            Set-Variable -Name LASTEXITCODE -Scope Global -Value $previousExitCode
        } else {
            Remove-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
        }
        if ($createdTemporaryRoot) {
            $resolvedRoot = [IO.Path]::GetFullPath($temporaryRoot)
            $resolvedParent = [IO.Path]::GetDirectoryName($resolvedRoot)
            $leaf = [IO.Path]::GetFileName($resolvedRoot)
            if ($resolvedParent.TrimEnd('\', '/') -ine $temporaryParent.TrimEnd('\', '/') -or
                $leaf -notmatch '^dsh-settings-tests-[0-9a-f]{32}$') {
                throw "Refusing to remove an unexpected fixture path: $resolvedRoot"
            }
            Remove-Item -LiteralPath $resolvedRoot -Recurse -Force
        }
    }
}
