#!/usr/bin/env bash
# dryrun_helpers.sh — helper functions for dry-run mode
# Source this file when --dry-run is enabled
# NOTE: DRY_RUN is set by bootstrap.sh before sourcing this file

# Global state for tracking actions
typeset -a DRY_RUN_ACTIONS=()

# Track what would be done
dry_run_log() {
  DRY_RUN_ACTIONS+=("$*")
}

# Override step() for dry-run mode
dry_run_step() {
  local title="$1"
  (( STEP++ )) || true
  echo ""
  printf "${CYAN}${BOLD}  ▸ [%d/%d]  %s${RESET}  ${DIM}(dry-run)${RESET}\n" "$STEP" "$TOTAL_STEPS" "$title"
}

# Check if Xcode CLI tools would be installed
check_xcode() {
  if ! xcode-select -p &>/dev/null; then
    dry_run_log "Install Xcode Command Line Tools"
    info "Would prompt to install Xcode CLI Tools (requires user interaction)"
  else
    success "Xcode CLI Tools already installed — skip"
  fi
}

# Check if Homebrew would be installed
check_homebrew() {
  if ! command -v brew &>/dev/null; then
    dry_run_log "Install Homebrew"
    info "Would install Homebrew from: https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

    # Detect expected installation path
    if [[ "$(uname -m)" == "arm64" ]]; then
      info "Would install to: /opt/homebrew (Apple Silicon)"
    else
      info "Would install to: /usr/local (Intel)"
    fi
  else
    _brew_version=$(brew --version | head -1 | awk '{print $2}')
    success "Homebrew $_brew_version already installed — skip"
  fi
}

# Check what packages would be installed from Brewfile
check_brew_bundle() {
  local brewfile="$1"

  if [[ ! -f "$brewfile" ]]; then
    warn "Brewfile not found: $brewfile"
    return
  fi

  dry_run_log "Run: brew bundle --file=$brewfile"

  if ! command -v brew &>/dev/null; then
    info "Would install packages from Brewfile (Homebrew not yet installed)"
    local entry_count
    entry_count=$(grep -cE "^(brew|cask|tap|mas)" "$brewfile" || echo "0")
    info "Brewfile contains: $entry_count total entries"
    return
  fi

  # Use brew bundle check to see what's missing (faster and more reliable)
  info "Checking Brewfile packages..."

  # Capture brew bundle check output
  local check_output
  check_output=$(brew bundle check --file="$brewfile" 2>&1 || true)

  if echo "$check_output" | grep -q "dependencies are satisfied"; then
    success "All Brewfile packages already installed — skip"
  else
    # Count missing packages from the output
    local missing_count
    missing_count=$(echo "$check_output" | grep -c "needs to be installed" || echo "0")
    if (( missing_count > 0 )); then
      info "Would install: $missing_count package(s)"
    else
      info "Would run brew bundle to sync packages"
    fi
  fi
}

# Check fzf integration
check_fzf() {
  if [[ ! -f "$(brew --prefix 2>/dev/null)/opt/fzf/install" ]]; then
    info "Would skip fzf integration (fzf not installed)"
  else
    # Check if already configured
    if [[ -f "$HOME/.fzf.zsh" ]]; then
      success "fzf integration already configured — skip"
    else
      dry_run_log "Configure fzf shell integration"
      info "Would run: fzf/install --key-bindings --completion --no-update-rc"
    fi
  fi
}

# Check SSH key generation
check_ssh_key() {
  if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    success "SSH key already exists at ~/.ssh/id_ed25519 — skip"
  else
    dry_run_log "Generate SSH key (~/.ssh/id_ed25519)"
    info "Would prompt for passphrase (optional)"
    info "Would add key to macOS Keychain"
    info "Would copy public key to clipboard"
    info "Would prompt to add key to GitHub"
  fi
}

# Check GitHub CLI authentication
check_gh_auth() {
  if ! command -v gh &>/dev/null; then
    info "Would skip GitHub CLI auth (gh not installed)"
  elif gh auth status &>/dev/null; then
    success "GitHub CLI already authenticated — skip"
  else
    dry_run_log "Authenticate GitHub CLI"
    info "Would run: gh auth login (requires user interaction)"
  fi
}

