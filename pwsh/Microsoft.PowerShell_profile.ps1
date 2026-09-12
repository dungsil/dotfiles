function udcheck {
  scoop update
  scoop status
  winget upgrade
}

function udall {
  scoop update --all
  winget upgrade --all
  if (Get-Command omp -ErrorAction SilentlyContinue) {
    omp plugin marketplace update
    omp plugin upgrade --scope user
  }
}

function syncplugins {
  if (Get-Command omp -ErrorAction SilentlyContinue) {
    omp plugin marketplace update
    omp plugin upgrade --scope user
  }
}

function syncsk() {
  $profileSource = Get-Item -LiteralPath $PSCommandPath
  if ($profileSource.LinkType) { $profileSource = $profileSource.ResolveLinkTarget($true) }
  & (Join-Path $profileSource.Directory.Parent.FullName 'install.ps1') -SkillsOnly
}
