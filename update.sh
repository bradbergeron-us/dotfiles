#!/usr/bin/env bash
# update.sh — keep your development environment current
#
# Run manually:     bash ~/dotfiles/update.sh
# Schedule daily with launchd (one command):
#   bash ~/dotfiles/setup-scheduler.sh             # install
#   bash ~/dotfiles/setup-scheduler.sh --uninstall # remove
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
# shellcheck disable=SC2034  # used by step() in helpers
STEP=0
# shellcheck disable=SC2034
TOTAL_STEPS=7

# shellcheck source=scripts/bootstrap_helpers.sh
source "$(dirname "$0")/scripts/bootstrap_helpers.sh"
setup_colors

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}  🔄  dotfiles update${RESET}  —  keeping your environment current\n"
echo "  ─────────────────────────────────────────────────"
printf "  ${DIM}Machine${RESET}  %s\n" "$(scutil --get ComputerName 2>/dev/null || hostname)"
printf "  ${DIM}Date${RESET}     %s\n" "$(date '+%a %b %d %Y  %H:%M')"
echo "  ─────────────────────────────────────────────────"

# ── Steps ─────────────────────────────────────────────────────────────────────

step "🔃  Dotfiles"
git -C "$DOTFILES_DIR" pull --rebase --autostash
success "Dotfiles pulled"

step "🔗  Symlinks"
zsh "$DOTFILES_DIR/install.sh"

step "🍺  Homebrew"
brew update
brew upgrade
brew autoremove
brew cleanup --prune=7  # remove downloads older than 7 days
success "Homebrew packages upgraded"

step "⚡  Runtimes (mise)"
if command -v mise &>/dev/null; then
  mise upgrade
  success "Runtimes upgraded: $(mise current | tr '\n' ' ')"
else
  warn "mise not installed — skipping runtime upgrades"
fi

step "🦀  Rust"
if command -v rustup &>/dev/null; then
  rustup update
  success "Rust toolchain updated: $(rustc --version 2>/dev/null)"
else
  warn "rustup not installed — skipping"
fi

step "💎  Ruby gems"
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

step "🔍  Health check"
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
