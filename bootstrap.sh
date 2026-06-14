#!/usr/bin/env bash
# bootstrap.sh — install all dependencies and symlink dotfiles on a fresh Mac
# Usage: bash bootstrap.sh [--dry-run] [--skip-preflight]

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOTSTRAP_START=$SECONDS
# shellcheck disable=SC2034  # used by step() in helpers
STEP=0
# shellcheck disable=SC2034
TOTAL_STEPS=13

# Parse arguments
export DRY_RUN=false
export SKIP_PREFLIGHT=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      export DRY_RUN=true
      ;;
    --skip-preflight)
      export SKIP_PREFLIGHT=true
      ;;
    --help|-h)
      echo "Usage: bash bootstrap.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --dry-run         Show what would be done without actually doing it"
      echo "  --skip-preflight  Skip pre-flight system checks"
      echo "  --help, -h        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# shellcheck source=scripts/bootstrap_helpers.sh
source "$(dirname "$0")/scripts/bootstrap_helpers.sh"
setup_colors

# Source dry-run helpers if needed
if [[ "$DRY_RUN" == true ]]; then
  # shellcheck source=scripts/dryrun_helpers.sh
  source "$(dirname "$0")/scripts/dryrun_helpers.sh"
fi

# ── Startup banner ───────────────────────────────────────────────────────────
echo ""
if [[ "$DRY_RUN" == true ]]; then
  printf "%s  🚀  dotfiles bootstrap%s  —  %sDRY-RUN MODE%s\n" "$BOLD" "$RESET" "$CYAN" "$RESET"
else
  printf "%s  🚀  dotfiles bootstrap%s  —  macOS developer setup\n" "$BOLD" "$RESET"
fi
echo "  ─────────────────────────────────────────────────"
printf "  ${DIM}Machine${RESET}  %s\n" "$(scutil --get ComputerName 2>/dev/null || hostname)"
printf "  ${DIM}Date${RESET}     %s\n" "$(date '+%a %b %d %Y  %H:%M')"
echo "  ─────────────────────────────────────────────────"

# ── Pre-flight check ─────────────────────────────────────────────────────────
if [[ "$SKIP_PREFLIGHT" == false ]] && [[ "$DRY_RUN" == false ]]; then
  if [[ -f "$DOTFILES_DIR/scripts/preflight.sh" ]]; then
    bash "$DOTFILES_DIR/scripts/preflight.sh"
    _preflight_exit=$?

    if (( _preflight_exit == 1 )); then
      echo ""
      error "Pre-flight check failed — fix critical errors before bootstrapping"
      echo ""
      info "To skip pre-flight checks (not recommended): bash bootstrap.sh --skip-preflight"
      exit 1
    elif (( _preflight_exit == 2 )); then
      echo ""
      warn "Pre-flight check found warnings — bootstrap can continue"
      read -t 10 -rp "  Continue anyway? [Y/n] (auto-yes in 10s) " continue_with_warnings || continue_with_warnings="y"
      if [[ "$continue_with_warnings" =~ ^[Nn]$ ]]; then
        info "Bootstrap cancelled — fix warnings and re-run"
        exit 0
      fi
    fi
    echo ""
  fi
fi

# ── Steps ─────────────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "🛠️  Xcode Command Line Tools"
  check_xcode
else
  step "🛠️  Xcode Command Line Tools"
  if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo ""
    warn "Re-run this script after the Xcode tools finish installing."
    exit 0
  fi
  success "Xcode CLI Tools"
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "🍺  Homebrew"
  check_homebrew
else
  step "🍺  Homebrew"
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for the rest of this script
    [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -f /usr/local/bin/brew ]]    && eval "$(/usr/local/bin/brew shellenv)"
  fi
  success "Homebrew $(brew --version | head -1)"
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "📦  Packages (brew bundle)"
  check_brew_bundle "$DOTFILES_DIR/Brewfile"
else
  step "📦  Packages (brew bundle)"
  # Clean up any stale lock files
  info "Preparing package installation..."
  rm -f "$DOTFILES_DIR/Brewfile.lock.json" 2>/dev/null || true

  # Temporarily disable ALL error handling for brew bundle
  # This ensures the script ALWAYS continues to the next step
  info "Installing Homebrew packages (will adopt any existing GUI apps)..."
  (
    set +e
    HOMEBREW_CASK_OPTS="--adopt" brew bundle --verbose --no-upgrade --file="$DOTFILES_DIR/Brewfile"
    exit 0  # Force success exit code
  ) || true
  _brew_exit_code=$?

  # Always report success and continue
  if [[ $_brew_exit_code -eq 0 ]]; then
    success "Brew packages installed"
  else
    warn "Some Brew packages may have failed — continuing with setup anyway"
    warn "Run 'brew bundle --verbose' manually later to retry any failed packages"
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "🔍  fzf shell integration"
  check_fzf
