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

To schedule daily automatic runs via launchd (9 AM): `bash ~/dotfiles/setup-scheduler.sh`

To run the health check standalone: `bash ~/dotfiles/verify.sh`

To re-symlink without upgrading packages: `zsh ~/dotfiles/install.sh`

### Terminal preview

<details>
<summary>What bootstrap.sh looks like when it runs</summary>

```
  🚀  dotfiles bootstrap  —  macOS developer setup
  ─────────────────────────────────────────────────
  Machine  your-machine-name
  Date     Mon Jun 01 2026  08:00
  ─────────────────────────────────────────────────

  ▸ [1/13]  🛠️  Xcode Command Line Tools
  ✓ Xcode CLI Tools

  ▸ [2/13]  🍺  Homebrew
  ✓ Homebrew 4.5.2

  ▸ [3/13]  📦  Packages (brew bundle)
  → Installing packages from Brewfile...
  ✓ Brew packages installed

  ▸ [4/13]  🔍  fzf shell integration
  ✓ fzf configured

  ▸ [5/13]  🔑  SSH key for commit signing
  ✓ SSH key already exists at ~/.ssh/id_ed25519 — skipping

  ▸ [6/13]  🐙  GitHub CLI authentication
  ✓ GitHub CLI already authenticated

  ▸ [7/13]  ⚡  Runtimes via mise  (Ruby · Node · Java · Python · Go)
  → Installing Ruby, Node, Java, Python, and Go via mise...
  ✓ Ruby, Node, Java, Python, and Go installed via mise

  ▸ [8/13]  🦀  Rust (rustup)
  ✓ rustup already installed: rustc 1.86.0

  ▸ [9/13]  🖥️  tmux plugin manager (TPM)
  ✓ TPM already installed

  ▸ [10/13]  📁  git-lfs
  ✓ git-lfs

  ▸ [11/13]  🔗  Dotfile symlinks

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

  ▸ [12/13]  🏢  Work-specific configurations

  Setup work configs (.m2, .yarnrc, .continue, .claude, .aws)?

  Run work configuration setup? [y/N]: y
  ✓ Work configurations installed

  ▸ [13/13]  ⚙️  macOS developer defaults
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
| `zshrc` | `~/.zshrc` | Shell config — mise, PATH, aliases, plugins |
| `zprofile` | `~/.zprofile` | Login profile — Homebrew PATH setup |
| `gitconfig` | `~/.gitconfig` | Git defaults, delta pager, SSH signing |
| `gitignore_global` | `~/.gitignore_global` | Global ignores — macOS, editors, Java, Go |
| `tmux.conf` | `~/.tmux.conf` | tmux — `C-a` prefix, vim keys, TPM plugins |
| `hyper.js` | `~/.hyper.js` | Hyper — Tokyo Night theme, JetBrains Mono |
| `config/starship.toml` | `~/.config/starship.toml` | Starship prompt config |
| `config/mise.toml` | `~/.config/mise/config.toml` | Global runtime versions (Ruby, Node, Java, Python, Go) |
| `config/direnvrc` | `~/.config/direnv/direnvrc` | Shared `layout python` / `layout node` helpers |
| `ssh_config` | `~/.ssh/config` | SSH agent + macOS Keychain |
| `gemrc` | `~/.gemrc` | `--no-document` — faster gem installs |
| `irbrc` | `~/.irbrc` | IRB/rails console defaults |
| `pryrc` | `~/.pryrc` | Pry REPL defaults |
| `psqlrc` | `~/.psqlrc` | psql defaults — `\x auto`, `\timing`, per-DB history |
| `editorconfig` | `~/.editorconfig` | Global EditorConfig fallback |
| `vscode/settings.json` | `~/Library/.../Code/User/settings.json` | VS Code settings |
| `vscode/extensions.txt` | _(auto-installed)_ | Core VS Code extensions |
| `Brewfile` | _(used by bootstrap)_ | All Homebrew packages and casks |
| `npmrc` | `~/.npmrc` | npm defaults — `save-exact`, no fund/update noise |
| `update.sh` | _(run to update)_ | Upgrade all packages, runtimes, and gems; runs health check at end |
| `verify.sh` | _(run to verify)_ | Health check — symlinks, version drift, missing tools, stale backups |
| `setup-scheduler.sh` | _(run once)_ | Install launchd job to run `update.sh` daily at 9 AM |
| `macos.sh` | _(run once)_ | macOS developer defaults |
| `zshrc.local.example` | _(template)_ | Template for machine-specific overrides |

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

### Apps

| App | What it does |
|-----|-------------|
| [Raycast](https://raycast.com) | Launcher, clipboard history, window management — replaces Spotlight |
| [Insomnia](https://insomnia.rest) | GUI REST/GraphQL client — API design, collections, team sharing |
| [OrbStack](https://orbstack.dev) | Docker Desktop replacement — starts in <1s, lower RAM/CPU |
| [VS Code](https://code.visualstudio.com) | Editor — settings and extensions tracked in `vscode/` |
| [Postgres.app](https://postgresapp.com) | PostgreSQL with a macOS GUI |
| [DBeaver](https://dbeaver.io) | Universal database GUI |

---

## Package management

```sh
brew bundle --file=~/dotfiles/Brewfile          # install everything
brew bundle check --file=~/dotfiles/Brewfile    # check what's missing
```

To add a package: edit `Brewfile`, run `brew bundle`. To upgrade all packages, use `update.sh` — it runs `brew upgrade` as part of the full update cycle.

Work machine? Also run `brew bundle --file=~/dotfiles/Brewfile.work`.

---

## Machine-specific config (`~/.zshrc.local`)

`~/.zshrc.local` is sourced last and never committed. Each machine has its own:

```sh
cp ~/dotfiles/zshrc.local.example ~/.zshrc.local
```

Covers Go/Rust overrides, Maven aliases, Java switching, direnv examples, corporate proxy, work git email, Sidekiq license keys, and more. See [docs/work-machine.md](docs/work-machine.md) for additional work-specific topics.

---

## Git Commit Signing

This dotfiles repo uses **conditional GPG signing** based on repository location. Commits are automatically signed with the appropriate key depending on which organization the repository belongs to.

### Directory Structure

Organize your repositories by organization for automatic signing:

```
~/Code/
├── work1/            # Work organization 1 (auto-signs with work email)
│   ├── project-a
│   ├── project-b
│   └── ...
├── work2/            # Work organization 2 (auto-signs with work email)
│   ├── client-x
│   ├── client-y
│   └── ...
└── personal/         # Personal projects (unsigned or use personal key)
    ├── my-app
    ├── dotfiles
    └── side-projects
