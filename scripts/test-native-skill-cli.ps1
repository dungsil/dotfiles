[CmdletBinding()]
param(
    [string]$SkillsRoot = (Join-Path $PSScriptRoot '../.agents/skills'),
    [switch]$UnitOnly
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'native-skill-cli.ps1')
$script:assertionCount = 0

function Assert-Equal([string]$Expected, [string]$Actual, [string]$Name) {
    if ($Expected -cne $Actual) {
        throw "$Name`: expected <$Expected>, got <$Actual>"
    }
    $script:assertionCount += 1
}

function Assert-Matches([string]$Actual, [string]$Pattern, [string]$Name) {
    if ($Actual -cnotmatch $Pattern) {
        throw "$Name`: missing pattern <$Pattern>"
    }
    $script:assertionCount += 1
}

function Assert-NotMatches([string]$Actual, [string]$Pattern, [string]$Name) {
    if ($Actual -cmatch $Pattern) {
        throw "$Name`: unexpected pattern <$Pattern>"
    }
    $script:assertionCount += 1
}

$cases = @(
    @{
        Name = 'provider-specific GitHub template'
        Path = 'vibe-init/references/issue-tracker-github.md'
        Source = '`gg issue create --title "..." --body "..."`; `gg pr view 42 --json body`; `gg api repos/o/r/issues/42 --jq .id`'
        Expected = '`gh issue create --title "..." --body "..."`; `gh pr view 42 --json body`; `gh api repos/o/r/issues/42 --jq .id`'
    },
    @{
        Name = 'GitLab template preserves MR and description flags'
        Path = 'vibe-init\references\issue-tracker-gitlab.md'
        Source = '`gg issue create --description "..."`; `gg mr update 42 --description "..."`; `gg issue note 42 --message "..."`; `gg pr view 42`와 비교한다.'
        Expected = '`glab issue create --description "..."`; `glab mr update 42 --description "..."`; `glab issue note 42 --message "..."`; `gh pr view 42`와 비교한다.'
    },
    @{
        Name = 'same-line provider context'
        Path = 'vibe-deep-plan/evals/evals.json'
        Source = 'GitHub에서는 `gg issue close 42`를 쓴다. GitLab에서는 `gg issue close 43`을 쓴다.'
        Expected = 'GitHub에서는 `gh issue close 42`를 쓴다. GitLab에서는 `glab issue close 43`을 쓴다.'
    },
    @{
        Name = 'Markdown provider blocks'
        Path = 'vibe-plan/SKILL.md'
        Source = "- **GitHub**: ``gg issue create``.`r`n  ``gg api --method POST repos/o/r/issues/1/sub_issues -F sub_issue_id=2```r`n- **GitLab**: 다음을 쓴다.`r`n  ``gg issue create``.`r`n  ``gg api --method POST projects/:id/issues -F issue_type=task```r`n"
        Expected = "- **GitHub**: ``gh issue create``.`r`n  ``gh api --method POST repos/o/r/issues/1/sub_issues -F sub_issue_id=2```r`n- **GitLab**: 다음을 쓴다.`r`n  ``glab issue create``.`r`n  ``glab api --method POST projects/:id/issues -F issue_type=task```r`n"
    },
    @{
        Name = 'Git commands do not inherit a forge provider'
        Path = 'mixed.md'
        Source = "# GitLab`n``gg status --short``; ``gg remote -v``; ``gg push --force-with-lease```n``gg mr view 2```n# GitHub`n``gg issue view 3```n"
        Expected = "# GitLab`n``git status --short``; ``git remote -v``; ``git push --force-with-lease```n``glab mr view 2```n# GitHub`n``gh issue view 3```n"
    },
    @{
        Name = 'command shape overrides comparison prose'
        Path = 'mixed.md'
        Source = 'GitLab과 비교할 때 `gg pr view 2`를 읽는다. GitHub과 비교할 때 `gg mr view 3`을 읽는다. `gg api projects/1`과 `gg api repos/o/r`를 읽는다.'
        Expected = 'GitLab과 비교할 때 `gh pr view 2`를 읽는다. GitHub과 비교할 때 `glab mr view 3`을 읽는다. `glab api projects/1`과 `gh api repos/o/r`를 읽는다.'
    },
    @{
        Name = 'GitLab API policy does not assert a missing flag'
        Path = 'issue-tracker-gitlab.md'
        Source = "``gg api projects/1 | jq '.id'`` (``gg api``에는 ``--jq`` 플래그가 없어 파이프로 넘긴다)."
        Expected = "``glab api projects/1 | jq '.id'`` (API 응답은 파이프로 ``jq``에 넘겨 필요한 필드를 선택한다)."
    },
    @{
        Name = 'tracker selection documents both providers'
        Path = 'vibe-init/SKILL.md'
        Source = '`gg issue create`를 호출할지 선택한다.'
        Expected = '`gh issue create` 또는 `glab issue create`를 호출할지 선택한다.'
    },
    @{
        Name = 'shared API advice documents both providers'
        Path = 'vibe-deep-plan/evals/evals.json'
        Source = '두 트래커 모두 `gg api`로 읽는다. GitHub에서는 `gg api --method PATCH repos/o/r/issues/1`를 쓴다. GitLab에서는 `gg api --method PUT projects/1/issues/2`를 쓴다.'
        Expected = '두 트래커 모두 `gh api` 또는 `glab api`로 읽는다. GitHub에서는 `gh api --method PATCH repos/o/r/issues/1`를 쓴다. GitLab에서는 `glab api --method PUT projects/1/issues/2`를 쓴다.'
    },
    @{
        Name = 'word boundaries preserve other identifiers'
        Path = 'mixed.md'
        Source = 'egg gg_name gg2 bigger `gg status`'
        Expected = 'egg gg_name gg2 bigger `git status`'
    },
    @{
        Name = 'dedicated skill is outside conversion scope'
        Path = '.agents/skills/gg/SKILL.md'
        Source = '`gg issue view 1`'
        Expected = '`gg issue view 1`'
    },
    @{
        Name = 'non-document files are outside conversion scope'
        Path = 'tool.ps1'
        Source = 'gg status'
        Expected = 'gg status'
    },
    @{
        Name = 'empty content remains an empty string'
        Path = 'empty.md'
        Source = ''
        Expected = ''
    }
)

