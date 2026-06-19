# Zsh configuration

The shell config is split into small, focused modules so each concern is easy to
find and edit. `~/.zshrc` is a symlink to `home/zshrc`, which is a **thin loader**
that sources the modules in `home/zsh/`.

## How loading works

`home/zshrc` resolves its own real path — even though it is reached through the
`~/.zshrc` symlink — and derives the module directory from it:

```bash
_zshrc_self="${${(%):-%x}:A}"                 # ~/.zshrc -> ~/dotfiles/home/zshrc
DOTFILES_DIR="${DOTFILES_DIR:-${_zshrc_self:h:h}}"
DOTFILES_ZSH_DIR="${DOTFILES_ZSH_DIR:-${_zshrc_self:h}/zsh}"
```

This means the modules are sourced **straight from the repo** — they are not
symlinked individually, so there is nothing extra to add to
`config/symlinks.map`. You can override the location by exporting
`DOTFILES_ZSH_DIR` before the shell starts, and there is a fallback to
`~/dotfiles/home/zsh` if resolution ever fails.

Modules are sourced with a small `source_if_exists` helper, in the same order
their settings ran in the original monolithic `zshrc`.

## Modules

| Module | Responsibility |
|--------|----------------|
| `home/zsh/path.zsh` | `PATH` and core environment: `EDITOR`, `~/dotfiles/bin`, NVM guard, mise, cargo, Go, `~/.local/bin`, fzf |
| `home/zsh/functions.zsh` | Shell functions + zsh hooks: Claude-session detection, terminal tab-title, git rebase helpers (`grn`, `grbic`) |
| `home/zsh/aliases.zsh` | All aliases (git, navigation, editor, `bat` as `cat`, …) |
| `home/zsh/prompt.zsh` | Starship prompt initialization |
| `home/zsh/plugins.zsh` | sheldon plugin manager (with manual fallback) + completion init (`compinit`) |
| `home/zsh/integrations.zsh` | Third-party hooks: zoxide, direnv |

Machine-local files keep their original positions in `home/zshrc`:
`~/afs_localprops.sh`, then `~/.zshrc.local`, and finally uv's
`~/.local/bin/env`.

## Where things go

- **A new alias** → `home/zsh/aliases.zsh`
- **A new function** → `home/zsh/functions.zsh`
- **A new tool integration** (`eval "$(tool init zsh)"`) → `home/zsh/integrations.zsh`
- **A `PATH` or environment entry** → `home/zsh/path.zsh`
- **A whole new module** → create `home/zsh/<name>.zsh` and add a
  `source_if_exists "$DOTFILES_ZSH_DIR/<name>.zsh"` line to `home/zshrc`

## Local overrides

Per-machine configuration is **not** committed. Put it in `~/.zshrc.local`,
which `home/zshrc` sources last so it can override anything above:

```bash
cp ~/dotfiles/home/examples/zshrc.local.example ~/.zshrc.local
```

The template covers Go/Rust overrides, Java switching, corporate proxy, work git
email, Claude Code SSL, and more. Keep secrets out of tracked files — they belong
only in `~/.zshrc.local`.

## Validating

Syntax-check everything (no execution):

```bash
zsh -n home/zshrc
find home/zsh -name "*.zsh" -print0 | xargs -0 -n1 zsh -n
```

Or let the CLI do it as part of the broader health check:

```bash
dotfiles doctor
```

CI also runs `zsh -n` on `home/zshrc` and every `home/zsh/*.zsh` module.
