#!/usr/bin/env bash
# dotfiles.sh — unified entry point for common dotfiles operations.
#
# A thin, memorable wrapper around the existing scripts so you can run
# `dotfiles status` / `dotfiles doctor` instead of remembering each script path.
# Most subcommands simply delegate (forwarding all arguments and the exit code)
# to the underlying script; `doctor` aggregates a few read-only health checks.
#
# Usage:
#   bash scripts/dotfiles.sh <command> [args...]
#   dotfiles <command> [args...]   # when ~/dotfiles/bin is on PATH (see home/zsh/path.zsh)
#
# Commands: help · status · verify · doctor · update · profile · cleanup

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colored output helpers (setup_colors, info/success/warn, step) — the same
# library every other script uses, so output stays consistent.
# shellcheck source=scripts/lib/bootstrap_helpers.sh
source "$ROOT_DIR/scripts/lib/bootstrap_helpers.sh"
setup_colors

usage() {
  cat <<'USAGE'
Usage: dotfiles <command> [args...]

Commands:
  help       Show this help message
  status     Show dotfiles status (repo state + last update)
  verify     Run the full health check (verify.sh)
  doctor     Read-only health check: status + verify + shell & terminal config
  update     Update dotfiles, packages, and runtimes (update.sh)
  profile    Show or set this machine's profile
  cleanup    Remove common dotfile cruft (backups, cache, legacy configs)

Most commands forward their arguments to the underlying script, e.g.:
  dotfiles status --verify
  dotfiles update --dry-run
  dotfiles cleanup --dry-run

Examples:
  dotfiles status
  dotfiles doctor
  dotfiles update

Run via `dotfiles <command>` (when ~/dotfiles/bin is on PATH) or
`bash ~/dotfiles/scripts/dotfiles.sh <command>`.
USAGE
}

# doctor — read-only snapshot of dotfiles health. Delegates to the existing
# status/verify scripts and adds light shell + terminal config checks. It never
# modifies the system; it aggregates failures and returns non-zero if any check
# fails so it is usable in scripts and CI.
doctor() {
  local fails=0 f
  # shellcheck disable=SC2034  # STEP/TOTAL_STEPS are read by step() in bootstrap_helpers.sh
  STEP=0
  # shellcheck disable=SC2034
  TOTAL_STEPS=4

  echo ""
  printf "${BOLD}  🩺  dotfiles doctor${RESET}  —  read-only health check\n"
  echo "  ─────────────────────────────────────────────────"

  # [1/4] Repository status (repo git state + last update.sh result)
  step "📦  Repository status"
  if bash "$ROOT_DIR/scripts/status.sh" --exit-code; then
    success "Repository status OK"
  else
    warn "Repository status reported issues (see above)"
    fails=$(( fails + 1 ))
  fi

  # [2/4] Full verification (symlinks, tools, runtimes, git health, ...)
  step "🔍  Verification (verify.sh)"
  if bash "$ROOT_DIR/verify.sh"; then
    success "Verification passed"
  else
    warn "verify.sh reported errors (see above)"
    fails=$(( fails + 1 ))
  fi

  # [3/4] Shell configuration — syntax-check zshrc + every module
  step "🐚  Shell configuration"
  if command -v zsh >/dev/null 2>&1; then
    local shell_ok=true
    if ! zsh -n "$ROOT_DIR/home/zshrc" 2>/dev/null; then
      warn "syntax error: home/zshrc"
      shell_ok=false
    fi
    for f in "$ROOT_DIR"/home/zsh/*.zsh; do
      [[ -e "$f" ]] || continue
      if ! zsh -n "$f" 2>/dev/null; then
        warn "syntax error: ${f#"$ROOT_DIR"/}"
        shell_ok=false
      fi
    done
    if [[ "$shell_ok" == true ]]; then
      success "zsh config parses cleanly (home/zshrc + modules)"
    else
      fails=$(( fails + 1 ))
    fi
  else
    info "zsh not found — skipping shell syntax check"
  fi

  # [4/4] Terminal configuration — Ghostty preferred, Hyper fallback
  step "🖥️   Terminal configuration"
  local ghostty_cfg="$ROOT_DIR/config/ghostty/config"
  if [[ ! -f "$ghostty_cfg" ]]; then
    warn "Ghostty config missing: config/ghostty/config"
    fails=$(( fails + 1 ))
  elif command -v ghostty >/dev/null 2>&1; then
    if ghostty +validate-config --config-file="$ghostty_cfg" >/dev/null 2>&1; then
      success "Ghostty config valid (ghostty +validate-config)"
    else
      warn "ghostty +validate-config reported errors for config/ghostty/config"
      fails=$(( fails + 1 ))
    fi
  else
    success "Ghostty config present (install ghostty to validate automatically)"
  fi
  [[ -f "$ROOT_DIR/home/hyper.js" ]] && info "Hyper fallback config present (home/hyper.js)"

  echo ""
  echo "  ─────────────────────────────────────────────────"
  if (( fails > 0 )); then
    printf "${BOLD}${YELLOW}  ⚠   Doctor finished with %d issue(s)${RESET}\n" "$fails"
    echo "  ─────────────────────────────────────────────────"
    return 1
  fi
  printf "${GREEN}${BOLD}  ✅  Doctor complete — no issues found${RESET}\n"
  echo "  ─────────────────────────────────────────────────"
  return 0
}

cmd="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi

case "$cmd" in
  help|-h|--help) usage ;;
  status)  exec bash "$ROOT_DIR/scripts/status.sh" "$@" ;;
  verify)  exec bash "$ROOT_DIR/verify.sh" "$@" ;;
  update)  exec bash "$ROOT_DIR/update.sh" "$@" ;;
  profile) exec bash "$ROOT_DIR/scripts/profile.sh" "$@" ;;
  cleanup) exec bash "$ROOT_DIR/scripts/cleanup.sh" "$@" ;;
  doctor)  doctor "$@" ;;
  *)
    printf "Unknown command: %s\n\n" "$cmd" >&2
    usage >&2
    exit 1
    ;;
esac