foreach ($case in $cases) {
    $original = $case.Source
    $actual = Get-NativeSkillCliContent -Content $case.Source -RelativePath $case.Path
    Assert-Equal $case.Expected $actual $case.Name
    Assert-Equal $actual (Get-NativeSkillCliContent $actual $case.Path) "$($case.Name): idempotence"
    Assert-Equal $original $case.Source "$($case.Name): source is unchanged"
}

if ($UnitOnly) {
    Write-Host "PASS: $script:assertionCount assertions; inline fixtures only; no files written."
    return
}

$targetPaths = @(
    'vibe-init/SKILL.md',
    'vibe-init/references/issue-tracker-github.md',
    'vibe-init/references/issue-tracker-gitlab.md',
    'vibe-init/evals/evals.json',
    'vibe-plan/SKILL.md',
    'vibe-plan/AGENT-BRIEF.md',
    'vibe-deep-plan/evals/evals.json'
)
$outputs = @{}
$sources = @{}
foreach ($relativePath in $targetPaths) {
    $fullPath = Join-Path $SkillsRoot $relativePath
    $source = [IO.File]::ReadAllText($fullPath)
    $actual = Get-NativeSkillCliContent $source $relativePath
    $outputs[$relativePath] = $actual
    $sources[$relativePath] = $source
    Assert-Equal 'System.String' ($actual.GetType().FullName) "$relativePath`: returns one string"
    Assert-NotMatches $actual '(?<![A-Za-z0-9_])gg(?![A-Za-z0-9_])' "$relativePath`: no standalone gg"
    Assert-Equal $actual (Get-NativeSkillCliContent $actual $relativePath) "$relativePath`: idempotence"
    Assert-Equal $source ([IO.File]::ReadAllText($fullPath)) "$relativePath`: source file is unchanged"
    Assert-Equal ([regex]::Matches($source, '\r\n|\n|\r').Value -join '|') `
        ([regex]::Matches($actual, '\r\n|\n|\r').Value -join '|') "$relativePath`: newline sequence"
    if ($relativePath.EndsWith('.json')) {
        $before = $source | ConvertFrom-Json
        $after = $actual | ConvertFrom-Json
        Assert-Equal $before.skill_name $after.skill_name "$relativePath`: JSON skill name"
        Assert-Equal ($before.evals.id -join '|') ($after.evals.id -join '|') "$relativePath`: JSON evaluation ids"
    }
}

$github = $outputs['vibe-init/references/issue-tracker-github.md']
$expectedGithub = [regex]::Replace($sources['vibe-init/references/issue-tracker-github.md'], '\bgg\b', 'gh')
Assert-Equal $expectedGithub $github 'GitHub template preserves all other text and flags'
Assert-NotMatches $github '\bglab\b' 'GitHub template does not contain GitLab commands'
Assert-Matches $github 'gh issue close <number> -R <owner>/<repo> --comment' 'GitHub close command preserves repository and comment'
Assert-Matches $github 'gh api --paginate .repos/\{owner\}/\{repo\}/pulls/<PR>/commits\?per_page=100. --jq' 'GitHub API preserves pagination and jq'

