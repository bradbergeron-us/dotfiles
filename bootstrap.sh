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
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  info "Generating SSH key for commit signing..."
  ssh-keygen -t ed25519 -C "$(git config user.email)" -f "$HOME/.ssh/id_ed25519"
  ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"

  # Create allowed_signers for local verification
  mkdir -p "$HOME/.config/git"
  echo "$(git config user.email) $(cat $HOME/.ssh/id_ed25519.pub)" > "$HOME/.config/git/allowed_signers"

  echo ""
  warn "SSH key generated. Add the following public key to GitHub (Settings → SSH keys → New → type: Signing):"
  echo ""
  cat "$HOME/.ssh/id_ed25519.pub"
  echo ""
else
  success "SSH key already exists: ~/.ssh/id_ed25519"
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
