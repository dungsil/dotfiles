function udcheck {
  scoop update
  scoop status
  winget upgrade
}

function udall {
  scoop update --all
  winget upgrade --all
}

function syncsk() {
  pnpm dlx skills add dungsil/skills -g -y -a universal --skill *
  pnpm dlx skills add dungsil-ai/vibe -g -y -a universal --skill *
}
