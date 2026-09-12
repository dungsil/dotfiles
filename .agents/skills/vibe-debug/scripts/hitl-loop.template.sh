#!/usr/bin/env bash
# Human-in-the-loop reproduction loop.
# Copy this file, edit the steps below, and execute.
# The agent runs the script, and the user follows the prompts in their terminal.
#
# Usage:
#   bash hitl-loop.template.sh
#
# Two helpers:
#   step "<instruction>"   → Displays instruction, waits for Enter
#   capture VAR "<prompt>" → Displays prompt, reads response into VAR
#
# At the end, captured values are output in KEY=VALUE format for agent parsing.

set -euo pipefail

step() {
  printf '\n>>> %s\n' "$1"
  read -r -p "    [Press Enter when done] " _
}

capture() {
  local var="$1" question="$2" answer
  printf '\n>>> %s\n' "$question"
  read -r -p "    > " answer
  printf -v "$var" '%s' "$answer"
}

# --- Edit below ---------------------------------------------------------

step "Open the app at http://localhost:3000 and log in."

capture ERRORED "Click the 'Export' button. Did an error occur? (y/n)"

capture ERROR_MSG "Paste the error message (or 'none'):"

# --- Edit above ---------------------------------------------------------

printf '\n--- Captured Results ---\n'
printf 'ERRORED=%s\n' "$ERRORED"
printf 'ERROR_MSG=%s\n' "$ERROR_MSG"