# Check mise runtime installations
check_mise_runtimes() {
  if ! command -v mise &>/dev/null; then
    info "Would skip runtime installation (mise not installed)"
    return
  fi

  # Read the runtime list from config/mise.toml — the single source of truth.
  local _rt
  local -a runtimes=()
  while IFS= read -r _rt; do
    [[ -n "$_rt" ]] && runtimes+=("$_rt")
  done < <(parse_mise_runtimes "$DOTFILES_DIR/config/mise.toml")
  if [[ ${#runtimes[@]} -eq 0 ]]; then
    info "No runtimes declared in config/mise.toml"
    return
  fi

  local installed
  installed=$(mise list 2>/dev/null || echo "")
  local -a missing=()

  for runtime in "${runtimes[@]}"; do
    if echo "$installed" | grep -q "$runtime"; then
      success "$runtime already installed — skip"
    else
      missing+=("$runtime")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    dry_run_log "Install mise runtimes: ${missing[*]}"
    info "Would install ${#missing[@]} runtime(s) (can take 5-10 minutes)"
    for runtime in "${missing[@]}"; do
      info "  - $runtime"
    done
  fi
}

# Check Corepack / yarn enablement (yarn ships with Node via Corepack)
check_corepack() {
  if ! command -v corepack &>/dev/null; then
    info "Would skip Corepack (corepack not found — installed with Node via mise)"
  elif command -v yarn &>/dev/null; then
    success "yarn already available ($(yarn --version 2>/dev/null || echo 'installed')) — skip"
  else
    dry_run_log "Enable Corepack (yarn + pnpm shims)"
    info "Would run: corepack enable"
    info "Would run: corepack prepare yarn@stable --activate"
  fi
}

# Check Rust installation
check_rust() {
  if brew list rust &>/dev/null 2>&1; then
    warn "Homebrew 'rust' formula detected (conflicts with rustup)"
    info "Would recommend uninstalling: brew uninstall rust"
  fi

  if ! command -v rustup &>/dev/null; then
    if command -v rustup-init &>/dev/null; then
      dry_run_log "Initialize Rust via rustup"
      info "Would run: rustup-init -y --no-modify-path"
      info "Would install: stable toolchain + rustfmt + clippy"
    else
      info "Would skip Rust (rustup not installed)"
    fi
  else
    local rust_version
    rust_version=$(rustc --version 2>/dev/null | awk '{print $2}' || true)
    success "rustup already installed (rustc $rust_version) — skip"
  fi
}

# Check git-lfs
check_git_lfs() {
  if ! command -v git-lfs &>/dev/null; then
    info "Would skip git-lfs configuration (not installed)"
  else
    dry_run_log "Configure git-lfs"
    info "Would run: git lfs install --skip-repo"
  fi
}

# Check dotfile symlinks
check_dotfile_symlinks() {
  dry_run_log "Run: install.sh (symlink dotfiles)"

  local -a files=(
    "$HOME/.zshrc:zshrc"
    "$HOME/.zprofile:zprofile"
    "$HOME/.gitconfig:gitconfig"
    "$HOME/.tmux.conf:tmux.conf"
    "$HOME/.hyper.js:hyper.js"
    "$HOME/.gitignore_global:gitignore_global"
    "$HOME/.gemrc:gemrc"
    "$HOME/.irbrc:irbrc"
    "$HOME/.pryrc:pryrc"
    "$HOME/.psqlrc:psqlrc"
    "$HOME/.npmrc:npmrc"
    "$HOME/.editorconfig:editorconfig"
    "$HOME/.config/starship.toml:config/starship.toml"
    "$HOME/.config/direnv/direnvrc:config/direnvrc"
    "$HOME/.config/mise/config.toml:config/mise.toml"
    "$HOME/.ssh/config:ssh_config"
  )

  local to_link=0
  local already_linked=0
  local to_backup=0

  for entry in "${files[@]}"; do
    local dest="${entry%%:*}"
    local src_rel="${entry##*:}"
    local src="$DOTFILES_DIR/$src_rel"

    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
      (( already_linked++ )) || true
    elif [[ -e "$dest" ]]; then
      (( to_backup++ )) || true
      (( to_link++ )) || true
    else
      (( to_link++ )) || true
    fi
  done

  info "Would symlink: $to_link file(s)"
  if (( to_backup > 0 )); then
    info "Would backup: $to_backup existing file(s) to ~/.dotfiles_backup/"
  fi
  info "Already linked: $already_linked file(s)"

  # Check local configs
  if [[ ! -f "$HOME/.zshrc.local" ]]; then
    dry_run_log "Create ~/.zshrc.local from template"
    info "Would create: ~/.zshrc.local (machine-specific config)"
  fi

  if [[ ! -f "$HOME/.config/git/local.gitconfig" ]]; then
    dry_run_log "Create ~/.config/git/local.gitconfig from template"
    info "Would create: ~/.config/git/local.gitconfig (git signing key)"
  fi
}

# Check work configs
check_work_configs() {
  if [[ -f "$DOTFILES_DIR/scripts/setup_work_configs.sh" ]]; then
    info "Would prompt to run work configuration setup (optional)"
    info "  Sets up: .m2, .yarnrc, .continue, .claude, .aws"
  fi
}

# Check macOS defaults
check_macos_defaults() {
  info "Would prompt to apply macOS developer defaults (optional)"
  info "  Includes: keyboard, trackpad, Finder, Dock, screenshots"
}

# Show dry-run summary
show_dry_run_summary() {
  echo ""
  echo "  ═════════════════════════════════════════════════"
  printf "${BOLD}  📋  Dry-Run Summary${RESET}  —  %d actions planned\n" "${#DRY_RUN_ACTIONS[@]}"
  echo "  ═════════════════════════════════════════════════"

  if (( ${#DRY_RUN_ACTIONS[@]} == 0 )); then
    echo ""
    success "No actions needed — system is already bootstrapped"
  else
    echo ""
    local i=1
    for action in "${DRY_RUN_ACTIONS[@]}"; do
      printf "  ${DIM}%2d.${RESET} %s\n" "$i" "$action"
      (( i++ ))
    done
  fi

  echo ""
  echo "  ─────────────────────────────────────────────────"
  info "To actually run bootstrap: bash ~/dotfiles/bootstrap.sh"
  echo ""
}
