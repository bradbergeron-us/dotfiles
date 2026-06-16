# Add a tracked dotfile

Track a new config file by adding one line to [`config/symlinks.map`](https://github.com/bradbergeron-us/dotfiles/blob/main/config/symlinks.map) — the single source of truth that `install.sh`, `verify.sh`, and `bootstrap.sh --dry-run` all read.

## 1. Put the file in the repo

Move the real file into the repo and reference it by a path relative to the repo root. Home-directory dotfiles live under `home/`; XDG configs live under `config/`.

```sh
# Example: track a new ~/.ackrc
mv ~/.ackrc ~/dotfiles/home/ackrc
```

## 2. Add a record to `symlinks.map`

Each record is whitespace-separated: `<src> <dest> [tags]`.

- **`src`** — path relative to the repo root (`DOTFILES_DIR`).
- **`dest`** — path relative to `$HOME`.
- **`tags`** — *optional* comma-separated profile tags (see below). Omit for "all profiles".

```text
home/ackrc             .ackrc
```

For a config under `~/.config`:

```text
config/foo/config.toml  .config/foo/config.toml
```

`install.sh` runs `mkdir -p` on the destination's parent, so nested paths like `.config/foo/` are created automatically.

### Optional: scope it to a profile

The third column gates which [profiles](../profiles.md) get the link, via `profile_includes`:

- **omit / blank** — link on every profile.
- **`gui`** — link on `personal` and `work` only (skipped on `minimal`/`server`).
- **`work`** — link on `work` only.
- **a profile name** (`personal`, `minimal`, …) — that profile only.

```text
home/hyper.js          .hyper.js              gui
```

## 3. Create the symlink

Re-run the installer. It backs up any existing real file to `~/.dotfiles_backup/<timestamp>/`, then links your new entry. It is idempotent — already-correct links report `current`.

```sh
zsh ~/dotfiles/install.sh
```

You'll see a line like `✓ linked    ~/.ackrc` and a summary of `linked · current · backed up · skipped` counts.

## 4. Verify and commit

```sh
bash ~/dotfiles/verify.sh        # confirms the link resolves to the repo
git -C ~/dotfiles add config/symlinks.map home/ackrc
git -C ~/dotfiles commit -m "feat: track ~/.ackrc"
```

!!! tip
    `~/.gitconfig` is intentionally **not** in `symlinks.map`. It's a real file with a thin `[include]` of the tracked `home/gitconfig`, so `git config --global` and tools never write into the repo. That bespoke setup stays in `install.sh`.

## See also

- [Machine Profiles](../profiles.md) — gate a dotfile to specific profiles with the tag column.
- [Add a zsh plugin](add-a-zsh-plugin.md) · [Manage packages](manage-packages.md) — other common additions.
