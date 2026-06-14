#!/usr/bin/env bash
# uninstall.sh — reverse install.sh: remove dotfiles symlinks and restore backups
#
# Usage:
#   bash ~/dotfiles/scripts/uninstall.sh            # interactive (asks for confirmation)
#   bash ~/dotfiles/scripts/uninstall.sh --dry-run  # print what would happen, change nothing
#   bash ~/dotfiles/scripts/uninstall.sh --yes      # skip the confirmation prompt
#   bash ~/dotfiles/scripts/uninstall.sh --help
#
# What it does:
#   1. Removes the symlinks install.sh creates — but ONLY the ones that actually
#      point INTO this dotfiles repo. Each managed path is resolved; if it is a
#      symlink whose target lives under this repo it is removed, otherwise it is
#      left untouched. Regular files and unrelated symlinks are never touched.
#   2. Restores the most recent ~/.dotfiles_backup/<timestamp> snapshot (the
#      files install.sh moved aside) back into $HOME.
#
# It deliberately does NOT remove user data that install.sh merely seeds and
# never owns: ~/.config/git/local.gitconfig and the global pre-commit hook at
# ~/.config/git/hooks/pre-commit.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_ROOT="$HOME/.dotfiles_backup"

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

# The exact set of links install.sh manages, in "<dest>" form.
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
MANAGED_LINKS=(
  "$HOME/.zshrc"
  "$HOME/.zprofile"
  "$HOME/.gitconfig"
  "$HOME/.tmux.conf"
  "$HOME/.hyper.js"
  "$HOME/.gitignore_global"
  "$HOME/.gemrc"
  "$HOME/.irbrc"
  "$HOME/.pryrc"
  "$HOME/.psqlrc"
  "$HOME/.npmrc"
  "$HOME/.editorconfig"
  "$HOME/.config/starship.toml"
  "$HOME/.config/direnv/direnvrc"
  "$HOME/.config/mise/config.toml"
  "$HOME/.ssh/config"
  "$VSCODE_DIR/settings.json"
)

# Counters
_removed=0
_skipped=0
_restored=0

# Pretty action line; prefixes [dry-run] when not actually doing the work.
action() {
  if (( DRY_RUN )); then
    printf "${CYAN}  → [dry-run] %s${RESET}\n" "$*"
  else
    printf "${CYAN}  → %s${RESET}\n" "$*"
  fi
}

# Resolve a symlink target to an absolute path (without requiring realpath).
resolve_target() {
  local link="$1" target
  target="$(readlink "$link")"
  case "$target" in
    /*) printf '%s\n' "$target" ;;
    *)  printf '%s\n' "$(cd "$(dirname "$link")" && pwd)/$target" ;;
  esac
}

# True when $1 is equal to or nested under $2.
is_under() {
  local path="$1" dir="$2"
  [[ "$path" == "$dir" || "$path" == "$dir/"* ]]
}

short() { printf '%s\n' "${1/$HOME/\~}"; }

echo ""
printf "${BOLD}  🧹  dotfiles uninstall${RESET}  —  reversing install.sh\n"
echo "  ─────────────────────────────────────────────────"
printf "  Repo:   %s\n" "$(short "$DOTFILES_DIR")"
if (( DRY_RUN )); then
  printf "  Mode:   dry-run (nothing will be changed)\n"
fi
echo "  ─────────────────────────────────────────────────"

# ── Confirmation ──────────────────────────────────────────────────────────────
if (( ! DRY_RUN && ! ASSUME_YES )); then
  printf "\n  This removes dotfiles symlinks pointing into the repo and restores\n"
  printf "  the most recent ~/.dotfiles_backup snapshot. Continue? [y/N] "
  read -r reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo ""; info "Aborted — nothing changed"; echo ""; exit 0 ;;
  esac
fi

# ── 1. Remove repo-owned symlinks ─────────────────────────────────────────────
# shellcheck disable=SC2034  # STEP/TOTAL_STEPS are read by step() from helpers
STEP=0
# shellcheck disable=SC2034
TOTAL_STEPS=2

step "🔗  Remove symlinks"
for dest in "${MANAGED_LINKS[@]}"; do
  short_dest="$(short "$dest")"

  if [[ ! -L "$dest" ]]; then
    if [[ -e "$dest" ]]; then
      warn "skip      $short_dest (not a symlink — leaving as-is)"
      (( _skipped++ )) || true
    fi
    continue
  fi

  target="$(resolve_target "$dest")"
  if ! is_under "$target" "$DOTFILES_DIR"; then
    warn "skip      $short_dest → $(short "$target") (not in this repo)"
    (( _skipped++ )) || true
    continue
  fi

  action "remove    $short_dest"
  if (( ! DRY_RUN )); then
    rm -f "$dest"
  fi
  (( _removed++ )) || true
done

# ── 2. Restore most recent backup ─────────────────────────────────────────────
step "♻️   Restore backup"
latest_backup=""
if [[ -d "$BACKUP_ROOT" ]]; then
  # Timestamp dir names sort chronologically; take the last one.
  while IFS= read -r dir; do
    [[ -n "$dir" ]] && latest_backup="$dir"
  done < <(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort)
fi

if [[ -z "$latest_backup" ]]; then
  info "No backups found in $(short "$BACKUP_ROOT") — nothing to restore"
else
  info "Restoring from $(short "$latest_backup")"
  shopt -s dotglob nullglob
  for item in "$latest_backup"/*; do
    name="$(basename "$item")"
    target="$HOME/$name"
    action "restore   $(short "$target")"
    if (( ! DRY_RUN )); then
      # Clear any leftover (e.g. a symlink we didn't own) then move the file back.
      [[ -e "$target" || -L "$target" ]] && rm -rf "$target"
      mv "$item" "$target"
    fi
    (( _restored++ )) || true
  done
  shopt -u dotglob nullglob

  # If we emptied the snapshot, drop the now-empty directory (real run only).
  if (( ! DRY_RUN )) && [[ -d "$latest_backup" ]]; then
    rmdir "$latest_backup" 2>/dev/null || true
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────────"
if (( DRY_RUN )); then
  success "${_removed} would remove  ·  ${_skipped} skipped  ·  ${_restored} would restore"
  info "Dry run — no changes were made"
else
  success "${_removed} removed  ·  ${_skipped} skipped  ·  ${_restored} restored"
fi
echo "  ─────────────────────────────────────────────────"
echo ""
