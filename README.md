# dotfiles

Personal macOS dotfiles — zsh, tmux, git, and a full developer toolchain.

![CI](https://github.com/bradbergeron-us/dotfiles/actions/workflows/test-bootstrap.yml/badge.svg)

> **Security Note:** This repository contains safe-to-share configuration templates. Machine-specific configs with actual GPG keys, work emails, and infrastructure URLs are stored in `~/.config/git/*.gitconfig` and are never committed. See [Git Commit Signing](#git-commit-signing) for details.

## Quick start

```sh
git clone https://github.com/bradbergeron-us/dotfiles.git ~/dotfiles
bash ~/dotfiles/bootstrap.sh
```

`bootstrap.sh` runs once on a fresh Mac and handles everything: Homebrew, all packages, runtimes (Ruby, Node, Java, Python, Go, Rust), dotfile symlinks, and macOS defaults. Open a new terminal when it finishes.

### Preview changes before running

```sh
bash ~/dotfiles/bootstrap.sh --dry-run
```

Shows what will be installed without making any changes. See [docs/DRY_RUN_AND_PREFLIGHT.md](docs/DRY_RUN_AND_PREFLIGHT.md) for details.

<details>
<summary>What bootstrap.sh does, step by step</summary>

1. Xcode Command Line Tools
2. Homebrew (auto-detects Apple Silicon vs Intel)
3. `brew bundle` — all packages, casks, fonts from `Brewfile`
4. fzf shell integration
5. GitHub CLI auth (`gh auth login` if needed)
6. SSH key for commit signing — generated, added to Keychain, copied to clipboard
7. Ruby 3.3.6, Node 22, Java 21, Python 3.12, Go 1.24 via mise
8. Rust stable via rustup (+ rustfmt, clippy)
9. TPM (tmux plugin manager)
10. `install.sh` — symlinks all dotfiles
11. `~/.zshrc.local` from template
12. Work-specific configurations — `.m2`, `.yarnrc`, `.continue`, `.claude`, `.aws` (optional prompt)
13. macOS developer defaults (optional prompt)

</details>

### Keeping everything current

```sh
bash ~/dotfiles/update.sh
```

Pulls the latest dotfiles, re-symlinks, upgrades all Homebrew packages, updates mise runtimes, Rust toolchain, and global gems. Finishes with a health check. Safe to run any time.

Preview first, or keep a machine deterministic by skipping package upgrades:

```sh
bash ~/dotfiles/update.sh --dry-run      # preview everything; change nothing
bash ~/dotfiles/update.sh --no-upgrade   # pull + re-symlink + verify only (no brew/mise/rustup/gem upgrades)
```

`--no-upgrade` is handy on a work laptop where tooling is version-sensitive. If the dotfiles repo has uncommitted local changes, `update.sh` skips the `git pull` to avoid a rebase conflict (override with `--force-pull`); a failed rebase is aborted automatically so the repo is left untouched. See [docs/work-machine.md](docs/work-machine.md#safe-updates-on-a-work-machine) for the work-machine workflow.

To schedule daily automatic runs via launchd (9 AM): `bash ~/dotfiles/scripts/setup-scheduler.sh` (add `--no-upgrade` so the scheduled run skips upgrades too). For a machine-wide default honored by **both** manual and scheduled runs, set `NO_UPGRADE=true` in `~/.config/dotfiles/update.conf` (see `home/examples/update.conf.example`) — the launchd job reads it directly since it can't see your shell rc.

To run the health check standalone: `bash ~/dotfiles/verify.sh`

For a quick read-only snapshot (repo git state + last `update.sh` result): `bash ~/dotfiles/scripts/status.sh` (aliased as `dotstatus`).

To re-symlink without upgrading packages: `zsh ~/dotfiles/install.sh`

### Machine profile
Each machine has a **profile** selecting which packages, dotfiles, and steps apply: `personal` (default, full GUI Mac), `work`, `minimal`, or `server`. Show or set it without re-bootstrapping:

```sh
bash ~/dotfiles/scripts/profile.sh           # show the active profile (aliased: dotprofile)
bash ~/dotfiles/scripts/profile.sh set work  # persist this machine's profile
```

Stored at `~/.config/dotfiles/profile`; precedence is `--profile` flag > `DOTFILES_PROFILE` env > that file > `personal`. (Selecting a profile is recorded now; profile-aware packages, symlinks, and steps land in follow-up changes.)

### Terminal preview

<details>
<summary>What bootstrap.sh looks like when it runs</summary>

```
  🚀  dotfiles bootstrap  —  macOS developer setup
  ─────────────────────────────────────────────────
  Machine  your-machine-name
  Date     Mon Jun 01 2026  08:00
  ─────────────────────────────────────────────────

  ▸ [1/14]  🛠️  Xcode Command Line Tools
  ✓ Xcode CLI Tools

  ▸ [2/14]  🍺  Homebrew
  ✓ Homebrew 4.5.2

  ▸ [3/14]  📦  Packages (brew bundle)
  → Installing packages from Brewfile...
  ✓ Brew packages installed

  ▸ [4/14]  🔍  fzf shell integration
  ✓ fzf configured

  ▸ [5/14]  🔑  SSH key for commit signing
  ✓ SSH key already exists at ~/.ssh/id_ed25519 — skipping

  ▸ [6/14]  🐙  GitHub CLI authentication
  ✓ GitHub CLI already authenticated

  ▸ [7/14]  ⚡  Runtimes via mise  (Ruby · Node · Java · Python · Go)
  → Installing Ruby, Node, Java, Python, and Go via mise...
  ✓ Ruby, Node, Java, Python, and Go installed via mise

  ▸ [8/14]  🧶  Yarn via Corepack (from Node)
  → Enabling Corepack (yarn + pnpm shims)...
  ✓ Corepack enabled — yarn 4.9.1

  ▸ [9/14]  🦀  Rust (rustup)
  ✓ rustup already installed: rustc 1.86.0

  ▸ [10/14]  🖥️  tmux plugin manager (TPM)
  ✓ TPM already installed

  ▸ [11/14]  📁  git-lfs
  ✓ git-lfs

  ▸ [12/14]  🔗  Dotfile symlinks

  🔗  dotfiles  ─  symlinking from ~/dotfiles
  ─────────────────────────────────────────────────
  ✓ current   ~/.zshrc
  ✓ current   ~/.gitconfig
  ✓ linked    ~/.irbrc
  ✓ linked    ~/.pryrc
  ...
  ─────────────────────────────────────────────────
  ✓ 3 linked  ·  14 current  ·  0 backed up
  ✓ 🎉  Done — open a new shell or: source ~/.zshrc

  ▸ [13/14]  🏢  Work-specific configurations

  Setup work configs (.m2, .yarnrc, .continue, .claude, .aws)?

  Run work configuration setup? [y/N]: y
  ✓ Work configurations installed

  ▸ [14/14]  ⚙️  macOS developer defaults
  Apply recommended macOS defaults? [y/N]: y

  ─────────────────────────────────────────────────
  🎉  Bootstrap complete  in 4m 23s
  ─────────────────────────────────────────────────

  Next steps
  1. Edit ~/.zshrc.local with machine-specific config
  2. Open a new terminal  (or: source ~/.zshrc)
  3. Keep everything current: bash ~/dotfiles/update.sh
```

</details>

---

## Dotfiles

| File | Symlinked to | What it does |
|------|-------------|--------------|
| `home/zshrc` | `~/.zshrc` | Shell config — mise, PATH, aliases, plugins |
| `home/zprofile` | `~/.zprofile` | Login profile — Homebrew PATH setup |
| `home/gitconfig` | `~/.gitconfig` _(include)_ | Git defaults, delta pager, SSH signing — loaded via a thin `~/.gitconfig` (not a symlink) so `git config --global` / tool writes stay out of the repo |
| `home/gitignore_global` | `~/.gitignore_global` | Global ignores — macOS, editors, Java, Go |
| `home/tmux.conf` | `~/.tmux.conf` | tmux — `C-a` prefix, vim keys, TPM plugins |
| `config/ghostty/config` | `~/.config/ghostty/config` | **Ghostty (preferred terminal)** — Tokyo Night, JetBrains Mono Nerd Font |
| `home/hyper.js` | `~/.hyper.js` | Hyper _(fallback terminal)_ — Tokyo Night theme, JetBrains Mono |
| `config/starship.toml` | `~/.config/starship.toml` | Starship prompt config |
| `config/mise.toml` | `~/.config/mise/config.toml` | Global runtime versions (Ruby, Node, Java, Python, Go) |
| `config/direnvrc` | `~/.config/direnv/direnvrc` | Shared `layout python` / `layout node` helpers |
| `home/ssh_config` | `~/.ssh/config` | SSH agent + macOS Keychain |
| `home/gemrc` | `~/.gemrc` | `--no-document` — faster gem installs |
| `home/irbrc` | `~/.irbrc` | IRB/rails console defaults |
| `home/pryrc` | `~/.pryrc` | Pry REPL defaults |
| `home/psqlrc` | `~/.psqlrc` | psql defaults — `\x auto`, `\timing`, per-DB history |
| `home/editorconfig` | `~/.editorconfig` | Global EditorConfig fallback |
| `config/nvim/init.lua` | `~/.config/nvim/init.lua` | Neovim — dependency-free baseline (Space leader, 2-space indent, diagnostics) |
| `vscode/settings.json` | `~/Library/.../Code/User/settings.json` | VS Code settings |
| `vscode/extensions.txt` | _(auto-installed)_ | Core VS Code extensions |
| `Brewfile` · `Brewfile.personal` · `Brewfile.work` | _(used by bootstrap)_ | Core CLI formulae + per-profile overlays (GUI casks/fonts/apps; work additions) |
| `home/npmrc` | `~/.npmrc` | npm defaults — `save-exact`, no fund/update noise |
| `update.sh` | _(run to update)_ | Upgrade all packages, runtimes, and gems; runs health check at end |
| `verify.sh` | _(run to verify)_ | Health check — symlinks, missing tools, installed runtimes, stale backups |
| `scripts/setup-scheduler.sh` | _(run once)_ | Install launchd job to run `update.sh` daily at 9 AM |
| `scripts/status.sh` | _(run / `dotstatus`)_ | Quick read-only health snapshot — repo git state + last `update.sh` result |
| `scripts/profile.sh` | _(run / `dotprofile`)_ | Show or set this machine's profile (`personal`/`work`/`minimal`/`server`) |
| `scripts/macos.sh` | _(run once)_ | macOS developer defaults |
| `home/examples/zshrc.local.example` | _(template)_ | Template for machine-specific overrides |

---

## Tools

Quick reference — [full descriptions, rationale, and usage in docs/tools.md](docs/tools.md)

### Shell & Prompt

| Tool | What it does |
|------|-------------|
| [Starship](https://starship.rs) | Fast cross-shell prompt — git, language versions, command duration |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart `cd` — `z proj` jumps to frecent dirs |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder — `Ctrl+R` history, `Ctrl+T` file picker |

### File & Search

| Tool | What it does |
|------|-------------|
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting — aliased as `cat` |
| [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) | 5–10× faster `grep`, respects `.gitignore` |
| [fd](https://github.com/sharkdp/fd) | Faster `find` with sensible defaults |
| [tree](https://oldmanprogrammer.net/source.php?page=tree) | Visual directory tree |

### Git

| Tool | What it does |
|------|-------------|
| [git-delta](https://github.com/dandavison/delta) | Syntax-highlighted diffs for `git diff`, `log`, `show` |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for git — rebase, cherry-pick, staged hunks |
| [gh](https://cli.github.com) | GitHub CLI — PRs, issues, Actions from the terminal |
| [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager) | Cross-platform credential helper — GitHub, GitHub Enterprise, Bitbucket from one machine |

### Utilities

| Tool | What it does |
|------|-------------|
| [jq](https://stedolan.github.io/jq/) | CLI JSON processor — `curl ... \| jq .` |
| [shellcheck](https://www.shellcheck.net) | Shell script linter |
| [tldr](https://tldr.sh) | Community cheat sheets — `tldr curl` vs `man curl` |
| [httpie](https://httpie.io) | Human-friendly HTTP client (`http`, `https`) |
| [watch](https://linux.die.net/man/1/watch) | Re-run a command on an interval |
| [direnv](https://direnv.net) | Per-directory env vars via `.envrc` — auto-loads on `cd` |
| [newman](https://github.com/postmanlabs/newman) | CLI runner for Insomnia/Postman collections |
| [redis](https://redis.io) | In-memory data store — background jobs, caching, sessions |
| [imagemagick](https://imagemagick.org) | Image conversion — resize, crop, format conversion |
| [pdftk-java](https://gitlab.com/pdftk-java/pdftk) | PDF toolkit — merge, split, fill forms, extract pages |
| [pre-commit](https://pre-commit.com) | Git hook framework — templates for Ruby, JS, Java |

### Runtime Management

| Tool | What it does |
|------|-------------|
| [mise](https://mise.jdx.dev) | Polyglot version manager — replaces chruby, nvm, pyenv |
| [uv](https://docs.astral.sh/uv/) | Fast Python packages — replaces pip, virtualenv, pipx |
| [ruff](https://docs.astral.sh/ruff/) | Fast Python linter + formatter — replaces flake8, black, isort |
| Go (via mise) | Go 1.24 — `~/go/bin` in PATH for `go install` tools |
| [Rust](https://www.rust-lang.org) (via [rustup](https://rustup.rs)) | Rust stable + rustfmt + clippy |
| [Yarn](https://yarnpkg.com) (via Corepack) | JS package manager — enabled from the mise-managed Node, no separate install |

### Apps

| App | What it does |
|-----|-------------|
| [Ghostty](https://ghostty.org) | Preferred terminal — GPU-accelerated, native macOS; Tokyo Night + JetBrains Mono Nerd Font (`config/ghostty/config`) |
| [Hyper](https://hyper.is) | Fallback terminal — kept installed during the Ghostty transition (`home/hyper.js`) |
| [Raycast](https://raycast.com) | Launcher, clipboard history, window management — replaces Spotlight |
| [Insomnia](https://insomnia.rest) | GUI REST/GraphQL client — API design, collections, team sharing |
| [OrbStack](https://orbstack.dev) | Docker Desktop replacement — starts in <1s, lower RAM/CPU |
| [VS Code](https://code.visualstudio.com) | Editor — settings and extensions tracked in `vscode/` |
| [Neovim](https://neovim.io) | Terminal editor — dependency-free baseline in `config/nvim/init.lua` |
| [Postgres.app](https://postgresapp.com) | PostgreSQL with a macOS GUI |
| [DBeaver](https://dbeaver.io) | Universal database GUI |

---

## Package management

Packages are split by profile (see [Machine profile](#machine-profile)):

- **`Brewfile`** — core CLI formulae, installed for every profile.
- **`Brewfile.personal`** — GUI casks, fonts, and apps (`personal`, `work`).
- **`Brewfile.work`** — work-only additions: Gradle, kubectl, Helm (`work`).

`bootstrap.sh` installs the core file plus the active profile's overlays automatically; `minimal`/`server` get core only.

```sh
brew bundle --file=~/dotfiles/Brewfile           # core CLI tools (all profiles)
brew bundle --file=~/dotfiles/Brewfile.personal  # GUI casks/fonts/apps (personal/work)
brew bundle --file=~/dotfiles/Brewfile.work      # work-only additions
brew bundle check --file=~/dotfiles/Brewfile     # check what's missing
```

To add a package: put CLI formulae in `Brewfile`, GUI casks/fonts/apps in `Brewfile.personal`, then run `brew bundle`. To upgrade everything, use `update.sh`.

---

## Machine-specific config (`~/.zshrc.local`)

`~/.zshrc.local` is sourced last and never committed. Each machine has its own:

```sh
cp ~/dotfiles/home/examples/zshrc.local.example ~/.zshrc.local
```

Covers Go/Rust overrides, Maven aliases, Java switching, direnv examples, corporate proxy, work git email, Sidekiq license keys, and more. See [docs/work-machine.md](docs/work-machine.md) for additional work-specific topics.

---

## Git Commit Signing

Commit signing is wired up but **off by default** in the committed `gitconfig` (`commit.gpgsign = false`). Enable it per machine in `~/.config/git/local.gitconfig`, or sign automatically per organization for repositories under `~/Code/workN/` via Git's `includeIf` directives.

```bash
# Generate or select a GPG key and record it in ~/.config/git/local.gitconfig
zsh ~/dotfiles/scripts/setup_gpg_signing.sh

# Verify per-organization signing once configured
bash ~/dotfiles/scripts/verify_git_signing.sh
```

See **[docs/GPG_SIGNING.md](docs/GPG_SIGNING.md)** for the full guide — GPG and SSH signing, per-organization (`work1`/`work2`) conditional configs, uploading keys to GitHub/GitLab/Bitbucket, and troubleshooting.

---

## Work Machine Setup

For work laptops with corporate proxy, internal registries, and AWS Bedrock access:

### Quick Setup

```sh
# 1. Run standard bootstrap
bash ~/dotfiles/bootstrap.sh

# 2. Setup work configurations (.m2, .yarnrc, .continue, .claude, .aws)
bash ~/dotfiles/scripts/setup_work_configs.sh

# 3. Install Zscaler certificate
bash ~/dotfiles/scripts/install_zscaler_cert.sh

# 4. Install Claude Code CLI
bash ~/dotfiles/scripts/install_claude_code.sh

# 5. Configure AWS credentials
aws configure sso --profile bedrock

# 6. Install VS Code work extensions
bash ~/dotfiles/scripts/install_vscode_work_extensions.sh

# 7. Verify everything
bash ~/dotfiles/verify.sh
```

### What Gets Configured

The work configuration setup creates templates for:

- **Maven** (`~/.m2/settings.xml`) — Nexus mirror and repository profiles
- **Yarn** (`~/.yarnrc`) — JFrog registry and auth settings
- **Bundle** (`~/.bundle/config`) — JFrog registry for Ruby gems
- **Continue IDE** (`~/.continue/config.yaml`) — AWS Bedrock models (Claude 4.5 & 3.7 Sonnet)
- **Claude Code** (`~/.claude/settings.json`) — AWS Bedrock environment and certificate path
- **AWS** (`~/.aws/config`) — Profile and region configuration
- **Certificates** (`~/.continue/certs/`) — Zscaler root certificate for corporate proxy
- **Claude CLI** (`~/.local/bin/claude`) — Claude Code command-line interface

### Security

All templates are safe to commit. Sensitive data (credentials, secrets, actual certificates) is stored locally and git-ignored:

- `system/certs/*.crt` — Actual certificate files (ignored)
- `system/installers/*` — Binary installers (ignored)
- `vscode/extensions/*.vsix` — Extension files (ignored)
- `~/.aws/credentials` — Never created by scripts (use SSO or aws-vault)

### Complete Guide

See **[docs/work-setup-complete.md](docs/work-setup-complete.md)** for:
- Prerequisites and required files
- Step-by-step installation guide
- Troubleshooting common issues
- Security best practices
- Advanced configuration

Or for additional work-specific topics: [docs/work-machine.md](docs/work-machine.md)

---

## Making changes

Because most dotfiles are symlinked, editing `~/.zshrc` edits `~/dotfiles/home/zshrc` directly. (Exception: `~/.gitconfig` is a thin _include_, not a symlink — edit `home/gitconfig` for shared settings; machine-specific or tool-written git config stays in `~/.gitconfig` / `~/.config/git/local.gitconfig`.)

```sh
cd ~/dotfiles
git add -A && git commit -m "describe change"
git push
```

---

## 📚 Documentation

| Doc | Contents |
|-----|---------|
| [docs/tools.md](docs/tools.md) | Full descriptions, rationale, and commands for every tool |
| [docs/work-setup-complete.md](docs/work-setup-complete.md) | **Complete work machine setup guide** — end-to-end from fresh macOS to production-ready |
| [docs/work-machine.md](docs/work-machine.md) | Additional work topics — Brewfile.work, zshrc.local, direnv, NVM migration |
| [docs/performance.md](docs/performance.md) | Shell startup optimization history and benchmarks |
