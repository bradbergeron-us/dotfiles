# Brewfile — core CLI packages (Homebrew formulae) for ALL profiles.
#
# Profiles layer GUI/app packages on top (see scripts/lib/profile_helpers.sh):
#   Brewfile.personal — GUI casks, fonts, apps (personal, work)
#   Brewfile.work     — work-only additions (work)
# bootstrap.sh installs this core file plus the active profile's overlays;
# `minimal`/`server` get core only. Keep GUI/cask entries OUT of this file.
#
# Install core: brew bundle --file=Brewfile   (check: brew bundle check)

# ------------------
# Shell & prompt
# ------------------
brew "starship"       # cross-shell prompt
brew "zoxide"         # smart cd with frecency ranking
brew "fzf"            # fuzzy finder (Ctrl+R history, Ctrl+T file picker)
brew "sheldon"        # fast, declarative zsh plugin manager (config: config/sheldon/plugins.toml)

# ------------------
# File & search
# ------------------
brew "bat"            # cat with syntax highlighting
brew "ripgrep"        # faster grep (rg)
brew "fd"             # faster find
brew "lsd"            # ls with icons, colors, and Git status (Rust binary; replaces colorls)

# ------------------
# Git
# ------------------
brew "git-lfs"                 # large file storage
brew "git-delta"               # syntax-highlighted diffs
brew "lazygit"                 # terminal UI for git
brew "gh"                      # GitHub CLI
brew "gnupg"                   # GPG for signing commits

# ------------------
# Runtime management
# ------------------
brew "mise"           # polyglot version manager (Ruby, Node, Python, Java, Go)
brew "openssl@3"      # required for building Ruby via mise
brew "maven"          # Java build tool — required for Maven projects
brew "uv"             # fast Python package and project manager (replaces pip + virtualenv)
brew "rustup"         # Rust toolchain manager — bootstrap.sh installs the stable toolchain
brew "ruff"           # extremely fast Python linter and formatter (from Astral, same team as uv)

# ------------------
# Editor
# ------------------
brew "neovim"         # terminal editor — dependency-free baseline config in config/nvim/init.lua

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
brew "gitleaks"       # secret scanning — used by the pre-commit hook and CI secret-scan job
brew "tldr"           # simplified man pages (community-maintained examples)
brew "httpie"         # human-friendly HTTP client (replaces curl for interactive use)
brew "watch"          # re-run a command on an interval (e.g. watch kubectl get pods)
brew "direnv"         # per-directory environment variables via .envrc files
brew "newman"         # CLI runner for Insomnia/Postman collections (useful in CI)
brew "redis"          # in-memory data store — background jobs (Sidekiq), caching, sessions
brew "imagemagick"    # image conversion and manipulation (resize, crop, format conversion)
brew "pdftk-java"    # PDF toolkit — merge, split, fill forms, extract pages

# ------------------
# Secrets management
# ------------------
brew "sops"           # encrypt/decrypt structured files in git (see scripts/secrets.sh, docs/secrets.md)
brew "age"            # modern file-encryption backend used by sops (key at ~/.config/sops/age/keys.txt)

# ------------------
# Testing
# ------------------
brew "bats-core"      # bash test runner for scripts/tests/*.bats (matches the CI suite)