else
  step "🔍  fzf shell integration"
  if [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
    info "Setting up fzf shell integration..."
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    success "fzf configured"
  else
    warn "fzf not installed — skipping shell integration (install it later with: brew install fzf)"
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "🔑  SSH key for commit signing"
  check_ssh_key
else
  step "🔑  SSH key for commit signing"
  echo ""
  printf "${DIM}  Every commit will be signed with your SSH key. GitHub shows a\n"
  printf "  'Verified' badge proving it actually came from you.${RESET}\n"
  echo ""

  if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    success "SSH key already exists at ~/.ssh/id_ed25519 — skipping generation"
  else
    printf "  No SSH key found — a new Ed25519 key will be generated now.\n"
    echo ""
    printf "  Passphrase recommendations:\n"
    printf "  • Setting one is more secure (recommended)\n"
    printf "  • macOS Keychain remembers it after first use\n"
    printf "  • Press Enter twice to skip (less secure but simpler)\n"
    echo ""
    read -rp "  Press Enter to generate your SSH key... "

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    # Use configured email, or prompt if not yet set (gitconfig is symlinked later at step 12)
    _key_email="$(git config user.email 2>/dev/null || true)"
    if [[ -z "$_key_email" ]]; then
      echo ""
      read -rp "  Enter your email for the SSH key (used as key comment): " _key_email
    fi

    ssh-keygen -t ed25519 -C "$_key_email" -f "$HOME/.ssh/id_ed25519"
    ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"

    # Register key for local signature verification
    mkdir -p "$HOME/.config/git"
    echo "$_key_email $(cat "$HOME/.ssh/id_ed25519.pub")" > "$HOME/.config/git/allowed_signers"
    unset _key_email

    # Copy to clipboard automatically
    pbcopy < "$HOME/.ssh/id_ed25519.pub"

    echo ""
    printf "${BOLD}  Action required: add your key to GitHub${RESET}\n"
    echo ""
    printf "  Your public key is ${GREEN}already on your clipboard${RESET}. Go to:\n"
    printf "  ${CYAN}  https://github.com/settings/ssh/new${RESET}\n"
    echo ""
    printf "  Title:    e.g. 'MacBook Pro — commit signing'\n"
    printf "  Key type: ${BOLD}Signing Key${RESET}  ← not Authentication Key\n"
    printf "  Key:      paste from clipboard\n"
    echo ""
    printf "  Your public key (also on clipboard):\n"
    echo ""
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    read -rp "  Press Enter once you've added the key to GitHub to continue... "
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "🐙  GitHub CLI authentication"
  check_gh_auth
else
  step "🐙  GitHub CLI authentication"
  if command -v gh &>/dev/null; then
    if ! gh auth status &>/dev/null; then
      echo ""
      printf "  ${DIM}gh is installed but not authenticated. You'll need this for\n"
      printf "  creating PRs, managing issues, and interacting with GitHub.${RESET}\n"
      echo ""
      gh auth login
    else
      success "GitHub CLI already authenticated"
    fi
  else
    warn "GitHub CLI (gh) not installed — skipping authentication (install it later with: brew install gh)"
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "⚡  Runtimes via mise  (Ruby · Node · Java · Python · Go)"
  check_mise_runtimes
elif command -v mise &>/dev/null; then
  step "⚡  Runtimes via mise  (Ruby · Node · Java · Python · Go)"
  # Check what's already installed
  _installed=$(mise list 2>/dev/null || echo "")

  # Define runtimes to install
  declare -a runtimes=("ruby@3.3.6" "node@22" "java@temurin-21" "python@3.12" "go@1.24")
  declare -a to_install=()

  # Check which runtimes need installation
  for runtime in "${runtimes[@]}"; do
    if echo "$_installed" | grep -q "$runtime"; then
      success "$runtime already installed"
    else
      to_install+=("$runtime")
    fi
  done

  # If nothing to install, skip the prompt
  if [[ ${#to_install[@]} -eq 0 ]]; then
    mise use --global ruby@3.3.6 node@22 java@temurin-21 python@3.12 go@1.24 2>/dev/null || true
    success "All runtimes already configured: Ruby 3.3.6 · Node 22 · Java 21 · Python 3.12 · Go 1.24"
  else
    echo ""
    printf "  ${DIM}Installing ${#to_install[@]} runtime(s) can take 5-10 minutes (compiling from source).${RESET}\n"
    echo ""
    read -t 10 -rp "  Install missing runtimes now? [Y/n] (auto-yes in 10s) " install_runtimes || install_runtimes="y"
    if [[ "$install_runtimes" =~ ^[Nn]$ ]]; then
      info "Skipped. Install later with: mise install"
    else
      # Install only missing runtimes with progress feedback
      declare -i total=${#to_install[@]}
      declare -i current=0

      # Disable exit-on-error for runtime installations
      set +e

      for runtime in "${to_install[@]}"; do
        (( current++ ))
        percentage=$(( current * 100 / total ))
        echo ""
        printf "${CYAN}  → [$current/$total - ${percentage}%%] Installing $runtime...${RESET}\n"
        echo ""
        # Show full output so user can see progress
        if mise install "$runtime" 2>&1; then
          printf "${GREEN}  ✓ [$current/$total - ${percentage}%%] $runtime installed${RESET}\n"
        else
          warn "Failed to install $runtime (continuing anyway)"
        fi
      done

      # Re-enable exit-on-error
      set -e

      mise use --global ruby@3.3.6 node@22 java@temurin-21 python@3.12 go@1.24 2>/dev/null || true
      success "Runtime installation complete (some may have failed - check above)"
    fi
  fi
else
  step "⚡  Runtimes via mise  (Ruby · Node · Java · Python · Go)"
  warn "mise not installed — skipping runtime installation (install it later with: brew install mise)"
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "🦀  Rust (rustup)"
  check_rust
else
  step "🦀  Rust (rustup)"
  # Note: we check for `rustup`, NOT `rustc` — a system/Homebrew rustc does not
  # give you toolchain management (stable/nightly/components). rustup does.
  # If `brew install rust` (the static formula) is present alongside rustup,
  # remove it to avoid PATH conflicts: brew uninstall rust
  if brew list rust &>/dev/null 2>&1; then
    warn "'brew install rust' (static formula) detected — it conflicts with rustup."
    warn "Remove it to avoid PATH confusion: brew uninstall rust"
    warn "rustup (installed via Brewfile) manages the Rust toolchain from here."
  fi
  if ! command -v rustup &>/dev/null; then
    if command -v rustup-init &>/dev/null; then
      info "Initializing Rust toolchain via rustup..."
      # --no-modify-path: zshrc sources ~/.cargo/env directly
      rustup-init -y --no-modify-path
      # shellcheck source=/dev/null
      . "$HOME/.cargo/env"
      rustup component add rustfmt clippy
      success "Rust installed via rustup (stable + rustfmt + clippy)"
    else
      warn "rustup-init not found — skipping Rust installation (install it later with: brew install rustup)"
    fi
  else
    success "rustup already installed: $(rustc --version 2>/dev/null || echo 'rustc not yet in PATH')"
  fi
fi

# NVM migration check (conditional — runs only if ~/.nvm exists)
if [[ "$DRY_RUN" == false ]]; then
  _nvm_dir="${NVM_DIR:-$HOME/.nvm}"
  [[ -d "$_nvm_dir" ]] && info "NVM detected — checking migration status..."
  if [[ -d "$_nvm_dir" ]]; then
    _nvm_count=$(find "$_nvm_dir/versions/node/" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') || _nvm_count=0
    if [[ "${_nvm_count:-0}" -eq 0 ]]; then
      echo ""
      warn "NVM is installed at $_nvm_dir but has no Node versions (ghost install)."
      warn "mise handles Node — NVM is no longer needed on this machine."
      read -rp "  Remove NVM automatically? [y/N] " _rm_nvm
      if [[ "$_rm_nvm" =~ ^[Yy]$ ]]; then
        rm -rf "$_nvm_dir"
        brew uninstall nvm 2>/dev/null || true
        unset NVM_DIR
        success "NVM removed — mise manages Node from here"
      else
        warn "Keeping NVM. The zshrc NVM guard will silence it since no versions are installed."
        unset _rm_nvm
      fi
    else
      echo ""
      warn "NVM has $_nvm_count Node version(s) installed. Recommended migration path:"
      warn "  1. For each Node version you use, run: mise use --global node@<version>"
      warn "  2. Test your projects with mise-managed Node"
      warn "  3. Once satisfied: brew uninstall nvm && rm -rf ~/.nvm"
      warn "Continuing without touching NVM — both mise and NVM can coexist during migration."
    fi
  fi
  unset _nvm_dir _nvm_count _rm_nvm
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "🖥️  tmux plugin manager (TPM)"
  info "Would skip TPM installation (install manually in tmux if needed)"
else
  step "🖥️  tmux plugin manager (TPM)"
  info "tmux plugins can be installed later inside tmux (Ctrl+B then Shift+I)"
  success "Skipping TPM installation during bootstrap - install manually if needed"
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "📁  git-lfs"
  check_git_lfs
else
  step "📁  git-lfs"
  if command -v git-lfs &>/dev/null; then
    git lfs install --skip-repo
    success "git-lfs configured (large file pointer tracking enabled globally)"
  else
    warn "git-lfs not installed — skipping configuration (install it later with: brew install git-lfs)"
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "🔗  Dotfile symlinks"
  check_dotfile_symlinks
else
  step "🔗  Dotfile symlinks"
  zsh "$DOTFILES_DIR/install.sh"
fi

if [[ "$DRY_RUN" == false ]]; then
  if [[ ! -f "$HOME/.zshrc.local" ]]; then
    cp "$DOTFILES_DIR/home/examples/zshrc.local.example" "$HOME/.zshrc.local"
    warn "Created ~/.zshrc.local from template — edit it with machine-specific config"
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "🏢  Work-specific configurations"
  check_work_configs
else
  step "🏢  Work-specific configurations"
  if [[ -f "$DOTFILES_DIR/scripts/setup_work_configs.sh" ]]; then
    echo ""
    printf "  Setup work configs (.m2, .yarnrc, .continue, .claude, .aws)?\n"
    echo ""
    read -rp "  Run work configuration setup? [y/N] " setup_work
    if [[ "$setup_work" =~ ^[Yy]$ ]]; then
      bash "$DOTFILES_DIR/scripts/setup_work_configs.sh"
      success "Work configurations installed"
    else
      info "Skipped. Run manually: bash ~/dotfiles/scripts/setup_work_configs.sh"
    fi
  else
    info "No work-specific configuration script found"
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  dry_run_step "⚙️  macOS developer defaults"
  check_macos_defaults
else
  step "⚙️  macOS developer defaults"
  echo ""
  printf "  Will apply:\n"
  printf "  • Keyboard   — fast key repeat, disable autocorrect & smart quotes\n"
  printf "  • Trackpad   — enable tap-to-click\n"
  printf "  • Finder     — show hidden files & all extensions, path bar, list view\n"
  printf "  • Dock       — auto-hide, instant animation, no recent apps\n"
  printf "  • Screenshots → ~/Desktop/screenshots/ (PNG, no shadow)\n"
  printf "  • TextEdit   — plain text mode by default\n"
  printf "  • Mission Control — faster animation, don't rearrange Spaces\n"
  echo ""
  read -rp "  Apply these settings? [y/N] " apply_macos
  if [[ "$apply_macos" =~ ^[Yy]$ ]]; then
    bash "$DOTFILES_DIR/macos.sh"
    success "macOS defaults applied — Finder and Dock restarted automatically"
    warn "Key repeat and trackpad changes take full effect after logout"
  else
    info "Skipped. Run manually any time: bash ~/dotfiles/macos.sh"
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  show_dry_run_summary
else
  _elapsed=$(( SECONDS - BOOTSTRAP_START ))
  _mins=$(( _elapsed / 60 ))
  _secs=$(( _elapsed % 60 ))

  echo ""
  echo "  ─────────────────────────────────────────────────"
  printf "${GREEN}${BOLD}  🎉  Bootstrap complete${RESET}  in %dm %ds\n" "$_mins" "$_secs"
  echo "  ─────────────────────────────────────────────────"
  echo ""
  printf "  ${BOLD}Next steps${RESET}\n"
  printf "  1. Edit ${CYAN}~/.zshrc.local${RESET} with machine-specific config\n"
  printf "  2. Open a new terminal  (or: ${CYAN}source ~/.zshrc${RESET})\n"
  printf "  3. Keep everything current: ${CYAN}bash ~/dotfiles/update.sh${RESET}\n"
  echo ""
fi
