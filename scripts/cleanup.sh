#!/usr/bin/env bash
# cleanup.sh — remove common dotfile cruft (backups, cache, legacy configs)
#
# Usage:
#   bash ~/dotfiles/scripts/cleanup.sh            # interactive (asks for confirmation)
#   bash ~/dotfiles/scripts/cleanup.sh --dry-run  # print what would happen, change nothing
#   bash ~/dotfiles/scripts/cleanup.sh --yes      # skip the confirmation prompt
#   bash ~/dotfiles/scripts/cleanup.sh --help
#
# What it does:
#   Removes common dotfile cruft that accumulates over time:
#   1. Backup files (.bak, .backup, old git configs)
#   2. Cache files (zsh completion, less/vim history, z directory jump data)
#   3. Legacy configs (old shell configs, replaced prompt/plugin systems)
#   4. Generated files (macOS .DS_Store metadata)
#
# What it NEVER touches:
#   - Managed dotfiles (symlinks created by install.sh)
#   - Expected unmanaged files (.fzf.zsh, .yarnrc, .zshrc.local)
#   - Directories (only removes files in $HOME root, not subdirectories)
#   - Any file not explicitly listed in the cleanup arrays below

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=scripts/lib/bootstrap_helpers.sh
source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
setup_colors

DRY_RUN=0
ASSUME_YES=0

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
    --yes|-y)     ASSUME_YES=1 ;;
    --help|-h)    usage; exit 0 ;;
    *) printf "Unknown option: %s\n" "$1" >&2; usage; exit 2 ;;
  esac
  shift
done

# Files to remove, organized by category
# Each array contains explicit paths only — no wildcards, no directories
BACKUP_FILES=(
  "$HOME/.zshrc.bak"
  "$HOME/.gitconfig.backup"
)

CACHE_FILES=(
  "$HOME/.zcompdump"
  "$HOME/.zcompdump-AFSMW740493660-5.9"
  "$HOME/.zcompdump-AFSMW740493660-5.9.AFSMW740493660.31545"
  "$HOME/.zcompdump-AFSMW740493660-5.9.zwc"
  "$HOME/.lesshst"
  "$HOME/.viminfo"
  "$HOME/.z"
  "$HOME/.DS_Store"
)

LEGACY_CONFIGS=(
  "$HOME/.bash_profile"
  "$HOME/.profile"
  "$HOME/.zshenv"
  "$HOME/.spaceship.zsh"
  "$HOME/.zsh.plugins.txt"
  "$HOME/.zsh_plugins.txt"
  "$HOME/.zsh_plugins.zsh"
  "$HOME/.angular-config.json"
)

# Counters
_removed=0
_skipped=0

# Pretty action line; prefixes [dry-run] when not actually doing the work.
action() {
  if (( DRY_RUN )); then
    printf "${CYAN}  → [dry-run] %s${RESET}\n" "$*"
  else
    printf "${CYAN}  → %s${RESET}\n" "$*"
  fi
}

short() { printf '%s\n' "${1/$HOME/\~}"; }

remove_files() {
  local category="$1"
  shift
  local files=("$@")

  echo ""
  printf "${BOLD}  🧹  %s${RESET}\n" "$category"

  for file in "${files[@]}"; do
    local short_file
    short_file="$(short "$file")"

    if [[ ! -e "$file" && ! -L "$file" ]]; then
      # File doesn't exist — skip silently (not an error)
      (( _skipped++ )) || true
      continue
    fi

    action "remove    $short_file"
    if (( ! DRY_RUN )); then
      rm -f "$file"
    fi
    (( _removed++ )) || true
  done
}

echo ""
printf "${BOLD}  🧹  dotfiles cleanup${RESET}  —  removing cruft from ${HOME/$HOME/\~}\n"
echo "  ─────────────────────────────────────────────────"
if (( DRY_RUN )); then
  printf "  Mode:   dry-run (nothing will be changed)\n"
fi
echo "  ─────────────────────────────────────────────────"

# ── Confirmation ──────────────────────────────────────────────────────────────
if (( ! DRY_RUN && ! ASSUME_YES )); then
  printf "\n  This removes backup files, cache, and legacy configs from your home\n"
  printf "  directory. Managed dotfiles (symlinks) are never touched. Continue? [y/N] "
  read -r reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo ""; info "Aborted — nothing changed"; echo ""; exit 0 ;;
  esac
fi

# ── Remove files by category ──────────────────────────────────────────────────
remove_files "Backup files" "${BACKUP_FILES[@]}"
remove_files "Cache files" "${CACHE_FILES[@]}"
remove_files "Legacy configs" "${LEGACY_CONFIGS[@]}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────────"
if (( DRY_RUN )); then
  success "${_removed} would remove  ·  ${_skipped} not found"
  info "Dry run — no changes were made"
else
  success "${_removed} removed  ·  ${_skipped} not found"
fi
echo "  ─────────────────────────────────────────────────"
echo ""

if (( ! DRY_RUN && _removed > 0 )); then
  info "Tip: Run 'bash ~/dotfiles/verify.sh' to check your dotfiles are still healthy"
fi
echo ""
