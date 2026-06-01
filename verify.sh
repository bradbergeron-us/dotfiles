#!/usr/bin/env bash
# verify.sh — dotfiles environment health check
#
# Reports:
#   1. Broken symlinks      (errors   — exit 1)
#   2. Version drift        (warnings — exit 0)
#   3. Missing required tools (warnings — exit 0)
#   4. Stale backups        (warnings — exit 0)
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
TOTAL_STEPS=7

# shellcheck source=scripts/bootstrap_helpers.sh
source "$DOTFILES_DIR/scripts/bootstrap_helpers.sh"
# shellcheck source=scripts/verify_helpers.sh
source "$DOTFILES_DIR/scripts/verify_helpers.sh"
setup_colors

REQUIRED_TOOLS=(
  brew mise git gh
  delta lazygit rg fd bat fzf zoxide
  rustup rustc cargo
  jq shellcheck direnv
  starship pre-commit
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

# ── 2. Version drift ──────────────────────────────────────────────────────────
step "📌  Version drift (mise.toml vs bootstrap.sh)"
check_mise_version_drift "$DOTFILES_DIR/config/mise.toml" "$DOTFILES_DIR/bootstrap.sh"

if [[ "$DRIFT_COUNT" -eq 0 ]]; then
  success "mise.toml and bootstrap.sh agree on all runtime versions"
else
  for drift in "${DRIFT_LIST[@]}"; do
    warn "$drift"
  done
  warn "$DRIFT_COUNT version(s) out of sync — update mise.toml or bootstrap.sh"
  WARNINGS=$(( WARNINGS + DRIFT_COUNT ))
fi

# ── 3. Required tools ─────────────────────────────────────────────────────────
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

# ── 4. Stale backups ──────────────────────────────────────────────────────────
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

# ── 5. SSH key ─────────────────────────────────────────────────────────
step "🔑  SSH key"
check_ssh_key

if [[ "$SSH_KEY_OK" == "true" ]]; then
  success "SSH key present and loaded in agent"
else
  warn "$SSH_KEY_ISSUE"
  WARNINGS=$(( WARNINGS + 1 ))
fi

# ── 6. git-lfs ─────────────────────────────────────────────────────────
step "🐙  git-lfs"
check_git_lfs_global

if [[ "$GIT_LFS_OK" == "true" ]]; then
  success "git-lfs installed and initialized globally"
else
  warn "$GIT_LFS_ISSUE"
  WARNINGS=$(( WARNINGS + 1 ))
fi

# ── 7. mise tools installed ──────────────────────────────────────────────
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
