#!/usr/bin/env bash
# preflight.sh — validate system requirements before bootstrap
# Usage: bash scripts/preflight.sh [--strict]
#
# Exit codes:
#   0 = all checks passed
#   1 = critical failures (--strict mode or blocking issues)
#   2 = warnings only (non-blocking)

set -euo pipefail

# Colors
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
CYAN="\033[36m"

STRICT_MODE=false
[[ "${1:-}" == "--strict" ]] && STRICT_MODE=true

typeset -i ERRORS=0
typeset -i WARNINGS=0

error()   { printf "${RED}  ✗ %s${RESET}\n" "$*"; (( ERRORS++ )) || true; }
warn()    { printf "${YELLOW}  ⚠ %s${RESET}\n" "$*"; (( WARNINGS++ )) || true; }
success() { printf "${GREEN}  ✓ %s${RESET}\n" "$*"; }
info()    { printf "${CYAN}  → %s${RESET}\n" "$*"; }

echo ""
printf "${BOLD}  🔍  Pre-flight Check${RESET}  —  validating system requirements\n"
echo "  ─────────────────────────────────────────────────"

# ── 1. Operating System ──────────────────────────────────────────────────────
info "Checking operating system..."
if [[ "$(uname -s)" != "Darwin" ]]; then
  error "Not running on macOS (found: $(uname -s))"
  error "These dotfiles are designed for macOS only"
else
  _macos_version=$(sw_vers -productVersion)
  _macos_major=$(echo "$_macos_version" | cut -d. -f1)

  if (( _macos_major < 12 )); then
    warn "macOS $_macos_version is older than Monterey (12.0)"
    warn "Some tools may not work correctly"
  else
    success "macOS $_macos_version"
  fi
fi

# ── 2. Architecture ──────────────────────────────────────────────────────────
info "Checking CPU architecture..."
_arch=$(uname -m)
if [[ "$_arch" == "arm64" ]]; then
  success "Apple Silicon (arm64)"

  # Check for Rosetta 2 (needed for some x86_64 tools)
  if /usr/bin/pgrep -q oahd; then
    success "Rosetta 2 is installed"
  else
    warn "Rosetta 2 not detected"
    warn "Some x86_64-only tools may require it"
    info "Install with: softwareupdate --install-rosetta --agree-to-license"
  fi
elif [[ "$_arch" == "x86_64" ]]; then
  success "Intel (x86_64)"
else
  warn "Unknown architecture: $_arch"
fi

# ── 3. Disk Space ────────────────────────────────────────────────────────────
info "Checking available disk space..."
_available=$(df -g / | awk 'NR==2 {print $4}')
if (( _available < 5 )); then
  error "Low disk space: ${_available}GB available (need 5GB+ for bootstrap)"
elif (( _available < 10 )); then
  warn "Disk space is tight: ${_available}GB available (10GB+ recommended)"
else
  success "${_available}GB available"
fi

# ── 4. Internet Connectivity ─────────────────────────────────────────────────
info "Checking internet connectivity..."
if ping -c 1 -t 2 github.com &>/dev/null || ping -c 1 -t 2 8.8.8.8 &>/dev/null; then
  success "Internet connection active"
else
  error "No internet connection detected"
  error "Bootstrap requires internet access to download packages"
fi

# ── 5. Xcode Command Line Tools ──────────────────────────────────────────────
info "Checking Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
  _xcode_path=$(xcode-select -p)
  success "Xcode CLI Tools installed at $_xcode_path"
else
  warn "Xcode CLI Tools not installed"
  info "Bootstrap will prompt to install them"
fi

# ── 6. Conflicting Package Managers ──────────────────────────────────────────
info "Checking for conflicting package managers..."
_conflicts=0

if [[ -f "/opt/local/bin/port" ]] || [[ -d "/opt/local" ]]; then
  warn "MacPorts detected at /opt/local"
  warn "MacPorts conflicts with Homebrew — recommend uninstalling"
  info "Uninstall guide: https://guide.macports.org/#installing.macports.uninstalling"
  (( _conflicts++ ))
fi

if [[ -d "/sw" ]] || command -v fink &>/dev/null; then
  warn "Fink detected at /sw"
  warn "Fink conflicts with Homebrew — recommend uninstalling"
  (( _conflicts++ ))
fi

if (( _conflicts == 0 )); then
  success "No conflicting package managers"
fi

