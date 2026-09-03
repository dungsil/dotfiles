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
  pnpm dlx skills add dungsil/skills -g -y -a universal --skill *
  pnpm dlx skills add dungsil-ai/vibe -g -y -a universal --skill *
}
