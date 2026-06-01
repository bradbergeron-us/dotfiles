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
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
zsh ~/dotfiles/install.sh
```

The script symlinks each file into `$HOME`. Any existing files are backed up to `~/.dotfiles_backup/<timestamp>/` before being replaced.

## Adding a new machine

1. Install dependencies: [Homebrew](https://brew.sh), [chruby](https://github.com/postmodern/chruby), [nvm](https://github.com/nvm-sh/nvm), [starship](https://starship.rs), [tmux](https://github.com/tmux/tmux)
2. Clone this repo to `~/dotfiles`
3. Run `zsh ~/dotfiles/install.sh`

## Making changes

Edit files directly in `~/dotfiles/` (the symlinks mean `~/.zshrc` etc. already point here), then commit and push:

```sh
cd ~/dotfiles
git add -A && git commit -m "your message"
git push
```
