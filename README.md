# dotfiles

Personal macOS dotfiles — zsh, tmux, git, and a full developer toolchain.

![CI](https://github.com/bradbergeron-us/dotfiles/actions/workflows/test-bootstrap.yml/badge.svg)

## Quick start

```sh
git clone https://github.com/bradbergeron-us/dotfiles.git ~/dotfiles
bash ~/dotfiles/bootstrap.sh
```

`bootstrap.sh` runs once on a fresh Mac and handles everything: Homebrew, all packages, runtimes (Ruby, Node, Java, Python, Go, Rust), dotfile symlinks, and macOS defaults. Open a new terminal when it finishes.

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
9. `colorls` gem
10. TPM (tmux plugin manager)
11. `install.sh` — symlinks all dotfiles
12. `~/.zshrc.local` from template
13. macOS developer defaults (optional prompt)

</details>

### Keeping everything current

```sh
bash ~/dotfiles/update.sh
```

Pulls the latest dotfiles, re-symlinks, upgrades all Homebrew packages, updates mise runtimes, Rust toolchain, and global gems. Finishes with a health check — also runnable standalone: `bash ~/dotfiles/verify.sh`. Safe to run any time.

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

  ▸ [8/13]  💎  Ruby gems
  ✓ colorls

  ▸ [9/13]  🦀  Rust (rustup)
  ✓ rustup already installed: rustc 1.86.0

  ▸ [10/13]  🖥️  tmux plugin manager (TPM)
  ✓ TPM already installed

  ▸ [11/13]  📁  git-lfs
  ✓ git-lfs

  ▸ [12/13]  🔗  Dotfile symlinks

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

Covers Go/Rust overrides, Maven aliases, Java switching, direnv examples, corporate proxy, work git email, Sidekiq license keys, and more. See [docs/work-machine.md](docs/work-machine.md) for the full work machine setup guide.

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
| [docs/work-machine.md](docs/work-machine.md) | Work machine setup — Brewfile.work, zshrc.local, direnv |
| [docs/performance.md](docs/performance.md) | Shell startup optimization history and benchmarks |
