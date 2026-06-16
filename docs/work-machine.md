# Work Machine Setup

Work machines need extra tools (API clients, database CLIs, Kubernetes, Java build tools) that don't belong on every personal Mac. This repo uses a **layered approach** to keep the base `Brewfile` lean while letting work machines opt in.

---

## 1. Install work-specific packages

Mark the machine's profile as `work` and `bootstrap.sh` (or `update.sh`) installs the core `Brewfile` plus the `Brewfile.personal` (GUI) and `Brewfile.work` overlays automatically:

```sh
bash ~/dotfiles/scripts/profile.sh set work   # mark this machine as a work device
# then run bootstrap, or on an existing machine bundle the files below
```

To run the bundles manually:

```sh
brew bundle --file=~/dotfiles/Brewfile           # core CLI (all profiles)
brew bundle --file=~/dotfiles/Brewfile.personal  # GUI casks/fonts/apps
brew bundle --file=~/dotfiles/Brewfile.work      # work additions
```

`Brewfile.work` adds: Gradle, kubectl, and Helm. Insomnia is a GUI app in `Brewfile.personal`; newman, Redis, and Maven are core CLI tools in `Brewfile`. PostgreSQL CLI tools are intentionally excluded: Postgres.app (from `Brewfile.personal`) provides them and installing `postgresql@xx` via Homebrew can cause conflicts.

---

## 2. Create `~/.zshrc.local` from the template

`zshrc.local.example` is a richly commented template covering common work-machine needs. Copy it and uncomment the sections relevant to your setup:

```sh
cp ~/dotfiles/home/examples/zshrc.local.example ~/.zshrc.local
# Open and uncomment the sections that apply to this machine
```

Covers:
- **Machine identity** — `MACHINE_NAME` for distinguishing machines in scripts/prompts
- **Go** — GOPATH override, GOFLAGS for vendored deps, common `go install` tools
- **Rust** — rustup toolchain overrides, CARGO_HOME / RUSTUP_HOME
- **Work PATH entries** — internal tooling, vendored binaries
- **Maven aliases** — `mci`, `mvnt`, `mvninstall -DskipTests`
- **Multi-Java switching** — `use-java 17` / `use-java 21` using mise
- **direnv examples** — sample `.envrc` with `DATABASE_URL`, `REDIS_URL`, `RAILS_ENV`
- **Corporate proxy** — `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY`
- **Work git email** — override the global git email for work commits
- **Sidekiq Pro/Enterprise** — `BUNDLE_ENTERPRISE__CONTRIBSYS__COM` license key
- **PG_CONFIG** — point at Postgres.app for native gem compilation

Because `~/.zshrc.local` is gitignored, all secrets and machine-specific config stay out of the repo entirely.

---

## 3. Global direnv helpers

`install.sh` symlinks `config/direnvrc` to `~/.config/direnv/direnvrc`. This file is sourced before every `.envrc` evaluation and provides reusable layout helpers available in any project:

- **`layout python`** — auto-creates and activates a `.venv` virtualenv (uses `uv` if installed, 10–100× faster than `python3 -m venv`)
- **`layout node`** — adds `node_modules/.bin` to PATH so locally-installed binaries (eslint, tsc, etc.) work without `npx`

Use them in any project's `.envrc`:

```sh
# .envrc
layout python
layout node
export DATABASE_URL=postgres://localhost/myapp_dev
export REDIS_URL=redis://localhost:6379/0
```

Then run `direnv allow` once to approve the file. After that, variables activate automatically on `cd` and unload when you leave.

---

## Safe updates on a work machine

`update.sh` is built not to disturb a working machine:

