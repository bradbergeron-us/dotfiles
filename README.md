# dotfiles

Personal macOS dotfiles for zsh, tmux, starship, git, and Hyper.

## Contents

| File | Destination | Description |
|------|-------------|-------------|
| `zshrc` | `~/.zshrc` | Zsh config — lazy NVM, chruby, aliases, hooks |
| `zprofile` | `~/.zprofile` | Zsh login profile — Homebrew, Python PATH |
| `gitconfig` | `~/.gitconfig` | Git user config and credential helper |
| `tmux.conf` | `~/.tmux.conf` | tmux — C-a prefix, vim keys, pane navigation |
| `hyper.js` | `~/.hyper.js` | Hyper terminal — Tokyo Night theme, JetBrains Mono |
| `config/starship.toml` | `~/.config/starship.toml` | Starship prompt config |

## Install on a new Mac

Clone and run the bootstrap script — it installs all dependencies and symlinks
everything in one step:

```sh
git clone https://github.com/bradbergeron-us/dotfiles.git ~/dotfiles
bash ~/dotfiles/bootstrap.sh
```

`bootstrap.sh` will:
1. Install Xcode CLI Tools (if needed — re-run after they finish)
2. Install Homebrew (works on both Apple Silicon and Intel)
3. Install brew packages: `chruby`, `ruby-install`, `nvm`, `starship`, `tmux`, `zoxide`, `git-lfs`, `openssl@3`
4. Install Ruby 3.3.6 via `ruby-install`
5. Install the `colorls` gem
6. Symlink all dotfiles into `$HOME` (backing up any existing files)
7. Create `~/.zshrc.local` from the template if it doesn't exist yet

Then install manually: [Hyper](https://hyper.is) and [VS Code](https://code.visualstudio.com).

## Machine-specific config

Anything specific to a machine (project paths, aliases, licenses, extra PATH
entries, Java paths, etc.) lives in `~/.zshrc.local`. This file is sourced at
the end of `.zshrc` but is **never committed** to the repo (it's in `.gitignore`).

A template is provided:

```sh
cp ~/dotfiles/zshrc.local.example ~/.zshrc.local
# then edit ~/.zshrc.local
```

## Shell performance

The zshrc is optimised for fast startup. Key decisions:

**Lazy NVM loading** — `nvm.sh` is not sourced at shell start. Instead, stub
functions for `nvm`, `node`, `npm`, and `npx` load it on first use. The
`load-nvmrc` hook walks the directory tree in pure shell to find `.nvmrc`
without touching NVM unless one is present.

**No dynamic PATH calls** — the previous `$(ruby -e 'puts Gem.bindir')` call
(which spawned a Ruby process on every shell start) has been removed; `chruby`
already manages the Ruby bin path.

**Starship Ruby module disabled** — the starship `[ruby]` module is disabled in
`config/starship.toml` to prevent Ruby execution on every prompt render. A
`command_timeout` of 2000ms is set as a global safety net for other modules.

### Benchmark results (MacBook Pro, Apple Silicon)

| Measurement | Startup time |
|-------------|-------------|
| Before optimisations | ~2.37s |
| After optimisations | ~0.30s |
| **Improvement** | **~87% faster** |

## Making changes

Edit files directly in `~/dotfiles/` (the symlinks mean `~/.zshrc` etc. already
point here), then commit and push:

```sh
cd ~/dotfiles
git add -A && git commit -m "your message"
git push
```
