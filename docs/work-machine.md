# Work Machine Setup

Work machines need extra tools (API clients, database CLIs, Kubernetes, Java build tools) that don't belong on every personal Mac. This repo uses a **layered approach** to keep the base `Brewfile` lean while letting work machines opt in.

---

## 1. Install work-specific packages

Run the base Brewfile first, then the work overlay:

```sh
brew bundle --file=~/dotfiles/Brewfile        # shared base (all machines)
brew bundle --file=~/dotfiles/Brewfile.work   # work additions
```

`Brewfile.work` adds: Gradle, kubectl, and Helm. Everything else you might expect here — Insomnia, newman, Redis, and Maven — is already in the base `Brewfile` since it's useful on every machine. PostgreSQL CLI tools are intentionally excluded: Postgres.app (installed by the base Brewfile) provides them and installing `postgresql@xx` via Homebrew can cause conflicts.

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