- **Preview first** — `bash ~/dotfiles/update.sh --dry-run` prints every action it *would* take and changes nothing (no pull, no upgrades, no status-file write, no log rotation).
- **No package upgrades** — `bash ~/dotfiles/update.sh --no-upgrade` pulls the latest dotfiles, re-creates symlinks, and runs the health check, but skips `brew upgrade`, `mise upgrade`, `rustup update`, and `gem update`. Use this when work tooling depends on specific package versions. (For manual runs you can also `export DOTFILES_UPDATE_NO_UPGRADE=1` in `~/.zshrc.local`; to cover the *scheduled* job, see "Make the scheduled job safe too" below, since launchd does not source your shell rc.)
- **Dirty-tree guard** — if `~/dotfiles` has uncommitted changes to tracked files, `update.sh` skips the `git pull` instead of risking a `--rebase --autostash` conflict. Commit or stash first, or pass `--force-pull` to override.
- **Abort-safe pull** — if a `pull --rebase` fails, the in-progress rebase is aborted so the repo is left exactly as it was.
- **Skip the pull entirely** — `--no-pull` (or `DOTFILES_UPDATE_NO_PULL=1`) re-symlinks and verifies against whatever is already checked out.

A conservative work-machine update is therefore:

```sh
bash ~/dotfiles/update.sh --dry-run --no-upgrade   # see exactly what will happen
bash ~/dotfiles/update.sh --no-upgrade             # apply: pull + re-symlink + verify only
```

### Make the scheduled job safe too

The launchd job does **not** source `~/.zshrc`/`~/.zshrc.local`, so an exported `DOTFILES_UPDATE_NO_UPGRADE` never reaches it. Two ways to make the scheduled run safe:

1. **Machine-wide default (recommended)** — set it once in `~/.config/dotfiles/update.conf`; `update.sh` reads this file directly on every run, manual or scheduled:

   ```sh
   mkdir -p ~/.config/dotfiles
   cp ~/dotfiles/home/examples/update.conf.example ~/.config/dotfiles/update.conf
   # then set NO_UPGRADE=true (and/or NO_PULL=true)
   ```

2. **Scheduled-only** — bake the flag into the launchd plist when installing the scheduler:

   ```sh
   bash ~/dotfiles/scripts/setup-scheduler.sh --no-upgrade
   ```

   The scheduled job then runs `update.sh --no-upgrade` while manual runs stay full. Precedence is config file < environment < flags, so a command-line flag always wins for one-off runs.

### One-time migration: `~/.gitconfig` became a thin include

Older checkouts symlinked `~/.gitconfig` to the tracked `home/gitconfig`, so `git config --global …` wrote *into the repo* and left the work checkout permanently "dirty". The current layout makes `~/.gitconfig` a thin **real** file that `[include]`s `home/gitconfig`, with machine-specific settings in `~/.config/git/local.gitconfig`. With the dirty-tree guard above, those leftover local edits would otherwise block every pull, so clear them once:

```sh
cd ~/dotfiles
git status                       # see what accumulated (often home/gitconfig)
git stash                        # or: git checkout -- home/gitconfig
git pull
zsh install.sh                   # rewrites ~/.gitconfig as a thin include, heals moved symlinks
# move any machine-specific git settings into ~/.config/git/local.gitconfig
```

`install.sh` backs up the old `~/.gitconfig` to `~/.dotfiles_backup/<timestamp>/` before replacing it, so nothing is lost.

---

## NVM → mise migration

If NVM is installed on a work machine, `bootstrap.sh` handles it automatically:

- **Ghost install (no versions)** — prompts to remove NVM cleanly (`rm -rf ~/.nvm && brew uninstall nvm`)
- **Has versions installed** — prints a 3-step migration guide and leaves NVM intact; mise and NVM can coexist during transition

Manual migration steps:
```sh
# 1. Install the Node versions you need via mise
mise use --global node@22
mise use --global node@18   # if you need multiple

# 2. Test your projects
# 3. Once satisfied, clean up NVM:
brew uninstall nvm && rm -rf ~/.nvm
```

The `zshrc` NVM guard mirrors this — it only silences NVM if the versions directory is empty, so a work machine mid-migration isn't broken.
