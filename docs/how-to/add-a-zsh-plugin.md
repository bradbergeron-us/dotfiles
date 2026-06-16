# Add a zsh plugin

Zsh plugins are managed declaratively by [sheldon](https://github.com/rossmacarthur/sheldon). Add a plugin by editing [`config/sheldon/plugins.toml`](https://github.com/bradbergeron-us/dotfiles/blob/main/config/sheldon/plugins.toml) — it's symlinked to `~/.config/sheldon/plugins.toml` and sourced from `home/zshrc` via `eval "$(sheldon source)"`.

## 1. Add the plugin

Add a `[plugins.<name>]` table. Most plugins come from GitHub, so use the `github = "owner/repo"` form:

```toml
[plugins.zsh-history-substring-search]
github = "zsh-users/zsh-history-substring-search"
```

sheldon downloads the plugin on the next shell source and generates the source lines automatically — no manual cloning.

!!! note
    Order matters for some plugins. `fast-syntax-highlighting` and `zsh-autosuggestions` should generally stay last; add ordering-sensitive plugins relative to them.

## 2. Reload the shell

Open a new terminal, or re-source your config in the current one:

```sh
exec zsh        # replace the current shell
# or
source ~/.zshrc
```

On first source, sheldon clones the new plugin and you'll see it take effect immediately.

## 3. (Optional) Pin / update versions

sheldon records resolved commits in a lock file. Refresh pinned commits with:

```sh
sheldon lock --update
```

## 4. Commit

```sh
git -C ~/dotfiles add config/sheldon/plugins.toml
git -C ~/dotfiles commit -m "feat: add zsh-history-substring-search plugin"
```

Because the file is tracked and symlinked, every machine picks up the same plugin set on its next `update.sh` or shell reload.

!!! tip
    `home/zshrc` only calls sheldon when it's installed (`command -v sheldon`), falling back to manually-cloned plugins under `~/.zsh`. Ensure `sheldon` is present (it's in the core `Brewfile`) so your new entry is picked up.