$gitlab = $outputs['vibe-init/references/issue-tracker-gitlab.md']
$expectedGitlab = $sources['vibe-init/references/issue-tracker-gitlab.md'].Replace(
    '(`gg api`에는 `--jq` 플래그가 없어 파이프로 넘긴다)',
    '(API 응답은 파이프로 `jq`에 넘겨 필요한 필드를 선택한다)'
)
$expectedGitlab = [regex]::Replace($expectedGitlab, '\bgg\b', 'glab').Replace('glab pr ...', 'gh pr ...')
Assert-Equal $expectedGitlab $gitlab 'GitLab template preserves all other text and flags'
Assert-NotMatches $gitlab '\bglab pr\b|\bgh (?:issue|mr|api)\b' 'GitLab template does not mix provider commands'
Assert-Matches $gitlab 'glab mr update <IID> -R <target-project> --description' 'GitLab MR preserves project and description'
Assert-Matches $gitlab 'glab issue note <iid> -R <issue-project> --message' 'GitLab note preserves issue project and message'
Assert-Matches $gitlab 'glab api --paginate "projects/<target_project_id>/merge_requests/<IID>/commits\?per_page=100" \| jq' 'GitLab API preserves pagination and jq pipeline'
Assert-NotMatches $gitlab 'api`에는 `--jq` 플래그가 없어' 'GitLab policy does not assert a missing jq flag'

$init = $outputs['vibe-init/SKILL.md']
Assert-Matches $init '\*\*GitHub\*\*:[^\r\n]*`gh` CLI' 'GitHub tracker selects gh'
Assert-Matches $init '\*\*GitLab\*\*:[^\r\n]*`glab` CLI' 'GitLab tracker selects glab'
Assert-Matches $init '`gh issue create` 또는 `glab issue create`' 'tracker selection retains both native CLI examples'

$plan = $outputs['vibe-plan/SKILL.md']
Assert-Matches $plan 'gh api --method POST repos/<owner>/<repo>/issues/<parent>/sub_issues -F sub_issue_id=<child-db-id>' 'plan uses GitHub sub-issue endpoint'
Assert-Matches $plan 'glab api --method POST "projects/:id/issues" -F "title=<제목>" -F "issue_type=task" -F "description=<본문>"' 'plan uses GitLab task endpoint'
Assert-NotMatches $plan '\bgh api[^`\r\n]*projects/|\bglab api[^`\r\n]*repos/' 'plan API providers do not cross'
Assert-Matches $outputs['vibe-plan/AGENT-BRIEF.md'] 'gh issue list --label needs-triage' 'agent brief uses GitHub command'

$initEvals = $outputs['vibe-init/evals/evals.json'] | ConvertFrom-Json
foreach ($entry in $initEvals.evals) {
    $entryText = $entry | ConvertTo-Json -Depth 16
    if ($entry.id -eq 'github-tracker-auto-close-rules') {
        Assert-NotMatches $entryText '\bglab\b' 'GitHub evaluation does not contain GitLab commands'
        Assert-Matches $entryText 'gh api' 'GitHub evaluation uses gh api'
    } elseif ($entry.id -eq 'gitlab-tracker-auto-close-rules') {
        Assert-NotMatches $entryText '\bgh\b' 'GitLab evaluation does not contain GitHub commands'
        Assert-Matches $entryText 'glab mr issues' 'GitLab evaluation uses glab mr'
    }
}

$deepEvals = $outputs['vibe-deep-plan/evals/evals.json'] | ConvertFrom-Json
$release = $deepEvals.evals | Where-Object id -EQ 'hosted-research-release-claim-after-charting'
if ($release.expected_output -match '--method PATCH') {
    Assert-Matches $release.expected_output 'GitHub에서는 `gh api --method PATCH repos/' 'mixed evaluation preserves GitHub API assignment syntax'
    Assert-Matches $release.expected_output 'GitLab에서는 `glab api --method PUT projects/' 'mixed evaluation preserves GitLab API assignment syntax'
    Assert-Matches $release.expected_output '두 트래커 모두 `gh api` 또는 `glab api`로' 'shared API advice preserves both providers'
} else {
    Assert-Matches $release.expected_output 'GitHub에서는 `gh issue edit <n> --remove-assignee @me`' 'mixed evaluation preserves GitHub assignment syntax'
    Assert-Matches $release.expected_output 'GitLab에서는 `glab issue update <n> --assignee=-@me`' 'mixed evaluation preserves GitLab assignment syntax'
}
$subissue = $deepEvals.evals | Where-Object id -EQ 'github-native-subissue-write-readback'
Assert-Matches $subissue.expected_output '`gh api`' 'GitHub sub-issue evaluation uses gh api'
Assert-NotMatches ($subissue | ConvertTo-Json -Depth 16) '\bglab\b' 'GitHub sub-issue evaluation does not contain glab'

Write-Host "PASS: $script:assertionCount assertions; $($targetPaths.Count) skill files; no files written."
