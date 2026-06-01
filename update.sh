#!/usr/bin/env bash
# update.sh — keep your development environment current
#
# Run manually:     bash ~/dotfiles/update.sh
# Schedule daily with launchd (optional):
#   Create ~/Library/LaunchAgents/dev.dotfiles.update.plist with:
#     ProgramArguments: ["/bin/bash", "/Users/YOU/dotfiles/update.sh"]
#     StartCalendarInterval: { Hour: 9, Minute: 0 }   # 9 AM daily
#     StandardOutPath / StandardErrorPath: ~/dotfiles/logs/update.log
#   Then: launchctl load ~/Library/LaunchAgents/dev.dotfiles.update.plist
#
# What it does:
#   1. Pulls latest dotfiles from GitHub
#   2. Re-runs install.sh to pick up any new symlinks
#   3. Upgrades all Homebrew packages
#   4. Upgrades all mise-managed runtimes
#   5. Updates the Rust toolchain via rustup
#   6. Updates global Ruby gems
#   7. Runs verify.sh health check

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
UPDATE_START=$SECONDS
STEP=0
TOTAL_STEPS=7

# shellcheck source=scripts/bootstrap_helpers.sh
source "$(dirname "$0")/scripts/bootstrap_helpers.sh"
setup_colors

section() {
  STEP=$((STEP + 1))
  echo ""
  printf "${BOLD}${BLUE}  ▸ [%d/%d]  %s${RESET}\n" "$STEP" "$TOTAL_STEPS" "$*"
}

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}  🔄  dotfiles update${RESET}  —  keeping your environment current\n"
echo "  ─────────────────────────────────────────────────"
printf "  ${DIM}Machine${RESET}  %s\n" "$(scutil --get ComputerName 2>/dev/null || hostname)"
printf "  ${DIM}Date${RESET}     %s\n" "$(date '+%a %b %d %Y  %H:%M')"
echo "  ─────────────────────────────────────────────────"

# ── Steps ─────────────────────────────────────────────────────────────────────

section "🔃  Dotfiles"
git -C "$DOTFILES_DIR" pull --rebase --autostash
success "Dotfiles pulled"

section "🔗  Symlinks"
zsh "$DOTFILES_DIR/install.sh"

section "🍺  Homebrew"
brew update
brew upgrade
brew autoremove
brew cleanup --prune=7  # remove downloads older than 7 days
success "Homebrew packages upgraded"

section "⚡  Runtimes (mise)"
if command -v mise &>/dev/null; then
  mise upgrade
  success "Runtimes upgraded: $(mise current | tr '\n' ' ')"
else
  warn "mise not installed — skipping runtime upgrades"
fi

section "🦀  Rust"
if command -v rustup &>/dev/null; then
  rustup update
  success "Rust toolchain updated: $(rustc --version 2>/dev/null)"
else
  warn "rustup not installed — skipping"
fi

section "💎  Ruby gems"
if command -v gem &>/dev/null; then
  gem update --system --no-document 2>/dev/null
  success "Global gems updated"
else
  warn "gem not found — skipping (mise Ruby may not be active)"
fi

# uv tool upgrade — updates globally installed tools (black, ruff, etc.)
# brew upgrade updates the uv binary itself; this updates tools managed by uv
if command -v uv &>/dev/null; then
  uv tool upgrade --all 2>/dev/null || true
fi

section "🔍  Health check"
bash "$DOTFILES_DIR/verify.sh" || warn "Some checks need attention — see output above"

# ── Summary ───────────────────────────────────────────────────────────────────
_elapsed=$(( SECONDS - UPDATE_START ))
_mins=$(( _elapsed / 60 ))
_secs=$(( _elapsed % 60 ))

echo ""
echo "  ─────────────────────────────────────────────────"
printf "${GREEN}${BOLD}  ✅  Update complete${RESET}  in %dm %ds\n" "$_mins" "$_secs"
echo "  ─────────────────────────────────────────────────"
echo ""
