#!/usr/bin/env bash
# uninstall.sh — remove dotfiles and optionally clean up installed packages
# Usage: bash uninstall.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
UNINSTALL_START=$SECONDS

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { printf "${CYAN}  → ${RESET}%s\n" "$*"; }
success() { printf "${GREEN}  ✓ ${RESET}%s\n" "$*"; }
warn()    { printf "${YELLOW}  ⚠ ${RESET}%s\n" "$*"; }
error()   { printf "${RED}  ✗ ${RESET}%s\n" "$*"; }

# ── Startup banner ───────────────────────────────────────────────────────────
echo ""
printf "${BOLD}${RED}  🗑️  dotfiles uninstall${RESET}  —  remove configurations\n"
echo "  ─────────────────────────────────────────────────"
printf "  ${DIM}Machine${RESET}  %s\n" "$(scutil --get ComputerName 2>/dev/null || hostname)"
printf "  ${DIM}Date${RESET}     %s\n" "$(date '+%a %b %d %Y  %H:%M')"
echo "  ─────────────────────────────────────────────────"
echo ""

warn "This will remove dotfile symlinks and optionally uninstall packages."
echo ""
read -rp "  Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo ""
  info "Uninstall cancelled"
  exit 0
fi

echo ""
echo "  ─────────────────────────────────────────────────"

# ── Step 1: Remove dotfile symlinks ──────────────────────────────────────────
echo ""
printf "${BOLD}  1. Removing dotfile symlinks${RESET}\n"
echo ""

typeset -i removed=0
typeset -i skipped=0

remove_symlink() {
  local link="$1"
  local short="${link/$HOME/\~}"

  if [[ -L "$link" ]]; then
    # Check if it points to our dotfiles
    local target
    target="$(readlink "$link")"
    if [[ "$target" == "$DOTFILES_DIR"* ]]; then
      rm "$link"
      success "removed    $short"
      (( removed++ ))
    else
      info "skipped    $short (points elsewhere: $target)"
      (( skipped++ ))
    fi
  elif [[ -e "$link" ]]; then
    info "skipped    $short (not a symlink)"
    (( skipped++ ))
  else
    info "missing    $short"
  fi
}

# Home directory symlinks
remove_symlink "$HOME/.zshrc"
remove_symlink "$HOME/.zprofile"
remove_symlink "$HOME/.gitconfig"
remove_symlink "$HOME/.tmux.conf"
remove_symlink "$HOME/.hyper.js"
remove_symlink "$HOME/.gitignore_global"
remove_symlink "$HOME/.gemrc"
remove_symlink "$HOME/.irbrc"
remove_symlink "$HOME/.pryrc"
remove_symlink "$HOME/.psqlrc"
remove_symlink "$HOME/.npmrc"
remove_symlink "$HOME/.editorconfig"

# Config directory symlinks
remove_symlink "$HOME/.config/starship.toml"
remove_symlink "$HOME/.config/direnv/direnvrc"
remove_symlink "$HOME/.config/mise/config.toml"
remove_symlink "$HOME/.ssh/config"

# VS Code
if [[ -d "$HOME/Library/Application Support/Code/User" ]]; then
  remove_symlink "$HOME/Library/Application Support/Code/User/settings.json"
fi

echo ""
success "$removed symlinks removed, $skipped skipped"

# ── Step 2: Optional - Remove local configs ──────────────────────────────────
echo ""
printf "${BOLD}  2. Remove local configuration files?${RESET}\n"
echo ""
warn "This will remove ~/.zshrc.local and ~/.config/git/local.gitconfig"
echo ""
read -rp "  Remove local configs? [y/N] " remove_local
if [[ "$remove_local" =~ ^[Yy]$ ]]; then
  [[ -f "$HOME/.zshrc.local" ]] && rm "$HOME/.zshrc.local" && success "Removed ~/.zshrc.local"
  [[ -f "$HOME/.config/git/local.gitconfig" ]] && rm "$HOME/.config/git/local.gitconfig" && success "Removed ~/.config/git/local.gitconfig"
else
  info "Kept local configs"
fi

# ── Step 3: Optional - Remove runtimes ───────────────────────────────────────
echo ""
printf "${BOLD}  3. Remove mise-managed runtimes?${RESET}\n"
echo ""
info "This will uninstall Ruby, Node, Java, Python, Go managed by mise"
echo ""
read -rp "  Remove runtimes? [y/N] " remove_runtimes
if [[ "$remove_runtimes" =~ ^[Yy]$ ]]; then
  if command -v mise &>/dev/null; then
    info "Removing mise-managed runtimes..."
    mise uninstall ruby@3.3.6 2>/dev/null || true
    mise uninstall node@22 2>/dev/null || true
    mise uninstall java@temurin-21 2>/dev/null || true
    mise uninstall python@3.12 2>/dev/null || true
    mise uninstall go@1.24 2>/dev/null || true
    success "Runtimes removed"
  else
    info "mise not installed, nothing to remove"
  fi
