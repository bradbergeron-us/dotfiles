#!/usr/bin/env bash
# bootstrap_helpers.sh — pure/testable helpers sourced by bootstrap.sh
# No side effects, no interactive prompts.
# shellcheck disable=SC2034  # variables are used by callers that source this file

# ── Color setup ───────────────────────────────────────────────────────────────
setup_colors() {
  if [[ -t 1 ]]; then
    RESET='\033[0m';  BOLD='\033[1m';   DIM='\033[2m'
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'
    BLUE='\033[1;34m'
  else
    RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; BLUE=''
  fi
}

# ── Output helpers ────────────────────────────────────────────────────────────
info()    { printf "${CYAN}  → %s${RESET}\n" "$*"; }
success() { printf "${GREEN}  ✓ %s${RESET}\n" "$*"; }
warn()    { printf "${YELLOW}  ⚠ %s${RESET}\n" "$*"; }

step() {
  STEP=$((STEP + 1))
  echo ""
  printf "${BOLD}${BLUE}  ▸ [%d/%d]  %s${RESET}\n" "$STEP" "$TOTAL_STEPS" "$*"
}
