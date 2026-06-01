#!/usr/bin/env zsh
# install.sh — symlink dotfiles into $HOME
# Run: zsh install.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

info()    { print -P "%F{cyan}[info]%f  $*"; }
success() { print -P "%F{green}[ok]%f    $*"; }
backup()  { print -P "%F{yellow}[backup]%f $*"; }
error()   { print -P "%F{red}[error]%f $*"; }

symlink() {
  local src="$1"
  local dest="$2"

  # Back up existing file/symlink if it's not already our symlink
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      success "Already linked: $dest"
      return
    fi
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$BACKUP_DIR/"
    backup "Backed up $(basename "$dest") → $BACKUP_DIR/"
  fi

  ln -sf "$src" "$dest"
  success "Linked: $dest → $src"
}

info "Installing dotfiles from $DOTFILES_DIR"
echo ""

# Home directory symlinks
symlink "$DOTFILES_DIR/zshrc"    "$HOME/.zshrc"
symlink "$DOTFILES_DIR/zprofile" "$HOME/.zprofile"
symlink "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
symlink "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
symlink "$DOTFILES_DIR/hyper.js"  "$HOME/.hyper.js"

# Git global ignore
symlink "$DOTFILES_DIR/gitignore_global" "$HOME/.gitignore_global"

# ~/.config symlinks
mkdir -p "$HOME/.config"
symlink "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"

echo ""
success "Done! Open a new shell or run: source ~/.zshrc"
