# Tool Reference

Full descriptions, rationale, and usage for every tool in the [Brewfile](../Brewfile).
For a quick summary of all tools, see the [tools table in the README](../README.md#tools).

---

## Shell & Prompt

### [Starship](https://starship.rs)
A fast, minimal shell prompt written in Rust that works across any shell. It surfaces contextual information (git branch, language versions, command duration) without configuration overhead, and is significantly faster than traditional prompts. The Ruby module is disabled in `config/starship.toml` to prevent timeout warnings; `command_timeout = 2000` is set as a safety net for other modules.

### [zoxide](https://github.com/ajeetdsouza/zoxide)
A smarter `cd` command that learns which directories you visit most. After a brief learning period you can jump to any frecent directory with `z proj` instead of typing the full path, saving a surprising amount of time across a workday.

### [fzf](https://github.com/junegunn/fzf)
A general-purpose fuzzy finder that integrates deeply into the shell. `Ctrl+R` becomes an interactive, searchable history browser; `Ctrl+T` fuzzy-finds files in the current tree. Once you use it, going back to linear history search feels painful.

---

## File & Search

### [bat](https://github.com/sharkdp/bat)
A `cat` replacement with syntax highlighting, line numbers, and Git change indicators in the gutter. Aliased as `cat` in `zshrc` so the improvement is automatic. Particularly useful when reviewing files or grepping output.

### [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`)
A grep replacement that is typically 5–10× faster than `grep`, respects `.gitignore` by default, and handles Unicode correctly. It's also what VS Code uses under the hood for its search. Use `rg pattern` anywhere you'd use `grep -r`.

### [fd](https://github.com/sharkdp/fd)
A `find` replacement that is faster, uses sensible defaults (ignores hidden files and `.gitignore` entries), and has a cleaner syntax. `fd Gemfile` vs `find . -name Gemfile` speaks for itself.

### [tree](https://oldmanprogrammer.net/source.php?page=tree)
Prints a visual directory tree. Useful for quickly understanding an unfamiliar project structure or documenting a directory layout in a README.

---

## Git

### [git-delta](https://github.com/dandavison/delta)
Replaces the default git diff output with syntax-highlighted, side-by-side diffs with line numbers. It wires into `git diff`, `git show`, `git log -p`, and interactive rebase automatically via the `gitconfig` pager setting. Reviewing code changes becomes significantly easier.

### [lazygit](https://github.com/jesseduffield/lazygit)
A terminal UI for git that makes complex operations (interactive rebase, cherry-pick, staged hunks, stash management) visual and keyboard-driven. Run `lazygit` inside any repo. Particularly valuable for reviewing and staging partial file changes.

### [gh](https://cli.github.com)
The official GitHub CLI. Lets you create PRs, review code, manage issues, and interact with GitHub Actions directly from the terminal without switching to a browser. Pairs well with the git aliases in `gitconfig`.

---

## Utilities

### [jq](https://stedolan.github.io/jq/)
A command-line JSON processor. Indispensable when working with APIs, parsing config files, or inspecting payloads. `curl ... | jq .` is a pattern you'll use constantly once it's available.

### [shellcheck](https://www.shellcheck.net)
A static analysis tool for shell scripts that catches bugs, bad practices, and portability issues before they become problems. Run `shellcheck script.sh` on any shell script you write.

### [tldr](https://tldr.sh)
Community-maintained cheat sheets for CLI commands. Where `man curl` gives you the full specification, `tldr curl` shows the five examples you actually need. Faster than a web search for "how do I do X with this tool".

### [httpie](https://httpie.io) (`http` / `https`)
A human-friendly HTTP client that formats responses with syntax highlighting, handles JSON naturally, and has intuitive syntax for headers and auth. Use it interactively instead of `curl` when debugging APIs. `https httpbin.org/get` vs `curl -s https://httpbin.org/get | jq .` — same result, less typing.

### [watch](https://linux.die.net/man/1/watch)
Re-runs a command on a fixed interval and updates the terminal in place. Useful for monitoring anything that changes over time: `watch kubectl get pods`, `watch git status`, `watch 'ls -lh output/'`. Default interval is 2 seconds; `-n 0.5` for faster polling.

### [direnv](https://direnv.net)
Loads and unloads environment variables automatically as you `cd` into and out of directories. Create a `.envrc` file in a project root and direnv will export those variables the moment you enter the directory, then remove them when you leave. No more forgetting to `export DATABASE_URL` before running a service. The `zshrc` hook (`eval "$(direnv hook zsh)"`) wires this in automatically.

Quick setup for a project:
```sh
echo 'export DATABASE_URL=postgres://localhost/myapp_dev' >> .envrc
direnv allow   # approve once; runs automatically after that
```

The global `config/direnvrc` (symlinked to `~/.config/direnv/direnvrc`) defines reusable layout helpers:
- **`layout python`** — auto-creates and activates a `.venv` virtualenv (uses `uv` if available, 10–100× faster)
- **`layout node`** — adds `node_modules/.bin` to PATH so locally-installed binaries work without `npx`

### [redis](https://redis.io)
An in-memory data store used for background job queues (Sidekiq), caching, and session storage. Running Redis locally lets you develop and test without needing a remote instance. Start/stop it with `brew services start redis` / `brew services stop redis`, or run it in the foreground with `redis-server`.

### [imagemagick](https://imagemagick.org)
A command-line image conversion and manipulation toolkit. Handles virtually any image format. Common uses in a developer workflow:
```sh
convert input.png -resize 800x600 output.jpg   # resize
convert input.pdf[0] thumbnail.png              # first page of PDF to image
mogrify -format webp *.png                      # batch convert all PNGs to WebP
identify image.png                              # show image dimensions and metadata
```
Also required as a native dependency by several Ruby gems (`rmagick`, `mini_magick`) and Python packages (`Pillow` sometimes links to it).

### [pdftk-java](https://gitlab.com/pdftk-java/pdftk)
A PDF toolkit for working with PDF files from the command line. The Java port of the original pdftk (the C version is no longer maintained). Common uses:
```sh
pdftk file1.pdf file2.pdf cat output combined.pdf   # merge PDFs
pdftk input.pdf burst output page_%02d.pdf           # split into individual pages
pdftk form.pdf fill_form data.fdf output filled.pdf  # fill a PDF form
pdftk input.pdf dump_data                            # extract metadata
```
Useful when working with government or enterprise document workflows that require PDF manipulation without opening Acrobat.

### [newman](https://github.com/postmanlabs/newman)
A CLI runner for Insomnia and Postman collections. Executes a collection of API requests from the command line and reports pass/fail results, making API test suites runnable in CI without opening a GUI. Export a collection from Insomnia, add `newman run collection.json` to your CI config.

### [pre-commit](https://pre-commit.com)
A framework for managing git pre-commit hooks. Hooks are defined in a `.pre-commit-config.yaml` at the root of each project and run automatically before every `git commit`.

The `gitconfig` in this repo sets `core.hooksPath = ~/.config/git/hooks`, which points to a global hook stub installed by `install.sh`. This means pre-commit runs automatically in **any repo** that has a `.pre-commit-config.yaml` — no need to run `pre-commit install` in each project individually.

**Available templates:**

| Template | Use for |
|----------|---------|
| `templates/pre-commit-ruby-rails.yaml` | Ruby on Rails — RuboCop (with all plugins), Brakeman, bundler-audit |
| `templates/pre-commit-javascript.yaml` | JavaScript/React — ESLint, Stylelint, Prettier |
| `templates/pre-commit-java.yaml` | Java/Maven — Google Java Format, Checkstyle; SpotBugs optional |
| `templates/pre-commit-config.yaml` | General purpose — hygiene hooks + RuboCop + secrets detection |

**Adding pre-commit to a project:**
```sh
# Ruby on Rails
cp ~/dotfiles/templates/pre-commit-ruby-rails.yaml your-project/.pre-commit-config.yaml
cd your-project && pre-commit run --all-files

# JavaScript / React
cp ~/dotfiles/templates/pre-commit-javascript.yaml your-project/.pre-commit-config.yaml
cd your-project && npm install && pre-commit run --all-files

# Java / Maven
cp ~/dotfiles/templates/pre-commit-java.yaml your-project/.pre-commit-config.yaml
cd your-project && mvn install -DskipTests && pre-commit run --all-files
```

The templates use `repo: local` for tools like Brakeman and ESLint — they run the exact version pinned in your `Gemfile.lock` or `package.json`, matching CI exactly. The trade-off: `bundle install` / `npm install` must be run first.

**Common commands:**
```sh
pre-commit run                 # staged files only
pre-commit run --all-files     # every file in the repo
pre-commit run rubocop         # single hook by name
pre-commit autoupdate          # bump remote hook versions
git commit --no-verify         # skip hooks (use sparingly)
```

---

## tmux

### [tmux](https://github.com/tmux/tmux)
A terminal multiplexer that lets you run multiple terminal sessions within a single window, detach from them without losing state, and restore them later. Essential for long-running processes, remote development, and keeping a structured workspace.

This config uses `C-a` as the prefix (instead of the default `C-b`) to mirror GNU Screen muscle memory.

**Key bindings (prefix = `C-a`):**

| Binding | Action |
|---------|--------|
| `prefix + \` | Split pane horizontally |
| `prefix + -` | Split pane vertically |
| `prefix + c` | New window (remembers current path) |
| `prefix + b` | Break pane into its own window |
| `prefix + r` | Reload `tmux.conf` live |
| `C-h/j/k/l` | Navigate panes (vim-aware — works across Vim splits too) |
| `v` in copy-mode | Begin selection (vim-style) |
| `y` in copy-mode | Copy selection to macOS clipboard |

**Plugins (managed by [TPM](https://github.com/tmux-plugins/tpm)):**

`bootstrap.sh` clones TPM automatically. After first install, open tmux and press `prefix + I` to install plugins.

| Plugin | What it does |
|--------|-------------|
| [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) | Sensible defaults everyone agrees on |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Save/restore sessions across reboots — `prefix + Ctrl-s` / `prefix + Ctrl-r` |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Auto-saves sessions every 15 min; auto-restores on tmux start |

With resurrect + continuum, a machine restart no longer means losing your workspace layout.

---

## Runtime Management

### [mise](https://mise.jdx.dev)
A polyglot version manager written in Rust that replaces `chruby`, `nvm`, and `pyenv` with a single tool. Manages Ruby, Node, Python, Java, Go, and dozens of other runtimes. Versions are set globally in `~/.config/mise/config.toml` and overridden per project via `.mise.toml`, `.ruby-version`, or `.nvmrc` — so existing projects need no changes. Adds ~5ms to shell startup.

```sh
mise install ruby@3.3.6       # install a specific version
mise use node@22               # set globally
mise use --local ruby@3.4      # set for current project only
mise current                   # show active versions
mise ls                        # list all installed versions
```

This replaced `chruby` + `ruby-install` + `nvm` — three separate tools, three shell init blocks, ~500ms of startup overhead.

**`~/.gemrc`** — a one-line config (`gem: --no-document`) that skips generating `ri` and `rdoc` on every `gem install`. Makes installs noticeably faster and saves hundreds of megabytes of rarely-read documentation.

### [uv](https://docs.astral.sh/uv/)
A fast Python package and project manager written in Rust by [Astral](https://astral.sh) (same team as `ruff`). Replaces `pip`, `virtualenv`, `pipx`, and `pip-tools` in a single binary that is 10–100× faster.

```sh
uv venv                   # create .venv in current directory
uv pip install requests   # install into active venv
uv run python script.py   # run without activating the venv
uv tool install black     # install a CLI tool globally (like pipx)
```

The `direnvrc` `layout_python` helper uses `uv` automatically — so `echo 'layout python' >> .envrc && direnv allow` gets you an auto-activating virtualenv in any Python project.

### Go (via mise)
Managed by mise like Ruby and Node. The `zshrc` adds `~/go/bin` to `PATH` so tools installed with `go install` are immediately available.

```sh
mise use --global go@1.24
go install golang.org/x/tools/gopls@latest           # language server
go install github.com/air-verse/air@latest            # live reload
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

### [Rust](https://www.rust-lang.org) (via [rustup](https://rustup.rs))
Managed by `rustup` rather than mise — the Rust project maintains it and it natively supports toolchain switching (stable/beta/nightly), cross-compilation targets, and component management. `bootstrap.sh` installs `rustup` via Homebrew, initializes the stable toolchain, and adds `rustfmt` and `clippy`. The `zshrc` sources `~/.cargo/env` to put `cargo` and all Rust binaries in PATH.

```sh
rustup update                  # update to latest stable
rustup toolchain list          # show installed toolchains
rustup default nightly         # switch to nightly
cargo new my-project           # create a new project
cargo build --release          # compile with optimizations
cargo test && cargo clippy && cargo fmt
```

> **Note:** if `brew install rust` (the static formula) is present, remove it: `brew uninstall rust`. rustup supersedes it and is the correct way to manage Rust for development.

### [ruff](https://docs.astral.sh/ruff/)
An extremely fast Python linter and formatter from [Astral](https://astral.sh) (same team as `uv`), written in Rust. Replaces `flake8`, `pylint`, `isort`, and `black` in one binary, 10–100× faster. Zero config out of the box; configurable via `pyproject.toml`.

```sh
ruff check .            # lint all Python files
ruff check --fix .      # lint and auto-fix safe issues
ruff format .           # format (Black-compatible)
ruff check --select I . # import sorting only
```

---

## Ruby REPLs

**`~/.irbrc`** — IRB is Ruby's built-in REPL and powers `rails console`. This config enables tab completion, persistent history (2000 entries in `~/.irb_history`), auto-indent, syntax-highlighted output, and a cleaner `>>` prompt. The `q` alias exits without typing `exit` or `quit`.

**`~/.pryrc`** — [Pry](https://github.com/pry/pry) is an enhanced Ruby REPL with syntax highlighting, source/doc browsing, and a debugger plugin ecosystem. Often used as the default Rails console (`gem 'pry-rails'`). This config sets a short prompt, defines shell-like aliases (`q`, `c`/`n`/`s` for byebug stepping when `pry-byebug` is available), enables the pager for long output, and stores history in `~/.pry_history`.

Install Pry globally:
```sh
gem install pry pry-byebug   # pry-rails goes in each project's Gemfile
```

---

## Database

**`~/.psqlrc`** — the psql client reads this file on startup, equivalent to a `.bashrc` for your database sessions. This config sets:
- `\x auto` — switches to expanded (vertical) output automatically when rows are too wide
- `\timing on` — prints query execution time after every statement
- `\pset null 'NULL'` — makes NULL values visible instead of showing as empty strings
- Per-database history: `HISTFILE ~/.psql_history-:DBNAME` keeps separate history per database
- `AUTOCOMMIT off` — requires explicit `COMMIT` or `ROLLBACK`; prevents silent mutations

Pairs with Postgres.app. `install.sh` symlinks it to `~/.psqlrc` automatically.

---

## EditorConfig

**`~/.editorconfig`** — [EditorConfig](https://editorconfig.org) is a cross-editor standard for defining code style rules that editors and IDEs read automatically without plugins. VS Code, JetBrains IDEs, Neovim, and many others support it natively.

The global `~/.editorconfig` acts as a fallback for any project without its own `.editorconfig`. Sets sane defaults (UTF-8, LF line endings, 2-space indent, final newline) with overrides for Java/Kotlin/Groovy (4 spaces), Go (tabs), and Makefiles (tabs). Project-level files always take precedence.

---

## Apps

### [Insomnia](https://insomnia.rest)
A GUI REST and GraphQL API client — a solid replacement for Postman. Best for designing, documenting, and sharing API collections with a team. Supports environments and variables, OAuth2 and other auth flows, saved collections, and full GraphQL. Collections can be checked into a repo alongside your code.

**Insomnia vs HTTPie:** they serve different purposes and complement each other. Use Insomnia for organized API collections, complex auth flows, and team sharing. Use HTTPie for quick terminal one-liners, scripting, and piping responses. Exploring a single endpoint? HTTPie. Managing a suite across dev/staging/prod environments? Insomnia.

### [OrbStack](https://orbstack.dev)
A fast, lightweight replacement for Docker Desktop on macOS. Starts in under a second (vs Docker Desktop's 10–30s), uses significantly less RAM and CPU, and runs Linux VMs natively on Apple Silicon. The CLI is fully compatible with Docker (`docker`, `docker-compose`) so no workflow changes are needed. Free for personal use.

### [Raycast](https://raycast.com)
Replaces macOS Spotlight as your primary launcher and desktop control layer. Everything is keyboard-driven: press the hotkey, type what you want, press `Enter`.

**Initial setup:**
1. System Settings → Keyboard → Keyboard Shortcuts → Spotlight → disable `Cmd+Space`
2. Raycast → Settings → General → set hotkey to `Cmd+Space`
3. Raycast → Extensions → Store → install `GitHub`, `Brew`, and anything relevant to your stack
4. Enable Clipboard History under Extensions (off by default)

**Shortcuts worth learning immediately:**

| What to type | What it does |
|---|---|
| App name | Launch or switch to any app |
| `clip` | Open Clipboard History — search and re-paste anything you've copied |
| `left half` / `right half` | Snap window to screen half |
| `maximize` | Fill screen (not macOS full-screen) |
| `42 * 1.08` | Inline calculator — `Enter` copies the result |
| `define <word>` | Dictionary lookup |
| `snip` | Create or search text snippets |
| `quit all` | Close every open app |

For window management: go to Settings → Extensions → Window Management and assign direct shortcuts (e.g. `Ctrl+Opt+Left`) so you skip the launcher entirely for window snapping.

For Clipboard History: assign `Cmd+Shift+V` in Settings → Extensions → Clipboard History.

**Official guide:** [manual.raycast.com](https://manual.raycast.com) — [YouTube channel](https://www.youtube.com/@raycastapp) has short walkthroughs of snippets, script commands, and extensions.
