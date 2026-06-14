#!/usr/bin/env bash
# Install work-specific VS Code extensions from .vsix files
# Part of Phase 2: Installation Scripts

set -e

# Get the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source helper functions if available
if [[ -f "$DOTFILES_DIR/scripts/bootstrap_helpers.sh" ]]; then
  source "$DOTFILES_DIR/scripts/bootstrap_helpers.sh"
else
  # Minimal fallback functions
  info() { echo "ℹ️  $*"; }
  success() { echo "✅ $*"; }
  warn() { echo "⚠️  $*"; }
  error() { echo "❌ $*" >&2; }
fi

install_work_vscode_extensions() {
  echo ""
  echo "╔════════════════════════════════════════════════╗"
  echo "║  VS Code Work Extensions Installation          ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""

  if ! command -v code &>/dev/null; then
    warn "VS Code CLI (code) not found"
    info "Install VS Code first: brew install --cask visual-studio-code"
    info "Or add the 'code' command from within VS Code:"
    info "  Command Palette (⌘⇧P) → Shell Command: Install 'code' command in PATH"
    return 1
  fi

  success "VS Code CLI found: $(code --version | head -1)"

  local extensions_dir="$DOTFILES_DIR/vscode/extensions"

  if [[ ! -d "$extensions_dir" ]]; then
    info "No work extensions directory found at: $extensions_dir"
    info "Create it with: mkdir -p $extensions_dir"
    echo ""
    info "Place .vsix files there:"
    echo "  • continue-*.vsix"
    echo "  • afs-code-cred-*.vsix"
    echo "  • any other work-specific extensions"
    return 0
  fi

  # Find all .vsix files
  local vsix_files=()
  while IFS= read -r -d '' file; do
    vsix_files+=("$file")
  done < <(find "$extensions_dir" -maxdepth 1 -name "*.vsix" -print0 2>/dev/null)

  if [[ ${#vsix_files[@]} -eq 0 ]]; then
    info "No .vsix files found in: $extensions_dir"
    echo ""
    info "To install work extensions:"
    echo "  1. Place .vsix files in: $extensions_dir"
    echo "  2. Re-run: bash $DOTFILES_DIR/scripts/install_vscode_work_extensions.sh"
    return 0
  fi

  echo ""
  info "Found ${#vsix_files[@]} extension(s):"
  for vsix in "${vsix_files[@]}"; do
    echo "  • $(basename "$vsix")"
  done
  echo ""

  read -rp "  Install these extensions? [Y/n] " do_install
  if [[ "$do_install" =~ ^[Nn]$ ]]; then
    info "Skipping installation"
    return 0
  fi

  local installed=0
  local failed=0

  for vsix in "${vsix_files[@]}"; do
    local ext_name
    ext_name=$(basename "$vsix")
    info "Installing $ext_name..."

    if code --install-extension "$vsix" --force 2>/dev/null; then
      success "Installed $ext_name"
      ((installed++))
    else
      error "Failed to install $ext_name"
      ((failed++))
    fi
  done

  echo ""
  echo "╔════════════════════════════════════════════════╗"
  echo "║  Installation Complete                         ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""

  if [[ $installed -gt 0 ]]; then
    success "Successfully installed: $installed extension(s)"
  fi

  if [[ $failed -gt 0 ]]; then
    warn "Failed to install: $failed extension(s)"
  fi

  echo ""
  info "Verify installed extensions:"
  echo "  code --list-extensions"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_work_vscode_extensions "$@"
fi
