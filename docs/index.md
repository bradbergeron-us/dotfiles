# dotfiles

Personal macOS dotfiles — zsh, tmux, git, and a full developer toolchain.

This site documents the [`bradbergeron-us/dotfiles`](https://github.com/bradbergeron-us/dotfiles)
repository. For the canonical, always-current overview, see the
[README on GitHub](https://github.com/bradbergeron-us/dotfiles#readme).

## Quick start

```sh
git clone https://github.com/bradbergeron-us/dotfiles.git ~/dotfiles
bash ~/dotfiles/bootstrap.sh
```

`bootstrap.sh` runs once on a fresh Mac and handles everything: Homebrew, all
packages, runtimes (Ruby, Node, Java, Python, Go, Rust), dotfile symlinks, and
macOS defaults. Open a new terminal when it finishes.

Preview what would happen without changing anything:

```sh
bash ~/dotfiles/bootstrap.sh --dry-run
```

See [Dry-Run & Pre-flight](DRY_RUN_AND_PREFLIGHT.md) for details.

## Machine profiles

Each machine has a **profile** that selects which packages, dotfiles, and steps
apply:

- **`personal`** (default) — full GUI Mac: core CLI + GUI casks/fonts/apps + macOS defaults.
- **`work`** — `personal` plus the work overlay (extra tooling, work git/signing).
- **`minimal`** — core CLI toolchain + runtimes + core dotfiles only.
- **`server`** — headless macOS: core CLI + runtimes + core dotfiles, no GUI, no macOS defaults.

Show or set a machine's profile without re-bootstrapping:

```sh
bash ~/dotfiles/scripts/profile.sh           # show the active profile (aliased: dotprofile)
bash ~/dotfiles/scripts/profile.sh set work  # persist this machine's profile
```

The profile is stored at `~/.config/dotfiles/profile`. Precedence is
`--profile` flag > `DOTFILES_PROFILE` env > that file > `personal`.

## Keeping everything current

```sh
bash ~/dotfiles/update.sh              # pull, re-symlink, upgrade packages, health check
bash ~/dotfiles/update.sh --dry-run    # preview everything; change nothing
bash ~/dotfiles/update.sh --no-upgrade # pull + re-symlink + verify only
```

Other handy commands:

- `bash ~/dotfiles/verify.sh` — standalone health check.
- `bash ~/dotfiles/scripts/status.sh` — quick read-only snapshot (aliased `dotstatus`).
- `zsh ~/dotfiles/install.sh` — re-symlink without upgrading packages.

## Documentation

- **Guides**
    - [Profiles](profiles.md) — `minimal` / `personal` / `work` / `server` and how each is applied.
    - [Usage & Lifecycle](usage.md) — clone, bootstrap, update, verify, status, and scheduling.
    - [Contributing](contributing.md) — conventions, the bats-core test workflow, and CI.
- **Setup**
    - [Dry-Run & Pre-flight](DRY_RUN_AND_PREFLIGHT.md) — preview and validate before installing.
    - [GPG Commit Signing](GPG_SIGNING.md) — set up signed Git commits.
    - [Encrypted Secrets](secrets.md) — commit secrets safely with sops + age.
- **Work machine**
    - [Work Machine Setup](work-machine.md) — the layered work overlay approach.
    - [Complete Work Setup Guide](work-setup-complete.md) — full corporate-environment walkthrough.
    - [Claude Code SSL Fix](claude-code-ssl-fix.md) — corporate certificate workaround.
- **Reference**
    - [Tool Reference](tools.md) — every tool in the Brewfile, with rationale and usage.
    - [Shell Performance](performance.md) — how shell startup was cut by ~97%.
