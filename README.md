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

## Tools

Everything installed via the `Brewfile`, with context on what each tool does
and why it's worth having.

### Shell & prompt

**[Starship](https://starship.rs)** — a fast, minimal shell prompt written in Rust that works across any shell. It surfaces contextual information (git branch, language versions, command duration) without configuration overhead, and is significantly faster than traditional prompts.

**[zoxide](https://github.com/ajeetdsouza/zoxide)** — a smarter `cd` command that learns which directories you visit most. After a brief learning period you can jump to any frecent directory with `z proj` instead of typing the full path, saving a surprising amount of time across a workday.

**[fzf](https://github.com/junegunn/fzf)** — a general-purpose fuzzy finder that integrates deeply into the shell. `Ctrl+R` becomes an interactive, searchable history browser; `Ctrl+T` fuzzy-finds files in the current tree. Once you use it, going back to linear history search feels painful.

### File & search

**[bat](https://github.com/sharkdp/bat)** — a `cat` replacement with syntax highlighting, line numbers, and Git change indicators in the gutter. Aliased as `cat` here so the improvement is automatic. Particularly useful when reviewing files or grepping output.

**[ripgrep](https://github.com/BurntSushi/ripgrep)** (`rg`) — a grep replacement that is typically 5–10× faster than `grep`, respects `.gitignore` by default, and handles Unicode correctly. It's also what VS Code uses under the hood for its search. Use `rg pattern` anywhere you'd use `grep -r`.

**[fd](https://github.com/sharkdp/fd)** — a `find` replacement that is faster, uses sensible defaults (ignores hidden files and `.gitignore` entries), and has a cleaner syntax. `fd Gemfile` vs `find . -name Gemfile` speaks for itself.

**[tree](https://oldmanprogrammer.net/source.php?page=tree)** — prints a visual directory tree. Useful for quickly understanding an unfamiliar project structure or documenting a directory layout in a README.

### Git

**[git-delta](https://github.com/dandavison/delta)** — replaces the default git diff output with syntax-highlighted, side-by-side diffs with line numbers. It wires into `git diff`, `git show`, `git log -p`, and interactive rebase automatically via the `gitconfig` pager setting. Reviewing code changes becomes significantly easier.

**[lazygit](https://github.com/jesseduffield/lazygit)** — a terminal UI for git that makes complex operations (interactive rebase, cherry-pick, staged hunks, stash management) visual and keyboard-driven. Run `lazygit` inside any repo. Particularly valuable for reviewing and staging partial file changes.

**[gh](https://cli.github.com)** — the official GitHub CLI. Lets you create PRs, review code, manage issues, and interact with GitHub Actions directly from the terminal without switching to a browser. Pairs well with the git aliases already in `gitconfig`.

### Utilities

**[jq](https://stedolan.github.io/jq/)** — a command-line JSON processor. Indispensable when working with APIs, parsing config files, or inspecting payloads. `curl ... | jq .` is a pattern you'll use constantly once it's available.

**[shellcheck](https://www.shellcheck.net)** — a static analysis tool for shell scripts that catches bugs, bad practices, and portability issues before they become problems. Run `shellcheck script.sh` on any shell script you write.

### Apps

**[Raycast](https://raycast.com)** — replaces macOS Spotlight as your primary launcher and desktop control layer. Everything is keyboard-driven: press the hotkey, type what you want, press `Enter`. No mouse required.

**Initial setup (do this first):**
1. Open System Settings → Keyboard → Keyboard Shortcuts → Spotlight — disable `Cmd+Space`
2. Open Raycast → Settings → General — set the Raycast hotkey to `Cmd+Space`
3. Open Raycast → Extensions → Store — install `GitHub`, `Brew`, and anything else relevant to your stack
4. Enable Clipboard History under Extensions (it's off by default)

**How it works:** press `Cmd+Space`, type any part of a command name, and press `Enter` to run it. You don't need exact names — fuzzy matching finds it. Press `Cmd+K` on any result to see all available actions for it.

**Shortcuts worth learning immediately:**

| What to type | What it does |
|---|---|
| `Cmd+Space`, then app name | Launch or switch to any app |
| `Cmd+Space`, then `clip` | Open Clipboard History — search and re-paste anything you've copied |
| `Cmd+Space`, then `left half` | Snap the current window to the left half of the screen |
| `Cmd+Space`, then `right half` | Snap to right half |
| `Cmd+Space`, then `maximize` | Full-screen the current window (not macOS full-screen, just resized) |
| `Cmd+Space`, then `42 * 1.08` | Evaluate inline — press `Enter` to copy the result |
| `Cmd+Space`, then `define <word>` | Dictionary lookup inline |
| `Cmd+Space`, then `snip` | Create or search text snippets |
| `Cmd+Space`, then `quit all` | Close every open app at once |

For window management: after a few uses, go to Settings → Extensions → Window Management and assign direct keyboard shortcuts (e.g. `Ctrl+Opt+Left` for left half) so you no longer need to open the launcher at all for window snapping.

For Clipboard History: assign `Cmd+Shift+V` as a direct hotkey in Settings → Extensions → Clipboard History. After that, every copy you make is searchable — code snippets, URLs, API responses, anything.

**Official guide:** [manual.raycast.com](https://manual.raycast.com) covers every feature in depth. The [YouTube channel](https://www.youtube.com/@raycastapp) has short walkthroughs of specific features like snippets, script commands, and extensions that are worth watching once to understand what's possible.

## Future considerations

Things worth evaluating as the setup evolves.

**[mise](https://mise.jdx.dev)** (formerly `rtx`) — a single polyglot version manager that can replace `chruby`, `nvm`, and `pyenv` with one unified tool. It manages Ruby, Node, Python, Java, Go, and many other runtimes using a single `.mise.toml` config file per project, and is significantly faster than the tools it replaces. The main reason to hold off for now is migration cost — existing projects rely on `.ruby-version` and `.nvmrc` files that chruby and nvm already handle well. When starting fresh on a new machine or project it would be the first choice.

**Commit signing with GPG or SSH** — signing commits proves they actually came from you, which matters on shared repositories and is increasingly expected on open-source projects. GitHub supports both GPG keys and SSH signing keys. Worth setting up once and adding the relevant `gitconfig` entries (`gpg.format`, `commit.gpgSign`, `user.signingkey`) to this repo.

**`1Password CLI` (`op`)** — if using 1Password, the CLI can serve as a secrets manager for the shell. It can inject secrets as environment variables at runtime (`op run -- your-command`) so sensitive values never need to live in `.zshrc.local` or any dotfile at all.

**`pre-commit`** — a framework for managing git pre-commit hooks across projects. Rather than relying on each repo to configure its own hooks, `pre-commit` provides a standard way to run linters, formatters, and checks automatically before every commit.

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
