#!/usr/bin/env bash
# bootstrap.sh — install all dependencies and symlink dotfiles on a fresh Mac
# Usage: bash bootstrap.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOTSTRAP_START=$SECONDS
STEP=0
TOTAL_STEPS=13

# ── Colors (disabled when not attached to a terminal) ────────────────────────
if [[ -t 1 ]]; then
  RESET='\033[0m';  BOLD='\033[1m';   DIM='\033[2m'
  GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'
  BLUE='\033[1;34m'
else
  RESET=''; BOLD=''; DIM=''; GREEN=''; YELLOW=''; CYAN=''; BLUE=''
fi

info()    { printf "${CYAN}  → %s${RESET}\n" "$*"; }
success() { printf "${GREEN}  ✓ %s${RESET}\n" "$*"; }
warn()    { printf "${YELLOW}  ⚠ %s${RESET}\n" "$*"; }

step() {
  STEP=$((STEP + 1))
  echo ""
  printf "${BOLD}${BLUE}  ▸ [%d/%d]  %s${RESET}\n" "$STEP" "$TOTAL_STEPS" "$*"
}

# ── Startup banner ───────────────────────────────────────────────────────────
echo ""
printf "${BOLD}  🚀  dotfiles bootstrap${RESET}  —  macOS developer setup\n"
echo "  ─────────────────────────────────────────────────"
printf "  ${DIM}Machine${RESET}  %s\n" "$(scutil --get ComputerName 2>/dev/null || hostname)"
printf "  ${DIM}Date${RESET}     %s\n" "$(date '+%a %b %d %Y  %H:%M')"
echo "  ─────────────────────────────────────────────────"

# ── Steps ─────────────────────────────────────────────────────────────────────
step "🛠️  Xcode Command Line Tools"
if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo ""
  warn "Re-run this script after the Xcode tools finish installing."
  exit 0
fi
success "Xcode CLI Tools"

step "🍺  Homebrew"
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for the rest of this script
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [[ -f /usr/local/bin/brew ]]    && eval "$(/usr/local/bin/brew shellenv)"
fi
success "Homebrew $(brew --version | head -1)"

step "📦  Packages (brew bundle)"
info "Installing packages from Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
success "Brew packages installed"

step "🔍  fzf shell integration"
info "Setting up fzf shell integration..."
"$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
success "fzf configured"

step "🔑  SSH key for commit signing"
echo ""
printf "${DIM}  Every commit will be signed with your SSH key. GitHub shows a\n"
printf "  'Verified' badge proving it actually came from you.${RESET}\n"
echo ""

if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  success "SSH key already exists at ~/.ssh/id_ed25519 — skipping generation"
else
  printf "  No SSH key found — a new Ed25519 key will be generated now.\n"
  echo ""
  printf "  Passphrase recommendations:\n"
  printf "  • Setting one is more secure (recommended)\n"
  printf "  • macOS Keychain remembers it after first use\n"
  printf "  • Press Enter twice to skip (less secure but simpler)\n"
  echo ""
  read -rp "  Press Enter to generate your SSH key... "

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  # Use configured email, or prompt if not yet set (gitconfig is symlinked later at step 12)
  _key_email="$(git config user.email 2>/dev/null || true)"
  if [[ -z "$_key_email" ]]; then
    echo ""
    read -rp "  Enter your email for the SSH key (used as key comment): " _key_email
  fi

  ssh-keygen -t ed25519 -C "$_key_email" -f "$HOME/.ssh/id_ed25519"
  ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"

  # Register key for local signature verification
  mkdir -p "$HOME/.config/git"
  echo "$_key_email $(cat "$HOME/.ssh/id_ed25519.pub")" > "$HOME/.config/git/allowed_signers"
  unset _key_email

  # Copy to clipboard automatically
  pbcopy < "$HOME/.ssh/id_ed25519.pub"

  echo ""
  printf "${BOLD}  Action required: add your key to GitHub${RESET}\n"
  echo ""
  printf "  Your public key is ${GREEN}already on your clipboard${RESET}. Go to:\n"
  printf "  ${CYAN}  https://github.com/settings/ssh/new${RESET}\n"
  echo ""
  printf "  Title:    e.g. 'MacBook Pro — commit signing'\n"
  printf "  Key type: ${BOLD}Signing Key${RESET}  ← not Authentication Key\n"
  printf "  Key:      paste from clipboard\n"
  echo ""
  printf "  Your public key (also on clipboard):\n"
  echo ""
  cat "$HOME/.ssh/id_ed25519.pub"
  echo ""
  read -rp "  Press Enter once you've added the key to GitHub to continue... "
fi

step "🐙  GitHub CLI authentication"
if ! gh auth status &>/dev/null; then
  echo ""
  printf "  ${DIM}gh is installed but not authenticated. You'll need this for\n"
  printf "  creating PRs, managing issues, and interacting with GitHub.${RESET}\n"
  echo ""
  gh auth login
else
  success "GitHub CLI already authenticated"
fi

step "⚡  Runtimes via mise  (Ruby · Node · Java · Python · Go)"
mise install ruby@3.3.6 node@22 java@temurin-21 python@3.12 go@1.24
mise use --global ruby@3.3.6 node@22 java@temurin-21 python@3.12 go@1.24
success "Ruby 3.3.6 · Node 22 · Java 21 · Python 3.12 · Go 1.24  (via mise)"

step "💎  Ruby gems"
info "Installing colorls..."
mise exec ruby@3.3.6 -- gem install colorls
success "colorls"

