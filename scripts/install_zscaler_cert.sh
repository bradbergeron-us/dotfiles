#!/usr/bin/env bash
# Install Zscaler root certificate for Claude Code and Continue
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

CERT_NAME="ZscalerRootCertificate-2048-SHA256"
CERT_FILE="${CERT_NAME}.crt"

install_zscaler_cert() {
  echo ""
  echo "╔════════════════════════════════════════════════╗"
  echo "║  Zscaler Certificate Installation              ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""

  info "This certificate is required for Claude Code and Continue"
  info "to work behind corporate proxy/firewall"
  echo ""

  local cert_path=""

  # Look for cert in common locations
  CERT_PATHS=(
    "$DOTFILES_DIR/certs/$CERT_FILE"
    "$HOME/.continue/certs/$CERT_FILE"
    "$HOME/Downloads/$CERT_FILE"
    "$HOME/Downloads/ClaudeCode-macOS-"*"/$CERT_FILE"
  )

  for path in "${CERT_PATHS[@]}"; do
    # Use glob expansion to handle wildcards
    for expanded_path in $path; do
      if [[ -f "$expanded_path" ]]; then
        cert_path="$expanded_path"
        break 2
      fi
    done
  done

  if [[ -z "$cert_path" ]]; then
    warn "Zscaler certificate not found in common locations"
    echo ""
    info "Searched locations:"
    for path in "${CERT_PATHS[@]}"; do
      echo "  • $path"
    done
    echo ""
    read -rp "  Enter path to ${CERT_FILE} (or press Enter to skip): " user_path

    if [[ -n "$user_path" && -f "$user_path" ]]; then
      cert_path="$user_path"
    else
      info "Skipping certificate installation"
      echo ""
      info "To install later:"
      echo "  1. Obtain ${CERT_FILE} from your IT department"
      echo "  2. Place it in: $DOTFILES_DIR/certs/$CERT_FILE"
      echo "  3. Re-run: bash $DOTFILES_DIR/scripts/install_zscaler_cert.sh"
      return 1
    fi
  else
    success "Found certificate at: $cert_path"
  fi

  # Install to Continue
  if [[ -d "$HOME/.continue/certs" && -f "$HOME/.continue/certs/$CERT_FILE" ]]; then
    info "Certificate already installed in ~/.continue/certs/"
  else
    mkdir -p "$HOME/.continue/certs"
    cp "$cert_path" "$HOME/.continue/certs/$CERT_FILE"
    success "Installed certificate to ~/.continue/certs/"
  fi

  # Copy to dotfiles certs directory if not already there
  if [[ "$cert_path" != "$DOTFILES_DIR/certs/$CERT_FILE" ]]; then
    mkdir -p "$DOTFILES_DIR/certs"
    if [[ ! -f "$DOTFILES_DIR/certs/$CERT_FILE" ]]; then
      cp "$cert_path" "$DOTFILES_DIR/certs/$CERT_FILE"
      info "Copied certificate to dotfiles: $DOTFILES_DIR/certs/"
      info "(This directory is git-ignored for security)"
    fi
  fi

  # Install to system keychain (optional)
  echo ""
  read -rp "  Also install to macOS System Keychain (requires sudo)? [y/N] " install_system
  if [[ "$install_system" =~ ^[Yy]$ ]]; then
    sudo security add-trusted-cert -d -r trustRoot \
      -k /Library/Keychains/System.keychain "$cert_path"
    success "Installed certificate to System Keychain"
    info "Applications will now trust this certificate"
  else
    info "Skipped system keychain installation"
  fi

  # Update NODE_EXTRA_CA_CERTS in shell configs
  echo ""
  local cert_env="export NODE_EXTRA_CA_CERTS=\"\$HOME/.continue/certs/$CERT_FILE\""

  # Check if already in .zshrc.local
  if [[ -f "$HOME/.zshrc.local" ]] && grep -q "NODE_EXTRA_CA_CERTS" "$HOME/.zshrc.local" 2>/dev/null; then
    success "NODE_EXTRA_CA_CERTS already configured in ~/.zshrc.local"
  else
    read -rp "  Add NODE_EXTRA_CA_CERTS to ~/.zshrc.local? [Y/n] " add_env
    if [[ ! "$add_env" =~ ^[Nn]$ ]]; then
      touch "$HOME/.zshrc.local"
      echo "" >> "$HOME/.zshrc.local"
      echo "# Zscaler certificate for Node.js tools (Claude Code, npm, yarn, etc.)" >> "$HOME/.zshrc.local"
      echo "$cert_env" >> "$HOME/.zshrc.local"
      success "Added NODE_EXTRA_CA_CERTS to ~/.zshrc.local"
      info "Restart your shell or run: source ~/.zshrc.local"
    fi
  fi

  echo ""
  echo "╔════════════════════════════════════════════════╗"
  echo "║  Certificate Installation Complete             ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""

  info "Certificate locations:"
  echo "  • Continue: ~/.continue/certs/$CERT_FILE"
  if [[ "$install_system" =~ ^[Yy]$ ]]; then
    echo "  • System: /Library/Keychains/System.keychain"
  fi
  if [[ -f "$DOTFILES_DIR/certs/$CERT_FILE" ]]; then
    echo "  • Dotfiles: $DOTFILES_DIR/certs/$CERT_FILE"
  fi
  echo ""

  info "Next steps:"
  echo "  1. Restart your shell: exec zsh"
  echo "  2. Verify Claude Code can connect: claude --version"
  echo "  3. Test Continue in VS Code"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_zscaler_cert "$@"
fi