else
  info "Kept runtimes"
fi

# ── Step 4: Optional - Remove Rust ───────────────────────────────────────────
echo ""
printf "${BOLD}  4. Remove Rust toolchain?${RESET}\n"
echo ""
read -rp "  Remove Rust (rustup)? [y/N] " remove_rust
if [[ "$remove_rust" =~ ^[Yy]$ ]]; then
  if command -v rustup &>/dev/null; then
    rustup self uninstall -y
    success "Rust removed"
  else
    info "Rust not installed"
  fi
else
  info "Kept Rust"
fi

# ── Step 5: Optional - Remove tmux plugins ───────────────────────────────────
echo ""
printf "${BOLD}  5. Remove tmux plugin manager?${RESET}\n"
echo ""
read -rp "  Remove TPM and plugins? [y/N] " remove_tpm
if [[ "$remove_tpm" =~ ^[Yy]$ ]]; then
  if [[ -d "$HOME/.tmux/plugins" ]]; then
    rm -rf "$HOME/.tmux/plugins"
    success "tmux plugins removed"
  else
    info "tmux plugins not installed"
  fi
else
  info "Kept tmux plugins"
fi

# ── Step 6: Optional - Uninstall Homebrew packages ───────────────────────────
echo ""
printf "${BOLD}  6. Uninstall Homebrew packages?${RESET}\n"
echo ""
warn "This will uninstall ALL packages listed in Brewfile"
warn "This includes: git, VS Code, Docker Desktop, and all CLI tools"
echo ""
read -rp "  Uninstall Homebrew packages? [y/N] " remove_brew
if [[ "$remove_brew" =~ ^[Yy]$ ]]; then
  if command -v brew &>/dev/null; then
    info "Uninstalling Homebrew packages from Brewfile..."
    brew bundle cleanup --file="$DOTFILES_DIR/Brewfile" --force
    success "Homebrew packages uninstalled"
  else
    info "Homebrew not installed"
  fi
else
  info "Kept Homebrew packages"
fi

# ── Step 7: Optional - Uninstall Homebrew itself ─────────────────────────────
echo ""
printf "${BOLD}  7. Uninstall Homebrew completely?${RESET}\n"
echo ""
warn "This will remove Homebrew and ALL installed packages"
echo ""
read -rp "  Uninstall Homebrew? [y/N] " remove_homebrew
if [[ "$remove_homebrew" =~ ^[Yy]$ ]]; then
  if command -v brew &>/dev/null; then
    info "Uninstalling Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    success "Homebrew uninstalled"
  else
    info "Homebrew not installed"
  fi
else
  info "Kept Homebrew"
fi

# ── Step 8: Restore shell defaults ───────────────────────────────────────────
echo ""
printf "${BOLD}  8. Restore default shell configuration?${RESET}\n"
echo ""
info "This will create a minimal ~/.zshrc to restore basic shell functionality"
echo ""
read -rp "  Create default ~/.zshrc? [y/N] " restore_zshrc
if [[ "$restore_zshrc" =~ ^[Yy]$ ]]; then
  cat > "$HOME/.zshrc" << 'EOF'
# Default zsh configuration
# Created by dotfiles uninstall script

# Basic PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Homebrew (if still installed)
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -f /usr/local/bin/brew ]]    && eval "$(/usr/local/bin/brew shellenv)"

# Basic prompt
autoload -Uz promptinit
promptinit
prompt adam1

# Basic completions
autoload -Uz compinit
compinit

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
EOF
  success "Created default ~/.zshrc"
else
  info "Skipped default ~/.zshrc creation"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
_elapsed=$(( SECONDS - UNINSTALL_START ))
_mins=$(( _elapsed / 60 ))
_secs=$(( _elapsed % 60 ))

echo ""
echo "  ─────────────────────────────────────────────────"
printf "${GREEN}${BOLD}  ✅  Uninstall complete${RESET}  in %dm %ds\n" "$_mins" "$_secs"
echo "  ─────────────────────────────────────────────────"
echo ""
printf "  ${BOLD}Next steps${RESET}\n"
printf "  1. Open a new terminal to load default shell config\n"
printf "  2. Optional: Remove the dotfiles directory: ${CYAN}rm -rf ~/dotfiles${RESET}\n"
printf "  3. Optional: Clean up backups: ${CYAN}rm -rf ~/.dotfiles_backup${RESET}\n"
echo ""