```

### Setting Up GPG Keys

#### 1. Generate work-specific GPG keys

```bash
# Work organization 1 key
gpg --full-generate-key
# Choose: RSA and RSA, 4096 bits, no expiration
# Email: your.name@work1.com

# Work organization 2 key (if applicable)
gpg --full-generate-key
# Email: your.name@work2.com

# Personal key (optional, for personal repos)
gpg --full-generate-key
# Email: your.name@personal.com
```

#### 2. Get your GPG key IDs

```bash
gpg --list-secret-keys --keyid-format=long

# Example output:
# sec   rsa4096/7FF14C4EDCDD84B3 2026-06-09 [SCEAR]
#       ^^^^^^^^^^^^^^^^^^^^
#       This is your key ID
```

#### 3. Add public keys to respective services

```bash
# Export public keys (replace KEY_ID with your actual key IDs)
gpg --armor --export YOUR_WORK1_KEY_ID
gpg --armor --export YOUR_WORK2_KEY_ID
gpg --armor --export YOUR_PERSONAL_KEY_ID
```

Add to respective services:
- **Work GitHub/GitLab**: Your organization's git service settings
- **Personal GitHub**: https://github.com/settings/gpg/new
- **Other services**: Bitbucket, Azure DevOps, etc.

#### 4. Configure conditional git configs

Create config files from templates:

```bash
# Work organization 1 configuration
cp ~/dotfiles/templates/config/git/work.gitconfig.template ~/.config/git/work1.gitconfig
# Edit ~/.config/git/work1.gitconfig and set your work email and GPG key ID

# Work organization 2 configuration (if applicable)
cp ~/dotfiles/templates/config/git/work.gitconfig.template ~/.config/git/work2.gitconfig
# Edit ~/.config/git/work2.gitconfig and set your work email and GPG key ID
```

#### 5. Verify configuration

```bash
bash ~/dotfiles/scripts/verify_git_signing.sh
```

Expected output:
```
🔍 Verifying git signing configuration...

✅ PASS Work Organization 1
  Email:      your.name@work1.com
  Signing key: YOUR_WORK1_KEY_ID
  Auto-sign:  true

✅ PASS Work Organization 2
  Email:      your.name@work2.com
  Signing key: YOUR_WORK2_KEY_ID
  Auto-sign:  true

✅ All git signing configurations are correct!
```

### How It Works

The main `gitconfig` uses `includeIf` directives to automatically load organization-specific configs:

```gitconfig
# Auto-loads when working in ~/Code/work1/
[includeIf "gitdir:~/Code/work1/"]
    path = ~/.config/git/work1.gitconfig

# Auto-loads when working in ~/Code/work2/
[includeIf "gitdir:~/Code/work2/"]
    path = ~/.config/git/work2.gitconfig
```

Each organization config overrides:
- `user.email` → Organization-specific email
- `user.signingkey` → Organization-specific GPG key
- `commit.gpgsign` → Enable signing

### Troubleshooting

**Commits not being signed:**
```bash
# Check which config is active
cd ~/Code/work1/your-project
git config --list --show-origin | grep -E 'user|commit|signing'
```

**Verify GPG key works:**
```bash
echo "test" | gpg --clearsign --default-key YOUR_GPG_KEY_ID
```

**Disable signing globally (emergency rollback):**
```bash
git config --global commit.gpgsign false
```

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

- `certs/*.crt` — Actual certificate files (ignored)
- `installers/*` — Binary installers (ignored)
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

Because dotfiles are symlinked, editing `~/.zshrc` edits `~/dotfiles/zshrc` directly:

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