step "🦀  Rust (rustup)"
# Note: we check for `rustup`, NOT `rustc` — a system/Homebrew rustc does not
# give you toolchain management (stable/nightly/components). rustup does.
# If `brew install rust` (the static formula) is present alongside rustup,
# remove it to avoid PATH conflicts: brew uninstall rust
if brew list rust &>/dev/null 2>&1; then
  warn "'brew install rust' (static formula) detected — it conflicts with rustup."
  warn "Remove it to avoid PATH confusion: brew uninstall rust"
  warn "rustup (installed via Brewfile) manages the Rust toolchain from here."
fi
if ! command -v rustup &>/dev/null; then
  info "Initializing Rust toolchain via rustup..."
  # --no-modify-path: zshrc sources ~/.cargo/env directly
  rustup-init -y --no-modify-path
  # shellcheck source=/dev/null
  . "$HOME/.cargo/env"
  rustup component add rustfmt clippy
  success "Rust installed via rustup (stable + rustfmt + clippy)"
else
  success "rustup already installed: $(rustc --version 2>/dev/null || echo 'rustc not yet in PATH')"
fi

# NVM migration check (conditional — runs only if ~/.nvm exists)
_nvm_dir="${NVM_DIR:-$HOME/.nvm}"
[[ -d "$_nvm_dir" ]] && info "NVM detected — checking migration status..."
if [[ -d "$_nvm_dir" ]]; then
  _nvm_count=$(ls "$_nvm_dir/versions/node/" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "${_nvm_count:-0}" -eq 0 ]]; then
    echo ""
    warn "NVM is installed at $_nvm_dir but has no Node versions (ghost install)."
    warn "mise handles Node — NVM is no longer needed on this machine."
    read -rp "  Remove NVM automatically? [y/N] " _rm_nvm
    if [[ "$_rm_nvm" =~ ^[Yy]$ ]]; then
      rm -rf "$_nvm_dir"
      brew uninstall nvm 2>/dev/null || true
      unset NVM_DIR
      success "NVM removed — mise manages Node from here"
    else
      warn "Keeping NVM. The zshrc NVM guard will silence it since no versions are installed."
      unset _rm_nvm
    fi
  else
    echo ""
    warn "NVM has $_nvm_count Node version(s) installed. Recommended migration path:"
    warn "  1. For each Node version you use, run: mise use --global node@<version>"
    warn "  2. Test your projects with mise-managed Node"
    warn "  3. Once satisfied: brew uninstall nvm && rm -rf ~/.nvm"
    warn "Continuing without touching NVM — both mise and NVM can coexist during migration."
  fi
fi
unset _nvm_dir _nvm_count _rm_nvm

step "🖥️  tmux plugin manager (TPM)"
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  info "Installing tmux plugin manager (TPM)..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" --depth=1
  success "TPM cloned"
else
  success "TPM already installed"
fi
# Install/update plugins headlessly (no tmux session required; idempotent)
info "Installing tmux plugins..."
TMUX='' "$HOME/.tmux/plugins/tpm/bin/install_plugins" &>/dev/null
success "tmux plugins ready (tmux-sensible, tmux-resurrect, tmux-continuum)"

step "📁  git-lfs"
git lfs install --skip-repo
success "git-lfs configured (large file pointer tracking enabled globally)"

step "🔗  Dotfile symlinks"
zsh "$DOTFILES_DIR/install.sh"

if [[ ! -f "$HOME/.zshrc.local" ]]; then
  cp "$DOTFILES_DIR/zshrc.local.example" "$HOME/.zshrc.local"
  warn "Created ~/.zshrc.local from template — edit it with machine-specific config"
fi

step "⚙️  macOS developer defaults"
echo ""
printf "  Will apply:\n"
printf "  • Keyboard   — fast key repeat, disable autocorrect & smart quotes\n"
printf "  • Trackpad   — enable tap-to-click\n"
printf "  • Finder     — show hidden files & all extensions, path bar, list view\n"
printf "  • Dock       — auto-hide, instant animation, no recent apps\n"
printf "  • Screenshots → ~/Desktop/screenshots/ (PNG, no shadow)\n"
printf "  • TextEdit   — plain text mode by default\n"
printf "  • Mission Control — faster animation, don't rearrange Spaces\n"
echo ""
read -rp "  Apply these settings? [y/N] " apply_macos
if [[ "$apply_macos" =~ ^[Yy]$ ]]; then
  bash "$DOTFILES_DIR/macos.sh"
  success "macOS defaults applied — Finder and Dock restarted automatically"
  warn "Key repeat and trackpad changes take full effect after logout"
else
  info "Skipped. Run manually any time: bash ~/dotfiles/macos.sh"
fi

_elapsed=$(( SECONDS - BOOTSTRAP_START ))
_mins=$(( _elapsed / 60 ))
_secs=$(( _elapsed % 60 ))

echo ""
echo "  ─────────────────────────────────────────────────"
printf "${GREEN}${BOLD}  🎉  Bootstrap complete${RESET}  in %dm %ds\n" "$_mins" "$_secs"
echo "  ─────────────────────────────────────────────────"
echo ""
printf "  ${BOLD}Next steps${RESET}\n"
printf "  1. Edit ${CYAN}~/.zshrc.local${RESET} with machine-specific config\n"
printf "  2. Open a new terminal  (or: ${CYAN}source ~/.zshrc${RESET})\n"
printf "  3. Keep everything current: ${CYAN}bash ~/dotfiles/update.sh${RESET}\n"
echo ""
