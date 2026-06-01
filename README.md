# dotfiles

Personal macOS dotfiles for zsh, tmux, starship, git, Hyper, and a full suite of developer tooling.

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
3. Runs `brew bundle` from `Brewfile` — installs all packages, casks, and mise
4. Sets up `fzf` shell integration (key bindings + tab completion)
5. Authenticates `gh` (GitHub CLI) if not already logged in
6. Generates an SSH key for commit signing and prompts you to add it to GitHub
7. Installs Ruby 3.3.6, Node 22, and Java 17 (Temurin) via mise
8. Installs the `colorls` gem
9. Calls `install.sh` to symlink all dotfiles including VS Code settings and mise config
10. Creates `~/.zshrc.local` from `zshrc.local.example`
11. Optionally applies macOS developer defaults (`macos.sh`)

After running, install manually: [Hyper](https://hyper.is) — everything else (VS Code, Postgres.app, DBeaver, Fira Code, JetBrains Mono) is installed automatically via the Brewfile.

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
| `zshrc` | `~/.zshrc` | Zsh config — mise activation, aliases, hooks |
| `zprofile` | `~/.zprofile` | Zsh login profile — Homebrew path setup |
| `gitconfig` | `~/.gitconfig` | Git — user, delta pager, sane defaults |
| `gitignore_global` | `~/.gitignore_global` | Global gitignore — macOS, editors, logs |
| `tmux.conf` | `~/.tmux.conf` | tmux — C-a prefix, vim keys, pane navigation |
| `hyper.js` | `~/.hyper.js` | Hyper terminal — Tokyo Night theme, JetBrains Mono |
| `config/starship.toml` | `~/.config/starship.toml` | Starship prompt — Ruby module disabled, 2s timeout |
| `Brewfile` | _(used by bootstrap)_ | Declarative list of all Homebrew packages and casks |
| `config/mise.toml` | `~/.config/mise/config.toml` | mise global runtime versions (Ruby, Node, Java) |
| `ssh_config` | `~/.ssh/config` | SSH agent + Keychain config |
| `vscode/settings.json` | `~/Library/.../Code/User/settings.json` | VS Code editor, terminal, and git settings |
| `vscode/extensions.txt` | _(installed by install.sh)_ | Core VS Code extensions for every machine |
| `vscode/extensions-java.txt` | _(manual install)_ | Java-specific VS Code extensions |
| `gemrc` | `~/.gemrc` | Skip ri/rdoc on every `gem install` — faster installs, less disk |
| `psqlrc` | `~/.psqlrc` | psql client defaults — `\x auto`, `\timing on`, per-DB history |
| `editorconfig` | `~/.editorconfig` | Global EditorConfig fallback — indent style, charset, line endings by file type |
| `macos.sh` | _(run once manually)_ | macOS developer defaults (key repeat, Dock, Finder, etc.) |
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

**[tldr](https://tldr.sh)** — community-maintained cheat sheets for CLI commands. Where `man curl` gives you the full specification, `tldr curl` shows the five examples you actually need. Faster than a web search for "how do I do X with this tool".

**[httpie](https://httpie.io)** (`http` / `https`) — a human-friendly HTTP client that formats responses with syntax highlighting, handles JSON naturally, and has intuitive syntax for headers and auth. Use it interactively instead of `curl` when debugging APIs. `https httpbin.org/get` vs `curl -s https://httpbin.org/get | jq .` — same result, less typing.

**[watch](https://linux.die.net/man/1/watch)** — re-runs a command on a fixed interval and updates the terminal in place. Useful for monitoring anything that changes over time: `watch kubectl get pods`, `watch git status`, `watch 'ls -lh output/'`. Default interval is 2 seconds; `-n 0.5` for faster polling.

**[direnv](https://direnv.net)** — loads and unloads environment variables automatically as you `cd` into and out of directories. Create a `.envrc` file in a project root and direnv will export those variables the moment you enter the directory, then remove them when you leave. No more forgetting to `export DATABASE_URL` before running a service. The `zshrc` hook (`eval "$(direnv hook zsh)"`) wires this in automatically.

Quick setup for a project:
```sh
# In your project root:
echo 'export DATABASE_URL=postgres://localhost/myapp_dev' >> .envrc
direnv allow   # approve the .envrc once; it runs automatically after that
```

**[pre-commit](https://pre-commit.com)** — a framework for managing git pre-commit hooks. Hooks are defined in a `.pre-commit-config.yaml` file at the root of each project and run automatically before every `git commit`. This repo includes a template at `templates/pre-commit-config.yaml` covering Ruby/Rails projects.

The `gitconfig` in this repo sets `core.hooksPath = ~/.config/git/hooks`, which points to a global hook stub installed by `install.sh`. This means pre-commit runs automatically in **any repo** that has a `.pre-commit-config.yaml` — no need to run `pre-commit install` in each project individually.

**Available templates:**

| Template | Use for |
|----------|---------|
| `templates/pre-commit-ruby-rails.yaml` | Ruby on Rails — RuboCop (with all plugins), Brakeman, bundler-audit |
| `templates/pre-commit-javascript.yaml` | JavaScript/React — ESLint, Stylelint, Prettier |
| `templates/pre-commit-java.yaml` | Java/Maven — Google Java Format, Checkstyle; SpotBugs and compile check optional |
| `templates/pre-commit-config.yaml` | General purpose — hygiene hooks + RuboCop + secrets detection |

**Adding pre-commit to a project:**

Copy the right template and you're done — no `pre-commit install` needed. The
global hook in `~/.config/git/hooks/pre-commit` (wired up by `install.sh`) runs
pre-commit automatically in any repo that has a `.pre-commit-config.yaml`.

```sh
# Ruby on Rails project
cp ~/dotfiles/templates/pre-commit-ruby-rails.yaml your-project/.pre-commit-config.yaml
cd your-project && pre-commit run --all-files

# JavaScript / React project
cp ~/dotfiles/templates/pre-commit-javascript.yaml your-project/.pre-commit-config.yaml
cd your-project && npm install  # local hooks need this
pre-commit run --all-files

# Java / Maven project
cp ~/dotfiles/templates/pre-commit-java.yaml your-project/.pre-commit-config.yaml
cd your-project && mvn install -DskipTests  # local hooks need a built project
pre-commit run --all-files
```

The first `pre-commit run --all-files` is important — it runs all hooks against
every existing file so you see what would have failed before now, and gives you
a chance to fix things before they block commits.

**How `local` vs remote hooks work:**

The Rails and JavaScript templates use `repo: local` for tools like Brakeman, ESLint, and Stylelint. This means pre-commit runs the tool that's already installed in the project rather than fetching a fresh copy from the internet. The benefit is that it always uses the exact version pinned in your `Gemfile.lock` or `package.json` — the same version CI uses — so there are no version drift surprises.

The trade-off: `local` hooks require `bundle install` / `npm install` to have been run first. If you clone a fresh repo and try to commit before installing dependencies, the hooks will fail.

**Common commands:**

```sh
pre-commit run                   # run hooks on staged files only (default)
pre-commit run --all-files       # run against every file in the repo
pre-commit run rubocop           # run a single hook by name
pre-commit autoupdate            # bump all remote hook versions to latest
git commit --no-verify           # skip hooks entirely (use sparingly)
```

### Runtime management

**[mise](https://mise.jdx.dev)** — a polyglot version manager written in Rust that replaces `chruby`, `nvm`, and `pyenv` with a single tool. It manages Ruby, Node, Python, Java, Go, and dozens of other runtimes from one interface. Versions are set globally in `~/.config/mise/config.toml` and can be overridden per project using `.mise.toml`, `.ruby-version`, or `.nvmrc` — so existing projects need no changes. Activation is a single line in `zshrc` and adds ~5ms to startup. Common commands:

```sh
mise install ruby@3.3.6   # install a specific version
mise use node@22          # set globally
mise use --local ruby@3.4 # set for current project only (writes .mise.toml)
mise current              # show active versions
mise ls                   # list all installed versions
```

This replaced `chruby` + `ruby-install` + `nvm` — three separate tools, three shell init blocks, ~500ms of startup overhead between them.

**`~/.gemrc`** — a one-line config (`gem: --no-document`) that tells Rubygems to skip generating `ri` and `rdoc` documentation on every `gem install`. This makes gem installs noticeably faster and avoids accumulating hundreds of megabytes of documentation that most developers never read locally.

### Database

**`~/.psqlrc`** — the psql client reads this file on startup, equivalent to a `.bashrc` for your database sessions. This repo's `psqlrc` sets:
- `\x auto` — switches to expanded (vertical) output automatically when a result is too wide to fit in the terminal
- `\timing on` — prints query execution time after every statement
- `\pset null 'NULL'` — makes NULL values visible instead of showing as empty strings (a common source of confusion)
- Per-database history: `HISTFILE ~/.psql_history-:DBNAME` keeps a separate history file for each database so context doesn't bleed between projects
- `AUTOCOMMIT off` — requires explicit `COMMIT` or `ROLLBACK`; prevents accidental data mutations from sticking silently

Pairs naturally with Postgres.app. No additional setup needed — `install.sh` symlinks it to `~/.psqlrc`.

### EditorConfig

**`~/.editorconfig`** — [EditorConfig](https://editorconfig.org) is a cross-editor standard for defining code style rules (indentation, line endings, charset, trailing whitespace) that editors and IDEs read automatically without any plugin required in most modern editors. VS Code, JetBrains IDEs, Neovim, and many others respect it natively.

The global `~/.editorconfig` acts as a fallback for any project that doesn't have its own `.editorconfig`. It sets sane defaults (UTF-8, LF line endings, 2-space indent, final newline) with overrides for Java/Kotlin/Groovy (4 spaces), Go (tabs), and Makefiles (tabs). Any project-level `.editorconfig` takes precedence — this is purely a safety net for projects that don't define their own.

### Apps

**[OrbStack](https://orbstack.dev)** — a fast, lightweight replacement for Docker Desktop on macOS. It starts in under a second (vs Docker Desktop's 10–30s), uses significantly less RAM and CPU, and runs Linux VMs natively on Apple Silicon. The CLI is fully compatible with Docker (`docker`, `docker-compose`) so no workflow changes are needed. Free for personal use; worth switching to immediately if you run containers locally.

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

**`1Password CLI` (`op`)** — if using 1Password, the CLI can serve as a secrets manager for the shell. It can inject secrets as environment variables at runtime (`op run -- your-command`) so sensitive values never need to live in `.zshrc.local` or any dotfile at all.

## Machine-specific config (`~/.zshrc.local`)

The last line of `zshrc` sources a local override file if it exists:

```zsh
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

`~/.zshrc.local` is in `.gitignore` and **never committed**. Each machine gets
its own private file that layered on top of the shared config without touching
the repo.

**Why this matters across machines:** the dotfiles repo contains only config
that works everywhere. When you clone onto a new machine — a work laptop, a
remote server, a new personal Mac — `bootstrap.sh` creates `~/.zshrc.local`
from the template. You fill it in with whatever is specific to that machine:

```zsh
# example ~/.zshrc.local on a work machine
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
alias proj='cd ~/code/your-project'
export PATH="$PATH:/opt/internal-tools/bin"
export SOME_LICENSE_KEY=your-key-here
```

The home machine has a different `~/.zshrc.local` with different values. Neither
file is ever in git, so they stay private and don't interfere with each other.

**Rule of thumb:** if a setting would break on a different machine or contains
a secret, it belongs in `~/.zshrc.local`. Everything else belongs in `zshrc`.

`bootstrap.sh` creates `~/.zshrc.local` automatically. To set it up manually:

```sh
cp ~/dotfiles/zshrc.local.example ~/.zshrc.local
# edit with this machine's specific values
```

## Work machine setup

Work machines need extra tools (API clients, database CLIs, Kubernetes, Java build tools) that don't belong on every personal Mac. This repo uses a **layered approach** to keep the base `Brewfile` lean while letting work machines opt in to additional packages.

### 1. Install work-specific Homebrew packages

Run the base Brewfile first, then the work overlay:

```sh
brew bundle --file=~/dotfiles/Brewfile        # shared base (all machines)
brew bundle --file=~/dotfiles/Brewfile.work   # work additions
```

`Brewfile.work` adds: Insomnia, Newman, PostgreSQL 16 CLI tools, Redis, Maven, Gradle, kubectl, and Helm. It does **not** duplicate anything already in `Brewfile`.

### 2. Create `~/.zshrc.local` from the template

`zshrc.local.example` is a richly commented template covering common work-machine needs. Copy it and uncomment the sections relevant to your setup:

```sh
cp ~/dotfiles/zshrc.local.example ~/.zshrc.local
```

Includes sections for:
- **Machine identity** — `MACHINE_NAME` for distinguishing machines
- **Work PATH entries** — internal tooling, vendored binaries
- **Maven aliases** — `mci`, `mvnt`, `mvninstall` with `-DskipTests`
- **Multi-Java switching** — `use-java 17` / `use-java 21` using mise
- **direnv examples** — sample `.envrc` with `DATABASE_URL`, `REDIS_URL`, `RAILS_ENV`
- **Corporate proxy** — `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY`
- **Work git email** — override the global git email for work commits
- **Sidekiq Pro/Enterprise** — `BUNDLE_ENTERPRISE__CONTRIBSYS__COM` license key
- **PG_CONFIG** — point at Postgres.app for native gem compilation

Because `~/.zshrc.local` is in `.gitignore`, all secrets and machine-specific config stay out of the repo entirely.

### 3. Global direnv helpers (`direnvrc`)

`install.sh` symlinks `config/direnvrc` to `~/.config/direnv/direnvrc`. This file is sourced by direnv before every `.envrc` evaluation and provides reusable layout helpers:

- **`layout python`** — auto-creates and activates a `.venv` virtualenv in the project directory
- **`layout node`** — adds `node_modules/.bin` to `PATH` so locally-installed binaries (eslint, tsc, etc.) work without `npx`

Use them in any project's `.envrc`:

```sh
# .envrc
layout python
layout node
export DATABASE_URL=postgres://localhost/myapp_dev
```

Then run `direnv allow` once to approve the file.

## Making changes

Because the dotfiles are symlinked, editing `~/.zshrc` (or any other dotfile)
directly edits the file inside `~/dotfiles/`. Just commit and push:

```sh
cd ~/dotfiles
git add -A && git commit -m "describe your change"
git push
```

## Shell performance

Startup time was reduced from ~2.37s to ~0.11s through a series of targeted changes.

**Replaced chruby + nvm with mise** — the biggest win. The previous setup sourced two chruby scripts, ran `brew --prefix` at startup, and used lazy-loader stub functions for `nvm`/`node`/`npm`/`npx` to avoid nvm's ~500ms cold start. All of that is now one line: `eval "$(mise activate zsh)"`, which adds ~5ms and handles both Ruby and Node with automatic per-project version switching.

**Removed dynamic PATH calls** — a `$(ruby -e 'puts Gem.bindir')` subshell that spawned a full Ruby process on every new shell has been removed.

**Starship Ruby module disabled** — starship's ruby module executed Ruby on every prompt render, causing intermittent timeout warnings. Disabled in `config/starship.toml` with `command_timeout = 2000` as a safety net for other modules.

**Cached `compinit`** — zsh rebuilds its completion dump (`~/.zcompdump`) on every shell start by default. A 24-hour freshness check now skips the rebuild (`compinit -C`) unless the dump is older than a day. Saves ~30–50ms per shell start with no visible downside.

### Benchmark (MacBook Pro, Apple Silicon)

| Measurement | Time |
|-------------|------|
| Original (chruby + nvm + Starship Ruby warnings) | ~2.37s |
| After lazy NVM + removing Ruby PATH call | ~0.58s |
| After replacing chruby + nvm with mise | ~0.11s |
| After compinit caching | **~0.08s** |
| **Total improvement** | **~97% faster** |