# ── 7. Existing Homebrew ─────────────────────────────────────────────────────
info "Checking Homebrew installation..."
if command -v brew &>/dev/null; then
  _brew_prefix=$(brew --prefix)
  _brew_version=$(brew --version | head -1)

  # Check if Homebrew is in the correct location for the architecture
  if [[ "$_arch" == "arm64" ]] && [[ "$_brew_prefix" != "/opt/homebrew" ]]; then
    warn "Homebrew at $_brew_prefix (expected /opt/homebrew for Apple Silicon)"
    warn "Consider reinstalling Homebrew in the correct location"
  elif [[ "$_arch" == "x86_64" ]] && [[ "$_brew_prefix" != "/usr/local" ]]; then
    warn "Homebrew at $_brew_prefix (expected /usr/local for Intel)"
  else
    success "$_brew_version at $_brew_prefix"
  fi
else
  info "Homebrew not installed (bootstrap will install it)"
fi

# ── 8. Shell Environment ─────────────────────────────────────────────────────
info "Checking shell environment..."
if [[ "$SHELL" == */zsh ]]; then
  success "Default shell: zsh"
elif [[ "$SHELL" == */bash ]]; then
  warn "Default shell is bash (these dotfiles are optimized for zsh)"
  info "Change shell with: chsh -s $(which zsh)"
else
  warn "Unknown shell: $SHELL"
fi

# ── 9. Write Permissions ─────────────────────────────────────────────────────
info "Checking write permissions..."
_perm_errors=0

if [[ ! -w "$HOME" ]]; then
  error "Cannot write to home directory: $HOME"
  (( _perm_errors++ ))
fi

# Check if we can create directories in common locations
for _dir in "$HOME/.config" "$HOME/.ssh" "$HOME/Library"; do
  if [[ ! -d "$_dir" ]] && ! mkdir -p "$_dir" 2>/dev/null; then
    error "Cannot create directory: $_dir"
    (( _perm_errors++ ))
  elif [[ -d "$_dir" ]] && [[ ! -w "$_dir" ]]; then
    error "Cannot write to directory: $_dir"
    (( _perm_errors++ ))
  fi
done

if (( _perm_errors == 0 )); then
  success "Write permissions OK"
fi

# ── 10. System Integrity Protection ──────────────────────────────────────────
info "Checking System Integrity Protection..."
if command -v csrutil &>/dev/null; then
  _sip_status=$(csrutil status 2>/dev/null | grep -o 'enabled\|disabled' || echo "unknown")
  if [[ "$_sip_status" == "enabled" ]]; then
    success "SIP is enabled (recommended)"
  elif [[ "$_sip_status" == "disabled" ]]; then
    warn "SIP is disabled (not recommended unless intentional)"
  else
    info "SIP status: $_sip_status"
  fi
fi

# ── 11. Existing Dotfiles ────────────────────────────────────────────────────
info "Checking for existing dotfiles..."
_existing_count=0
_important_files=(".zshrc" ".zprofile" ".gitconfig" ".tmux.conf")

for _file in "${_important_files[@]}"; do
  if [[ -f "$HOME/$_file" ]] && [[ ! -L "$HOME/$_file" ]]; then
    warn "Existing $_file found (will be backed up during bootstrap)"
    (( _existing_count++ ))
  fi
done

if (( _existing_count == 0 )); then
  success "No conflicting dotfiles"
else
  info "Bootstrap will back up $_existing_count existing file(s) to ~/.dotfiles_backup/"
fi

# ── 12. Git Configuration ────────────────────────────────────────────────────
info "Checking Git configuration..."
if command -v git &>/dev/null; then
  _git_name=$(git config --global user.name 2>/dev/null || echo "")
  _git_email=$(git config --global user.email 2>/dev/null || echo "")

  if [[ -z "$_git_name" ]] || [[ -z "$_git_email" ]]; then
    warn "Git user.name or user.email not configured"
    info "Set with: git config --global user.name 'Your Name'"
    info "         git config --global user.email 'you@example.com'"
  else
    success "Git configured as: $_git_name <$_git_email>"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────────"

if (( ERRORS == 0 )) && (( WARNINGS == 0 )); then
  printf "${GREEN}${BOLD}  ✓ All checks passed${RESET}  —  ready to bootstrap\n"
  exit 0
elif (( ERRORS > 0 )); then
  printf "${RED}${BOLD}  ✗ %d error(s)${RESET}  ·  ${YELLOW}%d warning(s)${RESET}\n" "$ERRORS" "$WARNINGS"
  echo ""
  error "Critical issues detected — fix errors before running bootstrap"
  echo ""
  exit 1
else
  printf "${YELLOW}${BOLD}  ⚠ %d warning(s)${RESET}  —  bootstrap can proceed\n" "$WARNINGS"
  echo ""

  if [[ "$STRICT_MODE" == true ]]; then
    warn "Running in strict mode — warnings treated as errors"
    exit 1
  fi

  exit 2
fi
