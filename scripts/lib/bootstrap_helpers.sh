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

# ── mise runtime parsing ──────────────────────────────────────────────────────
# parse_mise_runtimes TOML_FILE
# Prints one "tool@version" per line for every entry in the [tools] table of a
# mise config (e.g. config/mise.toml), making that file the single source of
# truth for runtime versions. Pure Bash (portable to macOS Bash 3.2): tracks the
# [tools] table, skips blanks/comments and other tables, and takes the first
# double-quoted value. A missing file prints nothing.
parse_mise_runtimes() {
  local toml_file="$1" line key val in_tools=0
  [[ -f "$toml_file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    # strip leading whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    case "$line" in
      ''|'#'*)    continue ;;              # blank or comment
      '[tools]'*) in_tools=1; continue ;;  # enter the [tools] table
      '['*)       in_tools=0; continue ;;  # any other table ends it
    esac
    [[ "$in_tools" -eq 1 && "$line" == *=* ]] || continue
    key="${line%%=*}"; key="${key//[[:space:]]/}"
    val="${line#*=}"; val="${val#*\"}"; val="${val%%\"*}"
    [[ -n "$key" && -n "$val" ]] && printf '%s@%s\n' "$key" "$val"
  done < "$toml_file"
}
