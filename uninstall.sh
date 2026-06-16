#!/usr/bin/env bash
# uninstall.sh — reverse install.sh: remove tracked dotfile symlinks and restore
# the files they replaced. The mirror image of install.sh, sharing its single
# source of truth (config/symlinks.map) and profile model (profile_helpers.sh).
#
# What it does:
#   • Removes only symlinks listed in config/symlinks.map that point into this
#     repo and apply to the active profile (current_profile / profile_includes).
#   • Restores the most recent ~/.dotfiles_backup/<timestamp>/ entry for each
#     destination it clears, when one exists (best effort, by basename).
#   • Removes the thin ~/.gitconfig include (a real file, not a symlink) that
#     install.sh writes, and restores any backed-up ~/.gitconfig.
#
# What it deliberately does NOT do (safety): it never deletes the dotfiles repo,
# never uninstalls Homebrew/mise/Rust packages, and never touches untracked user
# data such as ~/.zshrc.local or ~/.config/git/local.gitconfig. Removing a
# symlink only unlinks it — the tracked file in the repo is left intact.
#
# Usage:
#   bash uninstall.sh [--dry-run] [--yes] [--help]
#   --dry-run   Show what would be removed/restored; change nothing.
#   --yes, -y   Skip the confirmation prompt (required for non-interactive runs).
#   --help, -h  Show this help and exit.
#
# Re-runnable: a second run finds nothing left to remove and is a no-op.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles_backup"

DRY_RUN=false
ASSUME_YES=false

usage() {
  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
}

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true ;;
    --yes|-y)    ASSUME_YES=true ;;
    --help|-h)   usage; exit 0 ;;
    *)
      printf 'uninstall.sh: unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

# ── Shared helpers ────────────────────────────────────────────────────────────
# shellcheck source=scripts/lib/bootstrap_helpers.sh
source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
# shellcheck source=scripts/lib/profile_helpers.sh
source "$DOTFILES_DIR/scripts/lib/profile_helpers.sh"
setup_colors

PROFILE="$(current_profile)"

