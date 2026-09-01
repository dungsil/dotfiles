function udcheck {
  scoop update
  scoop status
  winget upgrade
}

function udall {
  scoop update --all
  winget upgrade --all
}
