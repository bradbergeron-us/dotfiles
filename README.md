# dotfiles

Personal macOS dotfiles for zsh, tmux, starship, git, and Hyper.

## Scripts

There are two scripts with distinct purposes:

### `bootstrap.sh` — new machine setup

Run this **once on a brand new Mac**. It installs all dependencies from scratch
and then calls `install.sh` to wire up the symlinks.

```sh
git clone https://github.com/bradbergeron-us/dotfiles.git ~/dotfiles
bash ~/dotfiles/bootstrap.sh
```

What it does, in order:
1. Installs Xcode Command Line Tools (pauses and prompts you to re-run if needed)
2. Installs Homebrew — detects Apple Silicon (`/opt/homebrew`) or Intel (`/usr/local`) automatically
3. Runs `brew bundle` from `Brewfile` — installs all packages and casks including Raycast
4. Sets up `fzf` shell integration (key bindings + tab completion)
5. Installs Ruby 3.3.6 via `ruby-install`
6. Installs the `colorls` gem
7. Calls `install.sh` to symlink the dotfiles
8. Creates `~/.zshrc.local` from `zshrc.local.example` if it doesn't already exist

After running, install manually: [Hyper](https://hyper.is) and [VS Code](https://code.visualstudio.com).

### `install.sh` — symlink dotfiles only

Run this when **dependencies are already installed** (e.g. re-cloning on a
machine you've set up before, or after pulling updates).

```sh
zsh ~/dotfiles/install.sh
```

Creates symlinks from `$HOME` into `~/dotfiles/` for each dotfile. Any
existing files that aren't already symlinked here are backed up to
`~/.dotfiles_backup/<timestamp>/` before being replaced. Safe to re-run —
already-correct symlinks are left untouched.

## Dotfiles

| File | Symlinked to | Description |
|------|--------------|-------------|
| `zshrc` | `~/.zshrc` | Zsh config — lazy NVM, chruby, aliases, hooks |
| `zprofile` | `~/.zprofile` | Zsh login profile — Homebrew path setup |
| `gitconfig` | `~/.gitconfig` | Git — user, delta pager, sane defaults |
| `gitignore_global` | `~/.gitignore_global` | Global gitignore — macOS, editors, logs |
| `tmux.conf` | `~/.tmux.conf` | tmux — C-a prefix, vim keys, pane navigation |
| `hyper.js` | `~/.hyper.js` | Hyper terminal — Tokyo Night theme, JetBrains Mono |
| `config/starship.toml` | `~/.config/starship.toml` | Starship prompt — Ruby module disabled, 2s timeout |
| `Brewfile` | _(used by bootstrap)_ | Declarative list of all Homebrew packages and casks |
| `zshrc.local.example` | _(template only)_ | Template for machine-specific overrides |

## Package management (Brewfile)

All Homebrew packages are declared in `Brewfile`. This replaces manually
tracking what's installed and makes restoring a new machine repeatable.

```sh
# Install everything (new machine or after adding packages)
brew bundle --file=~/dotfiles/Brewfile

# Check what's missing without installing
brew bundle check --file=~/dotfiles/Brewfile

# Upgrade all packages to latest
brew bundle --file=~/dotfiles/Brewfile --upgrade
```

To add a new package, add it to `Brewfile` and run `brew bundle`. Categories
in the file: shell & prompt, file & search, git, Ruby, Node, tmux, utilities,
and casks (GUI apps).

## Machine-specific config (`~/.zshrc.local`)

Anything specific to a machine — project paths, aliases, licenses, extra PATH
entries, Java paths, etc. — belongs in `~/.zshrc.local`. This file is sourced
at the end of `.zshrc` but is **never committed** (it's in `.gitignore`).

`bootstrap.sh` creates it automatically from the template. To set it up
manually:

```sh
cp ~/dotfiles/zshrc.local.example ~/.zshrc.local
# edit ~/.zshrc.local with your machine-specific values
```

## Making changes

Because the dotfiles are symlinked, editing `~/.zshrc` (or any other dotfile)
directly edits the file inside `~/dotfiles/`. Just commit and push:

```sh
cd ~/dotfiles
git add -A && git commit -m "describe your change"
git push
```

## Shell performance

The zshrc is optimised for fast startup. Key decisions:

**Lazy NVM loading** — `nvm.sh` is not sourced at shell start. Stub functions
for `nvm`, `node`, `npm`, and `npx` load it on first use. The `load-nvmrc`
hook finds `.nvmrc` files via pure shell traversal without touching NVM unless
one is present.

**No dynamic PATH calls** — the previous `$(ruby -e 'puts Gem.bindir')` call
(which spawned a Ruby process on every shell start) has been removed; `chruby`
already manages the Ruby bin path.

**Starship Ruby module disabled** — prevents Ruby execution on every prompt
render. A `command_timeout` of 2000ms is set as a global safety net.

### Benchmark (MacBook Pro, Apple Silicon)

| Measurement | Time |
|-------------|------|
| Before | ~2.37s |
| After | ~0.30s |
| **Improvement** | **~87% faster** |