# Most recent timestamped backup directory (names sort chronologically), or "".
latest_backup_dir() {
  local d last=""
  [[ -d "$BACKUP_ROOT" ]] || return 0
  for d in "$BACKUP_ROOT"/*/; do
    [[ -d "$d" ]] || continue
    last="${d%/}"
  done
  printf '%s' "$last"
}

LATEST_BACKUP="$(latest_backup_dir)"

removed=0
skipped=0
restored=0

# Restore the most recent backup for a destination, if one exists and the slot
# is now free. Best effort: install.sh backs files up by basename, so that is
# the key we look up here.
restore_backup() {
  local dest="$1"
  local short="${dest/$HOME/\~}"
  local base backup
  [[ -n "$LATEST_BACKUP" ]] || return 0
  base="$(basename "$dest")"
  backup="$LATEST_BACKUP/$base"
  [[ -e "$backup" || -L "$backup" ]] || return 0
  if [[ "$DRY_RUN" == true ]]; then
    info "would restore  $short  (from ${LATEST_BACKUP/$HOME/\~}/$base)"
    restored=$(( restored + 1 ))
    return 0
  fi
  # Never clobber something that already lives at the destination.
  [[ -e "$dest" || -L "$dest" ]] && return 0
  mkdir -p "$(dirname "$dest")"
  mv "$backup" "$dest"
  success "restored   $short  (from ${LATEST_BACKUP/$HOME/\~}/$base)"
  restored=$(( restored + 1 ))
}

# Remove a symlink only when it points into this repo; then try to restore.
remove_link() {
  local dest="$1"
  local short="${dest/$HOME/\~}"
  local target

  if [[ -L "$dest" ]]; then
    target="$(readlink "$dest")"
    if [[ "$target" == "$DOTFILES_DIR"/* ]]; then
      if [[ "$DRY_RUN" == true ]]; then
        info "would remove   $short"
      else
        rm "$dest"
        success "removed    $short"
      fi
      removed=$(( removed + 1 ))
      restore_backup "$dest"
    else
      info "skipped    $short  (points elsewhere: $target)"
      skipped=$(( skipped + 1 ))
    fi
  elif [[ -e "$dest" ]]; then
    info "skipped    $short  (not a symlink)"
    skipped=$(( skipped + 1 ))
  fi
  # Missing destinations are silently ignored — nothing to undo.
}

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}  🗑️  dotfiles uninstall${RESET}  —  remove tracked symlinks\n"
echo "  ─────────────────────────────────────────────────"
printf "  ${DIM}Machine${RESET}  %s\n" "$(scutil --get ComputerName 2>/dev/null || hostname)"
printf "  ${DIM}Profile${RESET}  %s\n" "$PROFILE"
if [[ "$DRY_RUN" == true ]]; then
  printf "  ${DIM}Mode${RESET}     dry-run (no changes)\n"
fi
echo "  ─────────────────────────────────────────────────"

# ── Confirmation ──────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" != true && "$ASSUME_YES" != true ]]; then
  if [[ -t 0 ]]; then
    echo ""
    warn "This removes dotfile symlinks and restores backed-up originals."
    read -rp "  Continue? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo ""
      info "Uninstall cancelled"
      exit 0
    fi
  else
    warn "Refusing to run non-interactively without --yes (use --dry-run to preview)."
    exit 1
  fi
fi

# ── Step 1: Remove tracked dotfile symlinks (config/symlinks.map SSOT) ─────────
echo ""
printf "${BOLD}  1. Removing dotfile symlinks${RESET}  (profile: %s)\n" "$PROFILE"
echo ""

SYMLINK_MAP="$DOTFILES_DIR/config/symlinks.map"
if [[ -r "$SYMLINK_MAP" ]]; then
  while read -r src_rel dest_rel tags_rel; do
    [[ -z "$src_rel" || "$src_rel" == \#* ]] && continue
    if ! profile_includes "$PROFILE" "${tags_rel:-}"; then
      continue
    fi
    remove_link "$HOME/$dest_rel"
  done < "$SYMLINK_MAP"
else
  warn "symlink manifest not found: $SYMLINK_MAP"
fi

# ── Step 2: Git config thin include ────────────────────────────────────────────
# install.sh writes ~/.gitconfig as a REAL file containing an [include] of the
# tracked home/gitconfig. Remove only that managed include (verified by content),
# then restore any backed-up original. Older installs may have symlinked it.
echo ""
printf "${BOLD}  2. Git config thin include${RESET}\n"
echo ""

GITCONFIG_DEST="$HOME/.gitconfig"
GITCONFIG_SRC="$DOTFILES_DIR/home/gitconfig"
GITCONFIG_SHORT="${GITCONFIG_DEST/$HOME/\~}"

if [[ -L "$GITCONFIG_DEST" ]]; then
  # Legacy: a symlink into the repo. Reuse the same safe removal path.
  remove_link "$GITCONFIG_DEST"
elif [[ -f "$GITCONFIG_DEST" ]] && grep -qF "path = $GITCONFIG_SRC" "$GITCONFIG_DEST"; then
  if [[ "$DRY_RUN" == true ]]; then
    info "would remove   $GITCONFIG_SHORT  (managed thin include)"
  else
    rm "$GITCONFIG_DEST"
    success "removed    $GITCONFIG_SHORT  (managed thin include)"
  fi
  removed=$(( removed + 1 ))
  restore_backup "$GITCONFIG_DEST"
else
  info "skipped    $GITCONFIG_SHORT  (not a managed thin include)"
  skipped=$(( skipped + 1 ))
fi

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────────"
if [[ "$DRY_RUN" == true ]]; then
  printf "${BOLD}  ✅  dry-run: %d would remove · %d would restore · %d skipped${RESET}\n" \
    "$removed" "$restored" "$skipped"
else
  printf "${GREEN}${BOLD}  ✅  Uninstall complete${RESET}  —  %d removed · %d restored · %d skipped\n" \
    "$removed" "$restored" "$skipped"
fi
echo "  ─────────────────────────────────────────────────"
echo ""
printf "  ${BOLD}Notes${RESET}\n"
printf "  • The dotfiles repo and your backups were left untouched.\n"
printf "  • Untracked local config (~/.zshrc.local, ~/.config/git/local.gitconfig) was kept.\n"
printf "  • Re-install any time with: ${CYAN}zsh %s/install.sh${RESET}\n" "${DOTFILES_DIR/$HOME/\~}"
echo ""
