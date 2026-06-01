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
# Ruby + Node via mise
# ------------------
info "Installing Ruby 3.3.6 and Node 22 via mise..."
mise install ruby@3.3.6 node@22
mise use --global ruby@3.3.6 node@22
success "Ruby $(mise exec ruby@3.3.6 -- ruby -e 'print RUBY_VERSION') and Node $(mise exec node@22 -- node -v)"

# ------------------
# Gems
# ------------------
info "Installing colorls..."
mise exec ruby@3.3.6 -- gem install colorls
success "colorls"

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

echo ""
success "Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.zshrc.local with any machine-specific config"
echo "  2. Open a new terminal (or run: source ~/.zshrc)"
echo "  3. Install Hyper:   https://hyper.is"
echo "  4. Install VS Code: https://code.visualstudio.com"
