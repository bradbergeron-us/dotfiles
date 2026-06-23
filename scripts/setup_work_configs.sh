#!/usr/bin/env bash
# Setup work-specific configurations from templates
# Part of Phase 2: Installation Scripts

# Note: the ~/… strings in the user-facing messages below are intentional
# display text, not paths meant to expand, so suppress SC2088 file-wide.
# shellcheck disable=SC2088

set -e

# Get the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source helper functions if available
if [[ -f "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh" ]]; then
  source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
else
  # Minimal fallback functions
  info() { echo "ℹ️  $*"; }
  success() { echo "✅ $*"; }
  warn() { echo "⚠️  $*"; }
  error() { echo "❌ $*" >&2; }
fi

# Color codes for output
CYAN='\033[0;36m'
RESET='\033[0m'

setup_maven() {
  echo ""
  info "Setting up Maven configuration..."

  mkdir -p "$HOME/.m2"

  if [[ -f "$HOME/.m2/settings.xml" ]]; then
    warn "~/.m2/settings.xml already exists"
    read -rp "  Overwrite? [y/N] " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      info "Skipped Maven configuration"
      return 0
    fi
    cp "$HOME/.m2/settings.xml" "$HOME/.m2/settings.xml.backup"
    info "Backed up existing settings.xml to settings.xml.backup"
  fi

  if [[ -f "$DOTFILES_DIR/templates/m2/settings.xml.template" ]]; then
    cp "$DOTFILES_DIR/templates/m2/settings.xml.template" "$HOME/.m2/settings.xml"
    success "Created ~/.m2/settings.xml from template"
    info "Review and configure server credentials as needed"
  else
    error "Template not found: $DOTFILES_DIR/templates/m2/settings.xml.template"
    return 1
  fi
}

setup_yarn() {
  echo ""
  info "Setting up Yarn configuration..."

  if [[ -f "$HOME/.yarnrc" ]]; then
    warn "~/.yarnrc already exists"
    read -rp "  Overwrite? [y/N] " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      info "Skipped Yarn configuration"
      return 0
    fi
    cp "$HOME/.yarnrc" "$HOME/.yarnrc.backup"
    info "Backed up existing .yarnrc to .yarnrc.backup"
  fi

  if [[ -f "$DOTFILES_DIR/templates/yarnrc.template" ]]; then
    cp "$DOTFILES_DIR/templates/yarnrc.template" "$HOME/.yarnrc"
    success "Created ~/.yarnrc from template"
    info "Authentication will be handled separately"
  else
    error "Template not found: $DOTFILES_DIR/templates/yarnrc.template"
    return 1
  fi
}

setup_bundle() {
  echo ""
  info "Setting up Bundle (Ruby gems) configuration..."

  mkdir -p "$HOME/.bundle"

  if [[ -f "$HOME/.bundle/config" ]]; then
    warn "~/.bundle/config already exists"
    read -rp "  Overwrite? [y/N] " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      info "Skipped Bundle configuration"
      return 0
    fi
    cp "$HOME/.bundle/config" "$HOME/.bundle/config.backup"
    info "Backed up existing config to config.backup"
  fi

  if [[ -f "$DOTFILES_DIR/templates/bundle/config.template" ]]; then
    cp "$DOTFILES_DIR/templates/bundle/config.template" "$HOME/.bundle/config"
    success "Created ~/.bundle/config from template"
    info "Edit with your JFrog credentials to install private gems"
  else
    error "Template not found: $DOTFILES_DIR/templates/bundle/config.template"
    return 1
  fi
}

setup_continue() {
  echo ""
  info "Setting up Continue IDE configuration..."

  mkdir -p "$HOME/.continue"

  if [[ -f "$HOME/.continue/config.yaml" ]]; then
    warn "~/.continue/config.yaml already exists"
    read -rp "  Overwrite? [y/N] " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      info "Skipped Continue configuration"
      return 0
    fi
    cp "$HOME/.continue/config.yaml" "$HOME/.continue/config.yaml.backup"
    info "Backed up existing config.yaml to config.yaml.backup"

    if [[ -f "$DOTFILES_DIR/templates/continue/config.yaml.template" ]]; then
      cp "$DOTFILES_DIR/templates/continue/config.yaml.template" "$HOME/.continue/config.yaml"
      success "Created ~/.continue/config.yaml from template"
    fi
  else
    if [[ -f "$DOTFILES_DIR/templates/continue/config.yaml.template" ]]; then
      cp "$DOTFILES_DIR/templates/continue/config.yaml.template" "$HOME/.continue/config.yaml"
      success "Created ~/.continue/config.yaml from template"
    else
      error "Template not found: $DOTFILES_DIR/templates/continue/config.yaml.template"
      return 1
    fi
  fi

  # Handle certificate installation
  if [[ -f "$HOME/.continue/certs/ZscalerRootCertificate-2048-SHA256.crt" ]]; then
    success "Zscaler certificate already installed in ~/.continue/certs/"
  else
    info "Zscaler certificate not found"
    info "Run: bash $DOTFILES_DIR/scripts/install_zscaler_cert.sh"
  fi
}

