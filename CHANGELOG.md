# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Neovim baseline: `config/nvim/init.lua` (symlinked to `~/.config/nvim/init.lua`) plus `neovim` in the `Brewfile`. Dependency-free defaults — Space leader, line numbers, 2-space indent, smart-case search, system clipboard, readable diagnostics, and highlight-on-yank.

## [1.0.0] - 2026-06-16

First tagged release. Captures the matured macOS dotfiles setup: a one-command
bootstrap, a safe keep-current workflow, health/status reporting, a curated CLI
toolchain, work-machine support, and CI.

### Added

#### Lifecycle
- `bootstrap.sh` — one-command setup on a fresh Mac (Xcode CLT, Homebrew, `Brewfile`, language runtimes, Rust, git-lfs, dotfile symlinks, optional work configs and macOS defaults). Supports `--dry-run` and `--skip-preflight`.
- `scripts/preflight.sh` — read-only system checks run before bootstrap (`--strict` promotes warnings to failures).
- `install.sh` — idempotent symlinker driven by `config/symlinks.map` (single source of truth). Writes a thin `~/.gitconfig` that *includes* the tracked `home/gitconfig` (so `git config --global` never writes into the repo), seeds `~/.config/git/local.gitconfig`, installs a global pre-commit hook, and backs up pre-existing files to `~/.dotfiles_backup/<timestamp>/`.
- `update.sh` — keep-current: pull, re-symlink, upgrade Homebrew/mise/rustup/gems/uv, then run the health check. Flags `--dry-run`, `--no-upgrade`, `--no-pull`, `--force-pull`, `--help`; skips the pull on a dirty work tree (with an abort-safe rebase); per-machine defaults via `~/.config/dotfiles/update.conf`; writes `logs/update.status`, posts a macOS notification on failure, and rotates `logs/update.log`.
- `verify.sh` — health check across nine areas (symlinks, required tools, stale backups, SSH key, global git-lfs, mise runtimes, dotfiles git health, Brewfile drift, gitconfig include).
- `scripts/status.sh` — fast, read-only snapshot of repo git state + last `update.sh` result; `--verify` and `--exit-code`; aliased `dotstatus`.
- `scripts/setup-scheduler.sh` — launchd job to run `update.sh` daily at 9 AM; `--no-upgrade` / `--no-pull` bake safety flags into the plist.

#### Runtimes & packages
- `config/mise.toml` — single source of truth for Ruby, Node, Java, Python, and Go versions (symlinked to `~/.config/mise/config.toml`).
- Rust via `rustup`; Yarn (and pnpm) via Corepack from the mise-managed Node.
- `Brewfile` — curated CLI toolchain and GUI casks (starship, zoxide, fzf, bat, ripgrep, fd, lsd, git-delta, lazygit, gh, jq, direnv, uv, ruff, and more).

#### Shell & editor config
- `home/` dotfiles: `zshrc`, `zprofile`, `tmux.conf`, `gitconfig`, `gitignore_global`, `ssh_config`, `gemrc`, `irbrc`, `pryrc`, `psqlrc`, `npmrc`, `editorconfig`, `hyper.js`.
- `config/` XDG configs: `starship.toml`, `direnvrc`, `mise.toml`.
- VS Code `settings.json` and tracked extension lists.

#### Work-machine support
- `Brewfile.work` overlay (Gradle, kubectl, Helm).
- `scripts/setup_work_configs.sh` plus templates for Maven, Yarn, Bundle, Continue IDE, Claude Code, and AWS.
- `scripts/install_zscaler_cert.sh`, `scripts/install_claude_code.sh`, `scripts/install_vscode_work_extensions.sh`.
- `home/examples/zshrc.local.example` and `home/examples/update.conf.example` templates.

#### Commit signing
- SSH/GPG commit signing wired up (off by default), with per-organization `includeIf` configs and `scripts/setup_gpg_signing.sh` / `scripts/verify_git_signing.sh`.

#### Quality & CI
- `.github/workflows/ci.yml` — shellcheck, zsh syntax, `Brewfile` validation, `install.sh` smoke test, and gitleaks secret scanning.
- `.github/workflows/test-bootstrap.yml` — auto-discovered hand-rolled unit tests for the `scripts/lib/` helpers.
- Pre-commit hooks (gitleaks, template validation).

#### Documentation
- `README.md`, `CONTRIBUTING.md`, and `docs/` (tools, work-machine setup, GPG signing, dry-run/preflight, performance).

[Unreleased]: https://github.com/bradbergeron-us/dotfiles/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/bradbergeron-us/dotfiles/releases/tag/v1.0.0
