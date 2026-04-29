#!/usr/bin/env bash
# Human-in-the-loop reproduction loop.
# Copy this file, edit the steps below, and run it.
#
# The agent runs the script. The human follows each prompt in the terminal.
# Captured answers are printed at the end as KEY=VALUE lines for the agent to
# use as reproduction evidence.
#
# Usage:
#   bash hitl-loop.template.sh
#
# Helpers:
#   step "<instruction>"          show instruction and wait for Enter
#   capture VAR "<question>"      ask a question and store the answer in VAR

set -euo pipefail

step() {
  printf '\n>>> %s\n' "$1"
  read -r -p "    [Enter when done] " _
}

capture() {
  local var="$1" question="$2" answer
  printf '\n>>> %s\n' "$question"
  read -r -p "    > " answer
  printf -v "$var" '%s' "$answer"
}

# --- edit below ---------------------------------------------------------

step "Open the app or system under test and prepare the failing workflow."

capture REPRODUCED "Did the issue reproduce? (y/n)"

capture OBSERVED "What did you observe? Include exact error text if available."

capture EXPECTED "What should have happened instead?"

capture EVIDENCE "Any screenshot name, log timestamp, request id, or other evidence?"

# --- edit above ---------------------------------------------------------

printf '\n--- Captured ---\n'
printf 'REPRODUCED=%s\n' "$REPRODUCED"
printf 'OBSERVED=%s\n' "$OBSERVED"
printf 'EXPECTED=%s\n' "$EXPECTED"
printf 'EVIDENCE=%s\n' "$EVIDENCE"
