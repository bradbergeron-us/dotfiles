# Ghostty (preferred terminal)

[Ghostty](https://ghostty.org) is the preferred terminal for these dotfiles: it
is fast (GPU-accelerated), native on macOS, and configured with zero required
options. [Hyper](https://hyper.is) is kept as a fallback during the transition.

## Why Ghostty

- GPU-accelerated rendering and native macOS UI (tabs, splits, window restore).
- Simple text config that is easy to track and validate in CI/`doctor`.
- Matches the rest of the toolchain's look: Tokyo Night + JetBrains Mono Nerd Font.

## How the config is installed

The tracked config lives at `config/ghostty/config` and is symlinked to
`~/.config/ghostty/config` by `install.sh`. Like every tracked symlink, the
mapping is declared once in `config/symlinks.map`:

```text
config/ghostty/config  .config/ghostty/config  gui
```

The `gui` tag means the link is created on the `personal` and `work` profiles and
skipped on `minimal`/`server`. Re-link any time with `zsh ~/dotfiles/install.sh`.

## Validating

Ghostty ships a validator that checks for syntax errors and invalid keys/values:

```bash
ghostty +validate-config                         # validate the installed config
ghostty +validate-config --config-file=config/ghostty/config  # validate the repo file
```

`dotfiles doctor` runs this automatically (when Ghostty is installed) as part of
its terminal-configuration check, and falls back to confirming the config file
exists otherwise. Reload a running Ghostty with **⌘+Shift+,**.

## Local customization (untracked)

Per-machine tweaks go in `~/.config/ghostty/ghostty.local`, which the tracked
config pulls in via an optional include at the end:

```ini
config-file = ?ghostty.local
```

The path is relative to the config file, and the leading `?` means Ghostty does
not error if the file is absent. Because the include is last, anything you set
there overrides the tracked defaults. Create it only when you need to:

```bash
printf 'font-size = 16\n' > ~/.config/ghostty/ghostty.local
```

This keeps machine-specific preferences out of the tracked `config/ghostty/config`.

## Hyper fallback

Hyper remains available so you always have a working terminal. Its config is
tracked at `home/hyper.js` → `~/.hyper.js` (also `gui`-tagged) and uses the same
Tokyo Night theme and JetBrains Mono font. Nothing here removes or replaces
Hyper; Ghostty is simply the default going forward.
