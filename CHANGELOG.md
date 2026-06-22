# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0](https://github.com/bradbergeron-us/dotfiles/compare/v1.4.0...v1.5.0) (2026-06-22)


### Features

* **update:** add progress messages for long-running upgrade steps ([1ceebb6](https://github.com/bradbergeron-us/dotfiles/commit/1ceebb61f322a7d4cf58be48c61b5cb78fa3dea1))
* **update:** add progress messages for long-running upgrade steps ([6e08166](https://github.com/bradbergeron-us/dotfiles/commit/6e081660f10ca3bbce9af6ade17cc514f4e53a14))


### Bug Fixes

* **install:** install only missing VS Code extensions with correct flag order ([083889c](https://github.com/bradbergeron-us/dotfiles/commit/083889c85045c2bf1e04d325c9b37124cc541413))
* **install:** make VS Code extension install best-effort (don't abort) ([e1c1513](https://github.com/bradbergeron-us/dotfiles/commit/e1c1513be00a845c780369dd0b6de72e04ddb9e0))
* **install:** make VS Code extension install best-effort (don't abort) ([89359d1](https://github.com/bradbergeron-us/dotfiles/commit/89359d1715f2fbe9315e064f86aac5646a9957c2))
* **rust:** support Homebrew's keg-only rustup on PATH and in bootstrap ([ff3dc49](https://github.com/bradbergeron-us/dotfiles/commit/ff3dc49cc103d37cdb5a2b94e9ac1402db0dc325))
* **rust:** support Homebrew's keg-only rustup on PATH and in bootstrap ([8559710](https://github.com/bradbergeron-us/dotfiles/commit/8559710c2e3edae7ee2b90d6cb0f8c1938001862))


### Performance Improvements

* **verify:** snapshot installed packages for the Brewfile drift check ([dfc9436](https://github.com/bradbergeron-us/dotfiles/commit/dfc9436630dbcc4f4aa1aab1c0760cb3c2c6556e))
* **verify:** snapshot installed packages for the Brewfile drift check ([4709e08](https://github.com/bradbergeron-us/dotfiles/commit/4709e08e163edcf8702e6571f58d37d2e75ca8f4))

## [1.4.0](https://github.com/bradbergeron-us/dotfiles/compare/v1.3.0...v1.4.0) (2026-06-22)


### Features

* add cleanup script for removing dotfile cruft ([5be01eb](https://github.com/bradbergeron-us/dotfiles/commit/5be01ebc0dfb34d865f2a089686aee270d44328c))
* add unified dotfiles CLI wrapper with doctor command ([890825b](https://github.com/bradbergeron-us/dotfiles/commit/890825b3f35a459b52367f4605fd9791dc6993b0))
* **cli:** add dotfiles man page and verify/doctor --help ([ca6474b](https://github.com/bradbergeron-us/dotfiles/commit/ca6474b33bff591b734252f69d0dbb992ff567a4))
* **cli:** add dotfiles man page and verify/doctor --help ([6fd3ac6](https://github.com/bradbergeron-us/dotfiles/commit/6fd3ac6d04a7cad82227a6834ecd3e8c76b4a168))
* dotfiles platform roadmap (unified CLI, doctor, modular zsh, Ghostty) ([bb526c5](https://github.com/bradbergeron-us/dotfiles/commit/bb526c5809c1112d84ec58e69f7bce452fe3c6ba))
* **ghostty:** support an optional local override include ([6e7334b](https://github.com/bradbergeron-us/dotfiles/commit/6e7334b0a8725d39a662a60a1a29864f7c37c49d))
* show active git email in starship prompt ([75866e7](https://github.com/bradbergeron-us/dotfiles/commit/75866e7dfc4262619de5eee8b954c06ed2977937))


### Bug Fixes

* **brewfile:** use current flux-app cask name ([95a05f3](https://github.com/bradbergeron-us/dotfiles/commit/95a05f361af63cdfe5398f14ff8655c0db43a89f))
* **docs:** use absolute URL for root CONTRIBUTING.md links ([33adced](https://github.com/bradbergeron-us/dotfiles/commit/33adcedf4356d19e41052859f331ee0e7f185327))
* **verify:** detect git-lfs via include-aware global config ([05b3dc5](https://github.com/bradbergeron-us/dotfiles/commit/05b3dc58bffdbb50000c8ef5cfdb3b7d9be056de))
* **verify:** missing-only Brewfile drift check + flux-app rename ([b74df96](https://github.com/bradbergeron-us/dotfiles/commit/b74df966a204947a48929d1904124b4eea4f3cec))
* **verify:** report only missing packages in Brewfile drift check ([bc01fa9](https://github.com/bradbergeron-us/dotfiles/commit/bc01fa940e694ec60c8d478ed12e6f10aa9c2d8c))

## [1.3.0](https://github.com/bradbergeron-us/dotfiles/compare/v1.2.0...v1.3.0) (2026-06-16)


### Features

* revive uninstaller (mirror of install.sh, profile-aware) ([8e847fb](https://github.com/bradbergeron-us/dotfiles/commit/8e847fb3c18d7bd80fbdf79ca1fe0d0298da34f5))
* revive uninstaller as the mirror of install.sh ([477f91c](https://github.com/bradbergeron-us/dotfiles/commit/477f91c04d8d198a2553f1c42c064f35d8c19237))

## [1.2.0](https://github.com/bradbergeron-us/dotfiles/compare/v1.1.0...v1.2.0) (2026-06-16)


### Features

* **docs:** Tokyo Night theme for the docs site ([36612b2](https://github.com/bradbergeron-us/dotfiles/commit/36612b21cb53722467867ec63eb5e3510643ab2e))
* **docs:** Tokyo Night theme for the docs site ([62c2392](https://github.com/bradbergeron-us/dotfiles/commit/62c239267e719006dbc8574a5a568a872d8868b0))

## [Unreleased]

## [1.1.0] - 2026-06-16

First release since `v1.0.0`. Adds machine profiles, encrypted secrets, a live
MkDocs documentation site, sheldon-managed zsh plugins, a Neovim baseline, and
expanded CI/testing — plus a guided first-run experience.

### Added
- **Machine profiles** — every machine now resolves a profile (`personal`, `work`, `minimal`, `server`) that drives which packages, dotfiles, and bootstrap steps apply.
  - Profile resolution and persistence with precedence `--profile` flag > `DOTFILES_PROFILE` env > `~/.config/dotfiles/profile` > `personal`, managed via `scripts/profile.sh` (aliased `dotprofile`).
  - Profile-aware symlinking — `config/symlinks.map` entries can be tagged so only the active profile's dotfiles install.
  - Per-profile Homebrew overlays — `Brewfile.personal` (GUI casks/fonts/apps on `personal`/`work`) and `Brewfile.work` (work-only additions) layered over the core `Brewfile`.
  - Profile-gated bootstrap steps — work configs run only on `work`; macOS defaults only on `personal`/`work` (skipped on `minimal`/`server`).
  - Guided first-run profile picker — `bootstrap.sh` prompts for a profile on a fresh machine and persists the choice.
- **Encrypted secrets** — sops + age workflow via `scripts/secrets.sh` and `.sops.yaml`, documented in `docs/secrets.md`.
- **Neovim baseline** — `config/nvim/init.lua` (symlinked to `~/.config/nvim/init.lua`) plus `neovim` in the `Brewfile`. Dependency-free defaults — Space leader, line numbers, 2-space indent, smart-case search, system clipboard, readable diagnostics, and highlight-on-yank.
- **Zsh plugins via [sheldon](https://sheldon.cli.rs)** — `config/sheldon/plugins.toml` (symlinked to `~/.config/sheldon/plugins.toml`) managing fast-syntax-highlighting and zsh-autosuggestions.
- **Documentation site** — MkDocs Material site deployed to GitHub Pages at <https://bradbergeron-us.github.io/dotfiles/> (`mkdocs.yml`, `.github/workflows/docs.yml`, `site_url`, pinned `docs/requirements.txt`).
- **GitHub templates** — issue and pull request templates under `.github/`.
- **Bootstrap dry-run CI** — `.github/workflows` job exercising `bootstrap.sh --dry-run` so the no-op path stays green.

### Changed
- **Test suite migrated to bats-core** — hand-rolled `scripts/lib/` unit tests replaced with bats-core tests, with `.github/workflows/test-bootstrap.yml` updated to run them. CONTRIBUTING now documents the bats workflow.

### Fixed
- Silenced dry-run stderr noise so `bootstrap.sh --dry-run` output stays clean.

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

[Unreleased]: https://github.com/bradbergeron-us/dotfiles/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/bradbergeron-us/dotfiles/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/bradbergeron-us/dotfiles/releases/tag/v1.0.0
