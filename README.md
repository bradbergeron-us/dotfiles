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

## Install

Clone and run the install script:

```sh
git clone https://github.com/bradbergeron-us/dotfiles.git ~/dotfiles
zsh ~/dotfiles/install.sh
```

The script symlinks each file into `$HOME`. Any existing files are backed up to `~/.dotfiles_backup/<timestamp>/` before being replaced.

## Dependencies

Install these before running `install.sh`:

- [Homebrew](https://brew.sh) — package manager
- [chruby](https://github.com/postmodern/chruby) + [ruby-install](https://github.com/postmodern/ruby-install) — Ruby version management
- [nvm](https://github.com/nvm-sh/nvm) — Node version management
- [Starship](https://starship.rs) — shell prompt (`brew install starship`)
- [tmux](https://github.com/tmux/tmux) — terminal multiplexer (`brew install tmux`)
- [colorls](https://github.com/athityakumar/colorls) — enhanced `ls` (`gem install colorls`)

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
