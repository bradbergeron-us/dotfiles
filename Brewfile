# Brewfile — declarative Homebrew packages
# Install everything: brew bundle
# Install and upgrade: brew bundle --upgrade
# Check what's missing: brew bundle check

# ------------------
# Shell & prompt
# ------------------
brew "starship"       # cross-shell prompt
brew "zoxide"         # smart cd with frecency ranking
brew "fzf"            # fuzzy finder (Ctrl+R history, Ctrl+T file picker)

# ------------------
# File & search
# ------------------
brew "bat"            # cat with syntax highlighting
brew "ripgrep"        # faster grep (rg)
brew "fd"             # faster find

# ------------------
# Git
# ------------------
brew "git-lfs"        # large file storage
brew "git-delta"      # syntax-highlighted diffs
brew "lazygit"        # terminal UI for git
brew "gh"             # GitHub CLI

# ------------------
# Runtime management
# ------------------
brew "mise"           # polyglot version manager (Ruby, Node, Python, etc.)
brew "openssl@3"      # required for building Ruby via mise
brew "maven"          # Java build tool — required for Maven projects
brew "uv"             # fast Python package and project manager (replaces pip + virtualenv)

# ------------------
# Terminal multiplexer
# ------------------
brew "tmux"

# ------------------
# Data & utilities
# ------------------
brew "jq"             # JSON processor
brew "shellcheck"     # shell script linter
brew "tree"           # directory tree view
brew "pre-commit"     # git hook framework (per-project, runs on commit)
brew "tldr"           # simplified man pages (community-maintained examples)
brew "httpie"         # human-friendly HTTP client (replaces curl for interactive use)
brew "watch"          # re-run a command on an interval (e.g. watch kubectl get pods)
brew "direnv"         # per-directory environment variables via .envrc files
brew "newman"             # CLI runner for Insomnia/Postman collections (useful in CI)

# ------------------
# Fonts
# ------------------
cask "font-fira-code"                  # Fira Code (editor font with ligatures)
cask "font-jetbrains-mono-nerd-font"   # JetBrains Mono with Nerd Font icons (terminal font)

# ------------------
# Apps (casks)
# ------------------
cask "insomnia"            # GUI REST/GraphQL client — API design, collections, team sharing
cask "raycast"             # launcher, clipboard history, window management
cask "visual-studio-code"  # editor
cask "postgres-app"        # Postgres.app — PostgreSQL with a macOS GUI
cask "dbeaver-community"   # universal database GUI (Postgres, MySQL, SQLite, etc.)
cask "orbstack"            # fast, lightweight Docker Desktop replacement + Linux VMs
