# Glossary

Definitions for the terms used throughout this repo and its docs. Repo-specific
concepts come first, followed by the third-party tools in the toolchain.

## Repo concepts

### Profile
The durable identity of a managed machine — one of `minimal`, `personal`,
`work`, or `server`. Persisted at `~/.config/dotfiles/profile` and honored by
every lifecycle script, so one shared repo can serve several distinct devices.
Selects which packages, dotfiles, and setup steps apply. See
[Machine Profiles](profiles.md).

### Overlay
An additive layer applied on top of the core set for certain profiles. The
package overlays are `Brewfile.personal` (GUI profiles) and `Brewfile.work`
(work profile), layered onto the always-installed core `Brewfile`. Dotfiles are
"overlaid" similarly via profile `tags` in `config/symlinks.map`.

### SSOT (single source of truth)
A file that is the one and only place a given fact is declared, read by every
consumer so a change propagates everywhere. The repo's SSOT files are
`config/symlinks.map`, `config/mise.toml`, `config/sheldon/plugins.toml`, the
`Brewfile`(+overlays), `.sops.yaml`, and `~/.config/dotfiles/update.conf`. See
[Architecture](architecture.md#single-sources-of-truth).

### Tag
The optional third column in `config/symlinks.map` (and the convention behind
the Brewfile overlays) that gates which profiles an item applies to: blank/`core`
= all, `gui` = `personal`+`work`, `work` = `work` only, or a profile name for
that profile exactly. Interpreted by `profile_includes`.

### Dry-run
A preview mode (`--dry-run` on `bootstrap.sh` and `update.sh`) that reports every
action it *would* take without changing anything — no installs, symlinks,
backups, or prompts. See [Dry-Run and Pre-flight](DRY_RUN_AND_PREFLIGHT.md).

### Pre-flight
The system-readiness check (`scripts/preflight.sh`) that `bootstrap.sh` runs
before making any changes: OS/arch, disk, network, conflicting package managers,
permissions, existing dotfiles, and repo integrity. Critical errors abort;
warnings prompt to continue. See [Dry-Run and Pre-flight](DRY_RUN_AND_PREFLIGHT.md).

### First-run picker
The interactive menu `bootstrap.sh` shows on a genuine first run (no profile flag,
env var, or persisted file, on an interactive terminal) to choose a profile.
Pressing Enter accepts the default, `personal`.

### Thin `~/.gitconfig` include
The pattern where `~/.gitconfig` is a **real file** (not a symlink) that
`[include]`s the tracked `home/gitconfig`. This lets `git config --global …` and
tools like `gh auth setup-git` write into your local file — overriding shared
defaults on that machine only — without corrupting the tracked repo file. See
[Architecture](architecture.md#the-thin-gitconfig-include).

### Brewfile drift
The state where installed Homebrew packages no longer match what the profile's
Brewfiles declare. `verify.sh` reports it as a warning; reconcile with
`brew bundle`. See [Troubleshooting](troubleshooting.md#brewfile-drift).

## Tools

### sheldon
A fast, declarative zsh plugin manager. The plugin list lives in
`config/sheldon/plugins.toml` (an [SSOT](#ssot-single-source-of-truth)) and is
loaded from `home/zshrc` via `eval "$(sheldon source)"`.

### mise
A polyglot runtime/version manager (successor in spirit to asdf) that replaced
chruby + nvm here. One line — `eval "$(mise activate zsh)"` — manages Ruby, Node,
Python, Java, and Go with automatic per-project version switching. Versions are
declared in `config/mise.toml`. See [Shell Performance](performance.md).

### sops / age
The encrypted-secrets stack. **age** is the encryption backend (a public/private
key pair); **sops** encrypts only the *values* in structured files and reads
`.sops.yaml` to decide which files to encrypt and for which recipients. See
[Encrypted Secrets](secrets.md).

### bats
Bats (Bash Automated Testing System) is the test framework used for the repo's
shell helpers. Tests live under `scripts/tests/` and run in CI; the pure helpers
in `scripts/lib/` are written to be unit-testable. See [Contributing](contributing.md).

### starship
The cross-shell prompt, configured in `config/starship.toml` (symlinked to
`~/.config/starship.toml`). Its Ruby module is disabled for startup performance.
See [Shell Performance](performance.md).

### direnv
Loads and unloads environment variables per directory from `.envrc` files.
Configured via `config/direnvrc` (symlinked to `~/.config/direnv/direnvrc`).

### launchd
macOS's service manager. The repo uses it (via `scripts/setup-scheduler.sh`) to
run `update.sh` daily. Because launchd does not source your shell rc, scheduled
runs read defaults from `~/.config/dotfiles/update.conf`. See
[Troubleshooting](troubleshooting.md#scheduled-updates).

### Corepack
The Node-bundled shim manager that provides `yarn` (and `pnpm`) without a
separate Homebrew formula. `bootstrap.sh` runs `corepack enable` so Yarn comes
"from Node".

### git-lfs
Git Large File Storage — replaces large files in git with lightweight pointers.
`bootstrap.sh` runs `git lfs install --skip-repo` to enable it globally; `verify.sh`
confirms the global init.