setup_claude() {
  echo ""
  info "Setting up Claude Code configuration..."

  mkdir -p "$HOME/.claude"

  if [[ -f "$HOME/.claude/settings.json" ]]; then
    warn "~/.claude/settings.json already exists"
    read -rp "  Overwrite? [y/N] " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      info "Skipped Claude Code configuration"
      return 0
    fi
    cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup"
    info "Backed up existing settings.json to settings.json.backup"
  fi

  if [[ -f "$DOTFILES_DIR/templates/claude/settings.json.template" ]]; then
    cp "$DOTFILES_DIR/templates/claude/settings.json.template" "$HOME/.claude/settings.json"
    success "Created ~/.claude/settings.json from template"
    info "Review and configure AWS profile as needed"
  else
    error "Template not found: $DOTFILES_DIR/templates/claude/settings.json.template"
    return 1
  fi
}

setup_aws() {
  echo ""
  info "Setting up AWS configuration..."

  mkdir -p "$HOME/.aws"

  if [[ -f "$HOME/.aws/config" ]]; then
    warn "~/.aws/config already exists"
    read -rp "  Overwrite? [y/N] " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      info "Skipped AWS configuration"
      return 0
    fi
    cp "$HOME/.aws/config" "$HOME/.aws/config.backup"
    info "Backed up existing config to config.backup"
  fi

  if [[ -f "$DOTFILES_DIR/templates/aws/config.template" ]]; then
    cp "$DOTFILES_DIR/templates/aws/config.template" "$HOME/.aws/config"
    success "Created ~/.aws/config from template"
    warn "Configure AWS credentials using: aws configure sso"
  else
    error "Template not found: $DOTFILES_DIR/templates/aws/config.template"
    return 1
  fi
}

setup_claude_cli() {
  echo ""
  info "Checking Claude Code CLI installation..."

  if command -v claude &>/dev/null; then
    local version
    version=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    success "Claude Code CLI already installed (version: $version)"
    return 0
  fi

  mkdir -p "$HOME/.local/bin"

  # Check for installer in dotfiles first
  if [[ -f "$DOTFILES_DIR/system/installers/claude-code-installer" ]]; then
    info "Found Claude Code installer in dotfiles"
    read -rp "  Install Claude Code CLI? [Y/n] " install_claude
    if [[ ! "$install_claude" =~ ^[Nn]$ ]]; then
      bash "$DOTFILES_DIR/system/installers/claude-code-installer" --prefix="$HOME/.local"
      success "Claude Code CLI installed"
    fi
  else
    warn "Claude Code installer not found in dotfiles"
    warn "Download from: https://claude.com/download"
    echo ""
    read -rp "  Enter path to installer (or press Enter to skip): " installer_path

    if [[ -n "$installer_path" && -f "$installer_path" ]]; then
      bash "$installer_path" --prefix="$HOME/.local"
      success "Claude Code CLI installed"
    else
      info "Skipping Claude Code CLI installation"
      info "You can install it later by running:"
      printf "  ${CYAN}bash $DOTFILES_DIR/scripts/install_claude_code.sh${RESET}\n"
    fi
  fi
}

