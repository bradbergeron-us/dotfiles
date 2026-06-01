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
# Brew packages
# ------------------
info "Installing brew packages..."
brew install \
  chruby \
  ruby-install \
  nvm \
  starship \
  tmux \
  zoxide \
  git-lfs \
  openssl@3

success "Brew packages installed"

# ------------------
# Ruby
# ------------------
RUBY_VERSION="3.3.6"
if ! ls ~/.rubies/ruby-${RUBY_VERSION} &>/dev/null; then
  info "Installing Ruby ${RUBY_VERSION} (this may take a few minutes)..."
  ruby-install ruby ${RUBY_VERSION}
fi
success "Ruby ${RUBY_VERSION}"

# ------------------
# Gems
# ------------------
info "Installing colorls..."
source "$(brew --prefix chruby)/share/chruby/chruby.sh"
chruby ruby-${RUBY_VERSION}
gem install colorls
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
