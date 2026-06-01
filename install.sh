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

# Ruby — skip docs on every gem install
symlink "$DOTFILES_DIR/gemrc" "$HOME/.gemrc"

# PostgreSQL client defaults (pairs with Postgres.app)
symlink "$DOTFILES_DIR/psqlrc" "$HOME/.psqlrc"

# EditorConfig global fallback (project-level .editorconfig overrides this)
symlink "$DOTFILES_DIR/editorconfig" "$HOME/.editorconfig"

# Local git config (signing key, work email overrides — not committed)
mkdir -p "$HOME/.config/git"
if [[ ! -f "$HOME/.config/git/local.gitconfig" ]]; then
  cp "$DOTFILES_DIR/gitconfig.local.example" "$HOME/.config/git/local.gitconfig"
  success "Created ~/.config/git/local.gitconfig from template"
else
  success "Already exists: ~/.config/git/local.gitconfig"
fi

# Global git hooks (pre-commit runs in any repo with .pre-commit-config.yaml)
mkdir -p "$HOME/.config/git/hooks"
if [[ ! -f "$HOME/.config/git/hooks/pre-commit" ]]; then
  cat > "$HOME/.config/git/hooks/pre-commit" << 'EOF'
#!/usr/bin/env bash
# Runs pre-commit if the repo has a config file
if command -v pre-commit &>/dev/null && [[ -f ".pre-commit-config.yaml" ]]; then
  pre-commit run --hook-stage commit
fi
EOF
  chmod +x "$HOME/.config/git/hooks/pre-commit"
  success "Created global pre-commit hook"
else
  success "Already exists: global pre-commit hook"
fi

# ~/.config symlinks
mkdir -p "$HOME/.config"
symlink "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"

# direnv global helpers (layout_python, layout_node)
mkdir -p "$HOME/.config/direnv"
symlink "$DOTFILES_DIR/config/direnvrc" "$HOME/.config/direnv/direnvrc"

# mise global config (pinned Ruby + Node versions)
mkdir -p "$HOME/.config/mise"
symlink "$DOTFILES_DIR/config/mise.toml" "$HOME/.config/mise/config.toml"

# SSH config
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
symlink "$DOTFILES_DIR/ssh_config" "$HOME/.ssh/config"

# VS Code settings
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
if [[ -d "$VSCODE_DIR" ]]; then
  symlink "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_DIR/settings.json"
  success "VS Code settings linked"
  if command -v code &>/dev/null; then
    info "Installing VS Code extensions..."
    grep -v '^#' "$DOTFILES_DIR/vscode/extensions.txt" | xargs -L1 code --install-extension --force 2>/dev/null
    success "VS Code extensions installed"
  fi
else
  info "VS Code not installed — skipping settings symlink"
fi

echo ""
success "Done! Open a new shell or run: source ~/.zshrc"
