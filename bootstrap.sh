#!/usr/bin/env bash
# bootstrap.sh — install all dependencies and symlink dotfiles on a fresh Mac
# Usage: bash bootstrap.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

info()    { echo "[info]  $*"; }
success() { echo "[ok]    $*"; }
warn()    { echo "[warn]  $*"; }

# ------------------
# Xcode CLI Tools
# ------------------
if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo ""
  warn "Re-run this script after the Xcode tools finish installing."
  exit 0
fi
success "Xcode CLI Tools"

# ------------------
# Homebrew
# ------------------
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for the rest of this script
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [[ -f /usr/local/bin/brew ]]    && eval "$(/usr/local/bin/brew shellenv)"
fi
success "Homebrew $(brew --version | head -1)"

# ------------------
# Brew packages (Brewfile)
# ------------------
info "Installing packages from Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
success "Brew packages installed"

# fzf shell integration (key bindings + completion)
info "Setting up fzf shell integration..."
"$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
success "fzf configured"

# ------------------
# SSH key for commit signing
# ------------------
echo ""
echo "============================================"
echo "  Git Commit Signing Setup"
echo "============================================"
echo ""
echo "Every commit will be cryptographically signed with your SSH key."
echo "GitHub shows a 'Verified' badge on signed commits, proving they"
echo "actually came from you and weren't tampered with."
echo ""

if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  success "SSH key already exists at ~/.ssh/id_ed25519 — skipping generation"
else
  echo "No SSH key found. A new Ed25519 key will be generated now."
  echo ""
  echo "You will be asked for a passphrase. Recommendations:"
  echo "  • Setting a passphrase is more secure (recommended)"
  echo "  • macOS Keychain will remember it after the first use"
  echo "    so you won't be prompted on every commit"
  echo "  • Press Enter twice to skip (less secure but simpler)"
  echo ""
  read -rp "Press Enter to continue and generate your SSH key..."

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$(git config user.email)" -f "$HOME/.ssh/id_ed25519"
  ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"

  # Register key for local signature verification
  mkdir -p "$HOME/.config/git"
  echo "$(git config user.email) $(cat "$HOME/.ssh/id_ed25519.pub")" > "$HOME/.config/git/allowed_signers"

  # Copy to clipboard automatically
  pbcopy < "$HOME/.ssh/id_ed25519.pub"

  echo ""
  echo "============================================"
  echo "  ACTION REQUIRED: Add your key to GitHub"
  echo "============================================"
  echo ""
  echo "Your public key has been copied to your clipboard."
  echo ""
  echo "Follow these steps to register it with GitHub:"
  echo ""
  echo "  1. Open this URL in your browser:"
  echo "     https://github.com/settings/ssh/new"
  echo ""
  echo "  2. Fill in the form:"
  echo "     • Title:    give it a name like 'MacBook Pro - commit signing'"
  echo "     • Key type: Signing Key  ← important, not Authentication Key"
  echo "     • Key:      paste from clipboard (already copied)"
  echo ""
  echo "  3. Click 'Add SSH key'"
  echo ""
  echo "Your public key (also in clipboard):"
  echo ""
  cat "$HOME/.ssh/id_ed25519.pub"
  echo ""
  read -rp "Press Enter once you've added the key to GitHub to continue..."
fi

# ------------------
# GitHub CLI auth
# ------------------
if ! gh auth status &>/dev/null; then
  echo ""
  echo "============================================"
  echo "  GitHub CLI Authentication"
  echo "============================================"
  echo ""
  echo "gh (GitHub CLI) is installed but not authenticated."
  echo "You'll need this for creating PRs, managing issues,"
  echo "and the SSH signing key step later."
  echo ""
  gh auth login
else
  success "GitHub CLI already authenticated"
fi

# ------------------
# Ruby + Node + Java via mise
# ------------------
info "Installing Ruby, Node, Java, Python, and Go via mise..."
mise install ruby@3.3.6 node@22 java@temurin-21 python@3.12 go@1.24
mise use --global ruby@3.3.6 node@22 java@temurin-21 python@3.12 go@1.24
success "Ruby, Node, Java, Python, and Go installed via mise"

# ------------------
# Gems
# ------------------
info "Installing colorls..."
mise exec ruby@3.3.6 -- gem install colorls
success "colorls"

# ------------------
# Rust via rustup
# ------------------
# Note: we check for `rustup`, NOT `rustc` — a system/Homebrew rustc does not
# give you toolchain management (stable/nightly/components). rustup does.
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

# ------------------
# NVM → mise migration
# ------------------
# mise handles Node. If NVM is installed, detect whether it has versions:
#   - Empty/ghost install → offer to remove it automatically
#   - Has versions installed → warn and show migration steps (do NOT remove)
_nvm_dir="${NVM_DIR:-$HOME/.nvm}"
if [[ -d "$_nvm_dir" ]]; then
  _nvm_count=$(ls "$_nvm_dir/versions/node/" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$_nvm_count" -eq 0 ]]; then
    echo ""
    warn "NVM is installed at $_nvm_dir but has no Node versions (ghost install)."
    warn "mise handles Node — NVM is no longer needed on this machine."
    read -rp "Remove NVM automatically? [y/N] " _rm_nvm
    if [[ "$_rm_nvm" =~ ^[Yy]$ ]]; then
      rm -rf "$_nvm_dir"
      brew uninstall nvm 2>/dev/null || true
      unset NVM_DIR
      success "NVM removed — mise manages Node from here"
    else
      warn "Keeping NVM. The zshrc NVM guard will silence it since no versions are installed."
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
unset _nvm_dir _nvm_count

# ------------------
# tmux plugin manager (TPM)
# ------------------
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  info "Installing tmux plugin manager (TPM)..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" --depth=1
  success "TPM installed — open tmux and press prefix+I to install plugins"
else
  success "TPM already installed"
fi

# ------------------
# git-lfs
# ------------------
git lfs install --skip-repo
success "git-lfs"

# ------------------
# Symlink dotfiles
# ------------------
info "Symlinking dotfiles..."
zsh "$DOTFILES_DIR/install.sh"

# ------------------
# Local overrides
# ------------------
if [[ ! -f "$HOME/.zshrc.local" ]]; then
  cp "$DOTFILES_DIR/zshrc.local.example" "$HOME/.zshrc.local"
  warn "Created ~/.zshrc.local from template — edit it to add machine-specific config."
fi

# ------------------
# macOS defaults
# ------------------
echo ""
read -rp "Apply recommended macOS developer defaults? (key repeat, Dock, Finder, etc.) [y/N] " apply_macos
if [[ "$apply_macos" =~ ^[Yy]$ ]]; then
  bash "$DOTFILES_DIR/macos.sh"
else
  info "Skipped macOS defaults. Run manually later: bash ~/dotfiles/macos.sh"
fi

echo ""
success "Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.zshrc.local with any machine-specific config"
echo "  2. Open a new terminal (or run: source ~/.zshrc)"
echo "  3. Install Hyper (not in Homebrew): https://hyper.is"
echo "  4. VS Code, Postgres.app, DBeaver, and fonts were installed via Brewfile"
