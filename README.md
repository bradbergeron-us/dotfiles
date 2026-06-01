# dotfiles

Personal macOS dotfiles — zsh, tmux, git, and a full developer toolchain.

![CI](https://github.com/bradbergeron-us/dotfiles/actions/workflows/ci.yml/badge.svg)

## Quick start

```sh
git clone https://github.com/bradbergeron-us/dotfiles.git ~/dotfiles
bash ~/dotfiles/bootstrap.sh
```

`bootstrap.sh` runs once on a fresh Mac and handles everything: Homebrew, all packages, runtimes (Ruby, Node, Java, Python, Go, Rust), dotfile symlinks, and macOS defaults. Open a new terminal when it finishes.

**Only manual step:** install [Hyper](https://hyper.is) — everything else installs automatically.

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

### Re-running on an existing machine

```sh
zsh ~/dotfiles/install.sh
```

Re-symlinks everything. Safe to run repeatedly — already-correct symlinks are skipped; existing files are backed up to `~/.dotfiles_backup/<timestamp>/`.

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
brew bundle                          # install everything from Brewfile
brew bundle check                    # check what's missing
brew bundle --upgrade                # upgrade all packages
```

To add a package: edit `Brewfile`, run `brew bundle`.
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
