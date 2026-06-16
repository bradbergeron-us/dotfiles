#!/usr/bin/env zsh
# install.sh — symlink dotfiles into $HOME
# Run: zsh install.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Counters
typeset -i _linked=0 _current=0 _backed=0 _skipped=0

info()    { print -P "%F{cyan}  → %f$*"; }
success() { print -P "%F{green}  ✓ %f$*"; }
backup()  { print -P "%F{yellow}  ⚠ %f$*"; }

symlink() {
  local src="$1"
  local dest="$2"
  # Display path with ~ instead of $HOME for readability
  local short="${dest/$HOME/\~}"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      success "current   $short"
      (( _current++ )) || true
      return
    fi
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$BACKUP_DIR/"
    backup "backed up  $short"
    (( _backed++ )) || true
  fi

  ln -sf "$src" "$dest"
  success "linked    $short"
  (( _linked++ )) || true
}

echo ""
print -P "%F{cyan}  🔗  dotfiles%f  ─  symlinking from ${DOTFILES_DIR/$HOME/\~}"
echo "  ─────────────────────────────────────────────────"

# Tracked dotfile symlinks — single source of truth: config/symlinks.map
# (install.sh creates them; verify.sh, bootstrap --dry-run, and CI read the
# same file, so the mapping lives in exactly one place.)
SYMLINK_MAP="$DOTFILES_DIR/config/symlinks.map"

# Resolve the active profile so only records that apply to it are linked. Sourcing
# is side-effect-free. With nothing set this resolves to `personal`, which
# includes every tag in use today (gui + core) — i.e. the same set as before
# profiles existed (plain `zsh install.sh` still links everything).
# shellcheck source=scripts/lib/profile_helpers.sh
source "$DOTFILES_DIR/scripts/lib/profile_helpers.sh"
_PROFILE="$(current_profile)"
info "profile   $_PROFILE"

if [[ -r "$SYMLINK_MAP" ]]; then
  while read -r src_rel dest_rel tags_rel; do
    [[ -z "$src_rel" || "$src_rel" == \#* ]] && continue
    if ! profile_includes "$_PROFILE" "${tags_rel:-}"; then
      info "skip      $dest_rel  (not in profile $_PROFILE)"
      (( _skipped++ )) || true
      continue
    fi
    dest="$HOME/$dest_rel"
    mkdir -p "$(dirname "$dest")"
    symlink "$DOTFILES_DIR/$src_rel" "$dest"
  done < "$SYMLINK_MAP"
else
  backup "symlink manifest not found: $SYMLINK_MAP"
fi

# Harden ~/.ssh perms (the directory is created above when linking ssh_config)
[[ -d "$HOME/.ssh" ]] && chmod 700 "$HOME/.ssh"

# Git config: a thin, REAL ~/.gitconfig that *includes* the tracked config.
# Deliberately NOT a symlink — this keeps `git config --global` and tools like
# `gh auth setup-git` from writing into the tracked dotfile (home/gitconfig).
# Machine/tool-written settings accumulate here and override the shared defaults.
GITCONFIG_DEST="$HOME/.gitconfig"
GITCONFIG_SRC="$DOTFILES_DIR/home/gitconfig"
GITCONFIG_SHORT="${GITCONFIG_DEST/$HOME/\~}"
if [[ -f "$GITCONFIG_DEST" && ! -L "$GITCONFIG_DEST" ]] && grep -qF "path = $GITCONFIG_SRC" "$GITCONFIG_DEST"; then
  success "current   $GITCONFIG_SHORT (thin include of dotfiles gitconfig)"
else
  if [[ -e "$GITCONFIG_DEST" || -L "$GITCONFIG_DEST" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$GITCONFIG_DEST" "$BACKUP_DIR/"
    backup "backed up  $GITCONFIG_SHORT (was a symlink/real file)"
  fi
  cat > "$GITCONFIG_DEST" <<EOF
# ~/.gitconfig — managed by dotfiles (thin include; intentionally NOT a symlink).
# Keeping this a real file means 'git config --global ...' and tools such as
# 'gh auth setup-git' write here instead of into the tracked repo file. Shared
# config is pulled in from the repo below; anything written after the include
# (by you or tooling) overrides those defaults on this machine only.
[include]
	path = $GITCONFIG_SRC
EOF
  success "linked    $GITCONFIG_SHORT (thin include → home/gitconfig)"
fi

# Local git config (signing key, work email overrides — not committed)
mkdir -p "$HOME/.config/git"
if [[ ! -f "$HOME/.config/git/local.gitconfig" ]]; then
  cp "$DOTFILES_DIR/home/examples/gitconfig.local.example" "$HOME/.config/git/local.gitconfig"
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

# VS Code settings
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
if [[ -d "$VSCODE_DIR" ]]; then
  symlink "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_DIR/settings.json"
  success "VS Code settings linked"
  if command -v code &>/dev/null; then
    info "Installing VS Code extensions..."
    # Run the install loop inside a subshell rooted at a throwaway temp dir.
    # `code --install-extension` drops empty `publisher.extension` residue
    # files into the cwd; isolating cwd here guarantees that residue never
    # lands in the dotfiles repo (the root cause of past stray files).
    (
      cd "$(mktemp -d)" || exit 1
      grep -v '^#' "$DOTFILES_DIR/vscode/extensions.txt" | xargs -L1 code --install-extension --force 2>/dev/null
    )
    success "VS Code extensions installed"
  fi
else
  info "VS Code not installed — skipping settings symlink"
fi

echo ""
echo "  ─────────────────────────────────────────────────"
success "${_linked} linked  ·  ${_current} current  ·  ${_backed} backed up  ·  ${_skipped} skipped"
if (( _backed > 0 )); then
  backup "backups saved to ${BACKUP_DIR/$HOME/\~}"
fi
echo ""
success "🎉  Done — open a new shell or: source ~/.zshrc"
