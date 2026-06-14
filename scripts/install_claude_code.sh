#!/usr/bin/env bash
# Install Claude Code CLI
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

# Color codes
CYAN='\033[0;36m'
RESET='\033[0m'

# Note: Version detection is dynamic - no hardcoded version needed
INSTALL_DIR="$HOME/.local/bin"

install_claude_code() {
  echo ""
  echo "╔════════════════════════════════════════════════╗"
  echo "║  Claude Code CLI Installation                  ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""

  # Check if already installed
  if command -v claude &>/dev/null; then
    current_version=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    if [[ "$current_version" != "unknown" ]]; then
      success "Claude Code $current_version is already installed"
      read -rp "  Reinstall? [y/N] " reinstall
      if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
        info "Keeping existing installation"
        return 0
      fi
    fi
  fi

  mkdir -p "$INSTALL_DIR"

  # Try to find installer in common locations
  INSTALLER_PATHS=(
    "$DOTFILES_DIR/system/installers/claude-code-installer"
    "$HOME/Downloads/ClaudeCode-macOS-v"*"/claude-code-installer"
    "$HOME/Downloads/claude-code-installer"
  )

  local found_installer=""
  for path in "${INSTALLER_PATHS[@]}"; do
    # Use glob expansion to handle wildcards
    for expanded_path in $path; do
      if [[ -f "$expanded_path" ]]; then
        found_installer="$expanded_path"
        break 2
      fi
    done
  done

  if [[ -n "$found_installer" ]]; then
    info "Found Claude Code installer at: $found_installer"
    read -rp "  Install Claude Code CLI? [Y/n] " do_install

    if [[ ! "$do_install" =~ ^[Nn]$ ]]; then
      info "Installing to $INSTALL_DIR..."
      bash "$found_installer" --prefix="$HOME/.local"
      success "Claude Code installed to $INSTALL_DIR/claude"

      # Verify installation
      if command -v claude &>/dev/null; then
        local installed_version
        installed_version=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        success "Verified: claude command available (version $installed_version)"
      else
        warn "Installation completed but 'claude' not found in PATH"
        info "Make sure $INSTALL_DIR is in your PATH"
        info "Add to ~/.zshrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
      fi

      return 0
    fi
  fi

  # Not found, provide instructions
  echo ""
  warn "Claude Code installer not found"
  echo ""
  info "To install Claude Code CLI:"
  echo ""
  printf "  1. Download from: ${CYAN}https://claude.com/download${RESET}\n"
  echo "  2. Save the installer to one of these locations:"
  echo "     • $DOTFILES_DIR/system/installers/claude-code-installer"
  echo "     • ~/Downloads/claude-code-installer"
  echo "  3. Re-run this script"
  echo ""
  read -rp "  Enter path to installer now (or press Enter to skip): " installer_path

  if [[ -n "$installer_path" && -f "$installer_path" ]]; then
    info "Installing to $INSTALL_DIR..."
    bash "$installer_path" --prefix="$HOME/.local"
    success "Claude Code installed to $INSTALL_DIR/claude"

    # Verify installation
    if command -v claude &>/dev/null; then
      local installed_version
      installed_version=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
      success "Verified: claude command available (version $installed_version)"
    else
      warn "Installation completed but 'claude' not found in PATH"
      info "Make sure $INSTALL_DIR is in your PATH"
    fi
  else
    info "Skipping Claude Code installation"
    info "Run this script again when you have the installer"
  fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_claude_code "$@"
fi
