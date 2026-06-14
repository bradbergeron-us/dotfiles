#!/usr/bin/env bash
# verify.sh — dotfiles environment health check
#
# Reports:
#   1. Broken symlinks        (errors   — exit 1)
#   2. Required tools         (warnings — exit 0)
#   3. Stale backups          (warnings — exit 0)
#   4. SSH key                (warnings — exit 0)
#   5. git-lfs global init    (warnings — exit 0)
#   6. mise tools installed   (warnings — exit 0)
#   7. dotfiles git health    (warnings — exit 0)
#   8. Brewfile drift         (warnings — exit 0)
#
# Usage:   bash ~/dotfiles/verify.sh
# Called by update.sh automatically after each update cycle.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
VERIFY_START=$SECONDS
ERRORS=0
WARNINGS=0
# shellcheck disable=SC2034  # used by step() in helpers
STEP=0
# shellcheck disable=SC2034
TOTAL_STEPS=8

# shellcheck source=scripts/lib/bootstrap_helpers.sh
source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
# shellcheck source=scripts/lib/verify_helpers.sh
source "$DOTFILES_DIR/scripts/lib/verify_helpers.sh"
setup_colors

REQUIRED_TOOLS=(
  brew mise git gh
  delta lazygit rg fd bat fzf zoxide
  rustup rustc cargo
  jq shellcheck direnv
  starship pre-commit
  yarn
)

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}  🔍  dotfiles verify${RESET}  —  environment health check\n"
echo "  ─────────────────────────────────────────────────"
printf "  ${DIM}Machine${RESET}  %s\n" "$(scutil --get ComputerName 2>/dev/null || hostname)"
printf "  ${DIM}Date${RESET}     %s\n" "$(date '+%a %b %d %Y  %H:%M')"
echo "  ─────────────────────────────────────────────────"

# ── 1. Symlinks ───────────────────────────────────────────────────────────────
step "🔗  Symlinks"
check_symlinks "$DOTFILES_DIR" "$HOME"

if [[ "$SYMLINK_BROKEN_COUNT" -eq 0 ]]; then
  success "$SYMLINK_OK_COUNT symlinks OK"
else
  for broken in "${SYMLINK_BROKEN_LIST[@]}"; do
    warn "$broken"
  done
  warn "$SYMLINK_BROKEN_COUNT broken — fix with: zsh ~/dotfiles/install.sh"
  ERRORS=$(( ERRORS + SYMLINK_BROKEN_COUNT ))
fi

# ── 2. Required tools ─────────────────────────────────────────────────────────
step "🧰  Required tools"
check_required_tools "${REQUIRED_TOOLS[@]}"

if [[ "$TOOLS_MISSING_COUNT" -eq 0 ]]; then
  success "All ${#REQUIRED_TOOLS[@]} tools present"
else
  for tool in "${TOOLS_MISSING_LIST[@]}"; do
    warn "missing: $tool"
  done
  warn "$TOOLS_MISSING_COUNT tool(s) missing — run: bash ~/dotfiles/bootstrap.sh"
  WARNINGS=$(( WARNINGS + TOOLS_MISSING_COUNT ))
fi

# ── 3. Stale backups ──────────────────────────────────────────────────────────
step "🗂️   Stale backups"
check_stale_backups "$HOME/.dotfiles_backup"

if [[ "$STALE_BACKUP_COUNT" -eq 0 ]]; then
  success "No stale backups"
else
  for backup_path in "${STALE_BACKUP_LIST[@]}"; do
    info "old: ${backup_path/$HOME/\~}"
  done
  warn "$STALE_BACKUP_COUNT backup(s) older than 30 days — consider: rm -rf ~/.dotfiles_backup"
  WARNINGS=$(( WARNINGS + STALE_BACKUP_COUNT ))
fi

# ── 4. SSH key ─────────────────────────────────────────────────────────
step "🔑  SSH key"
check_ssh_key

if [[ "$SSH_KEY_OK" == "true" ]]; then
  success "SSH key present and loaded in agent"
else
  warn "$SSH_KEY_ISSUE"
  WARNINGS=$(( WARNINGS + 1 ))
fi

# ── 5. git-lfs ──────────────────────────────────────────────────────
step "📁  git-lfs"
check_git_lfs_global

if [[ "$GIT_LFS_OK" == "true" ]]; then
  success "git-lfs installed and initialized globally"
else
  warn "$GIT_LFS_ISSUE"
  WARNINGS=$(( WARNINGS + 1 ))
fi

# ── 6. mise tools installed ──────────────────────────────────────────────
step "⚡  mise tools installed"
check_mise_installed "$DOTFILES_DIR/config/mise.toml"

if [[ "$MISE_UNINSTALLED_COUNT" -eq 0 ]]; then
  success "All mise-managed runtimes installed"
else
  for item in "${MISE_UNINSTALLED_LIST[@]}"; do
    warn "$item"
  done
  warn "$MISE_UNINSTALLED_COUNT runtime(s) not installed — run: mise install"
  WARNINGS=$(( WARNINGS + MISE_UNINSTALLED_COUNT ))
fi

# ── 7. Dotfiles git health ───────────────────────────────────────────────
step "🩺  Dotfiles git health"
check_dotfiles_git_health "$DOTFILES_DIR"

if [[ "$DOTFILES_GIT_HEALTH_OK" == "true" ]]; then
  success "No conflict markers in tracked dotfiles; git config parses cleanly"
else
  for issue in "${DOTFILES_GIT_HEALTH_ISSUES[@]}"; do
    warn "$issue"
  done
  WARNINGS=$(( WARNINGS + ${#DOTFILES_GIT_HEALTH_ISSUES[@]} ))
fi

# ── 8. Brewfile drift ────────────────────────────────────────────────────
step "🍺  Brewfile drift"
check_brewfile_drift "$DOTFILES_DIR/Brewfile"

if [[ "$BREWFILE_DRIFT_SKIPPED" == "true" ]]; then
  info "brew not installed — skipping Brewfile drift check"
elif [[ "$BREWFILE_DRIFT_OK" == "true" ]]; then
  success "Brewfile in sync with installed packages"
else
  warn "$BREWFILE_DRIFT_ISSUE"
  WARNINGS=$(( WARNINGS + 1 ))
fi

# ── Summary ───────────────────────────────────────────────────────────────────
_elapsed=$(( SECONDS - VERIFY_START ))

echo ""
echo "  ─────────────────────────────────────────────────"
if [[ "$ERRORS" -gt 0 ]]; then
  printf "${BOLD}  ❌  %d error(s)  %d warning(s)  (%ds)${RESET}\n" "$ERRORS" "$WARNINGS" "$_elapsed"
  echo "  ─────────────────────────────────────────────────"
  exit 1
elif [[ "$WARNINGS" -gt 0 ]]; then
  printf "${BOLD}${YELLOW}  ⚠   0 errors  %d warning(s)  (%ds)${RESET}\n" "$WARNINGS" "$_elapsed"
  echo "  ─────────────────────────────────────────────────"
else
  printf "${GREEN}${BOLD}  ✅  All checks passed  (%ds)${RESET}\n" "$_elapsed"
  echo "  ─────────────────────────────────────────────────"
fi