setup_jfrog_netrc() {
  echo ""
  info "Setting up JFrog authentication for Go modules..."

  # Check if JFrog CLI is authenticated
  if [[ ! -f "$HOME/.jfrog/jfrog-cli.conf.v6" ]]; then
    warn "JFrog CLI not configured"
    info "Please run: jf login"
    info "Then re-run this script to setup .netrc"
    return 1
  fi

  # Check if .netrc already exists
  if [[ -f "$HOME/.netrc" ]]; then
    # Check if it already has JFrog entry
    if grep -q "machine jfrog.accenturefederaldev.com" "$HOME/.netrc"; then
      success "~/.netrc already configured for JFrog"
      return 0
    fi

    warn "~/.netrc already exists (but no JFrog entry found)"
    read -rp "  Add JFrog credentials to existing .netrc? [Y/n] " add_jfrog
    if [[ "$add_jfrog" =~ ^[Nn]$ ]]; then
      info "Skipped JFrog .netrc configuration"
      return 0
    fi

    cp "$HOME/.netrc" "$HOME/.netrc.backup"
    info "Backed up existing .netrc to .netrc.backup"
  fi

  # Extract credentials from JFrog CLI config
  if command -v jq &>/dev/null; then
    local jfrog_user jfrog_token
    jfrog_user=$(jq -r '.servers[0].user // empty' "$HOME/.jfrog/jfrog-cli.conf.v6" 2>/dev/null)
    jfrog_token=$(jq -r '.servers[0].accessToken // empty' "$HOME/.jfrog/jfrog-cli.conf.v6" 2>/dev/null)

    if [[ -n "$jfrog_user" && -n "$jfrog_token" ]]; then
      # Append or create .netrc with JFrog credentials
      {
        echo ""
        echo "machine jfrog.accenturefederaldev.com"
        echo "login $jfrog_user"
        echo "password $jfrog_token"
      } >> "$HOME/.netrc"

      chmod 600 "$HOME/.netrc"
      success "Created ~/.netrc with JFrog credentials"
      info "Go modules can now authenticate with JFrog Artifactory"
    else
      error "Could not extract JFrog credentials"
      info "Please run: jf login"
      return 1
    fi
  else
    error "jq not installed (required to parse JFrog config)"
    info "Install with: brew install jq"
    return 1
  fi
}

# Main execution
main() {
  echo ""
  echo "╔════════════════════════════════════════════════╗"
  echo "║  Work Configuration Setup                      ║"
  echo "║  Installing work-specific configurations       ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""

  info "Dotfiles directory: $DOTFILES_DIR"
  echo ""

  # Prompt for each configuration
  read -rp "Setup Maven (.m2/settings.xml)? [Y/n] " do_maven
  if [[ ! "$do_maven" =~ ^[Nn]$ ]]; then
    setup_maven
  fi

  read -rp "Setup Yarn (.yarnrc)? [Y/n] " do_yarn
  if [[ ! "$do_yarn" =~ ^[Nn]$ ]]; then
    setup_yarn
  fi

  read -rp "Setup Bundle (.bundle/config for Ruby gems)? [Y/n] " do_bundle
  if [[ ! "$do_bundle" =~ ^[Nn]$ ]]; then
    setup_bundle
  fi

  read -rp "Setup Continue IDE (.continue/config.yaml)? [Y/n] " do_continue
  if [[ ! "$do_continue" =~ ^[Nn]$ ]]; then
    setup_continue
  fi

  read -rp "Setup Claude Code (.claude/settings.json)? [Y/n] " do_claude
  if [[ ! "$do_claude" =~ ^[Nn]$ ]]; then
    setup_claude
  fi

  read -rp "Setup AWS config (.aws/config)? [Y/n] " do_aws
  if [[ ! "$do_aws" =~ ^[Nn]$ ]]; then
    setup_aws
  fi

  read -rp "Install Claude Code CLI? [Y/n] " do_claude_cli
  if [[ ! "$do_claude_cli" =~ ^[Nn]$ ]]; then
    setup_claude_cli
  fi

  read -rp "Setup JFrog authentication (.netrc for Go modules)? [Y/n] " do_jfrog
  if [[ ! "$do_jfrog" =~ ^[Nn]$ ]]; then
    setup_jfrog_netrc
  fi

  echo ""
  echo "╔════════════════════════════════════════════════╗"
  echo "║  Work Configuration Setup Complete             ║"
  echo "╚════════════════════════════════════════════════╝"
  echo ""

  info "Next steps:"
  echo "  1. Review generated configuration files"
  echo "  2. Install certificates: bash $DOTFILES_DIR/scripts/install_zscaler_cert.sh"
  echo "  3. Configure AWS credentials: aws configure sso --profile bedrock"
  echo "  4. If you skipped JFrog setup, authenticate with: jf login"
  echo "  5. Test your setup: bash $DOTFILES_DIR/verify.sh"
  echo ""
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
