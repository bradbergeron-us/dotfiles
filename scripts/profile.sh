#!/usr/bin/env bash
# profile.sh — show or set this machine's dotfiles profile.
#
# A profile is the durable identity of the machine (personal | work | minimal |
# server), stored at ~/.config/dotfiles/profile and honored by bootstrap /
# install / update / verify / status. This lets an already-set-up machine adopt
# or switch a profile WITHOUT re-running the full bootstrap.
#
# Usage:
#   bash ~/dotfiles/scripts/profile.sh            # show the active profile
#   bash ~/dotfiles/scripts/profile.sh show
#   bash ~/dotfiles/scripts/profile.sh list
#   bash ~/dotfiles/scripts/profile.sh set work   # persist a new profile

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=scripts/lib/bootstrap_helpers.sh
source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
# shellcheck source=scripts/lib/profile_helpers.sh
source "$DOTFILES_DIR/scripts/lib/profile_helpers.sh"
setup_colors

_file_display="${DOTFILES_PROFILE_FILE/#$HOME/~}"

case "${1:-show}" in
  show)
    printf "  ${DIM}Active profile${RESET}  %s\n" "$(current_profile)"
    if [[ -f "$DOTFILES_PROFILE_FILE" ]]; then
      info "set in $_file_display"
    else
      info "default (no $_file_display yet) — set one with: profile.sh set <name>"
    fi
    ;;
  list)
    printf "  Available profiles: %s\n" "$DOTFILES_PROFILES"
    printf "  Active: %s\n" "$(current_profile)"
    ;;
  set)
    name="${2:-}"
    if [[ -z "$name" ]]; then
      warn "usage: profile.sh set <name>   (one of: $DOTFILES_PROFILES)"
      exit 1
    fi
    if ! valid_profile "$name"; then
      warn "unknown profile '$name' — valid profiles: $DOTFILES_PROFILES"
      exit 1
    fi
    persist_profile "$name"
    success "profile set to '$name'  ($_file_display)"
    info "Apply it: zsh ~/dotfiles/install.sh  &&  bash ~/dotfiles/update.sh"
    ;;
  --help|-h|help)
    cat <<'USAGE'
Usage: bash profile.sh [COMMAND]

  show          Show the active profile (default)
  list          List available profiles
  set <name>    Persist <name> as this machine's profile
  --help, -h    Show this help

The profile is stored at ~/.config/dotfiles/profile and honored by
bootstrap / install / update / verify / status. Precedence at resolve time:
--profile flag > DOTFILES_PROFILE env > this file > default (personal).
USAGE
    ;;
  *)
    warn "unknown command '${1:-}' — try: show | list | set <name> | --help"
    exit 1
    ;;
esac
