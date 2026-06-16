# Getting started: your first hour

This tutorial takes a **brand-new Mac** from nothing to a fully managed
development environment, then shows you the everyday loop that keeps it healthy.
It is learning-oriented: follow it top to bottom and you will end with a
verified setup and the muscle memory for the daily commands.

Allow roughly an hour — most of that is unattended package and runtime
installation. Every command below maps to a real script in the repo, and the
output snippets are illustrative of what you will see.

!!! note "What you need first"
    A Mac running macOS 12 (Monterey) or later, an internet connection, and a
    GitHub account. You do **not** need Homebrew, Xcode, or any developer tools
    installed yet — `bootstrap.sh` installs them for you.

## Step 1 — Clone the repo

Clone into `~/dotfiles` (the path every script assumes):

```sh
git clone https://github.com/bradbergeron-us/dotfiles.git ~/dotfiles
```

!!! tip "No git yet?"
    A fresh Mac may not have `git`. Running any `git` command triggers Apple's
    "command line developer tools" installer — accept it, wait for it to finish,
    then re-run the clone. `bootstrap.sh` also installs the full Xcode Command
    Line Tools in Step 1 below.

## Step 2 — Run bootstrap

Kick off the one-time setup:

```sh
bash ~/dotfiles/bootstrap.sh
```

`bootstrap.sh` runs a **14-step** setup: Xcode Command Line Tools, Homebrew,
packages (`brew bundle`), fzf shell integration, an SSH signing key, GitHub CLI
auth, mise runtimes, Yarn via Corepack, Rust via rustup, git-lfs, dotfile
symlinks (it calls `install.sh`), optional work configs, and macOS defaults.

### The first-run profile picker

Because this is a genuine first run (no `--profile` flag, no `DOTFILES_PROFILE`
environment variable, no saved profile file, and an interactive terminal),
bootstrap greets you with the profile picker before doing anything:

```text
  This machine has no saved profile yet — pick one:

    1) personal  (default) — full GUI Mac: core + GUI apps/casks + macOS defaults
    2) work                — personal plus the work overlay & work configs
    3) minimal             — core CLI + runtimes + core dotfiles only
    4) server              — headless macOS: core CLI + runtimes, no GUI

  Profile [1-4 or name, Enter = personal]:
```

For your first personal Mac, press **Enter** to accept `personal`. You can type
a number (`1`–`4`) or a name (`personal`, `work`, `minimal`, `server`). The
choice is **persisted** to `~/.config/dotfiles/profile` so that `update.sh`,
`verify.sh`, and `status.sh` all agree on this machine's profile afterward.

!!! info "Skipping the picker"
    Pass the profile up front to bypass the prompt entirely:
    `bash ~/dotfiles/bootstrap.sh --profile work`. See the
    [Adopt a profile](adopt-profile.md) tutorial and the
    [Profiles reference](../profiles.md) for the full precedence rules.

### The component summary

Right after the profile is resolved, bootstrap prints a banner and a summary of
exactly what this profile will set up — derived from `profile_component_summary`
so it always matches what the steps actually do:

```text
  🚀  dotfiles bootstrap  —  macOS developer setup
  ─────────────────────────────────────────────────
  Machine  Brad's MacBook Pro
  Date     Mon Jun 16 2026  09:00
  Profile  personal
  ─────────────────────────────────────────────────
  This profile sets up
  Runtimes (mise)      yes
  Core CLI + dotfiles  yes
  Package overlay      core + GUI (Brewfile.personal)
  GUI apps + dotfiles  yes
  Work configs         no
  macOS defaults       yes
  ─────────────────────────────────────────────────
```

Use this as a sanity check: if the profile line or the component rows are not
what you expected, `Ctrl-C` now and re-run with the right `--profile`.

### What to expect during the steps

A few steps are interactive or long-running:

- **Pre-flight check** — validates the system first. Critical errors abort the
  run; warnings prompt you to continue (auto-continuing after 10 seconds).
- **SSH key for commit signing** — if you have no `~/.ssh/id_ed25519`, bootstrap
  generates one, copies the public key to your clipboard, and pauses with
  instructions to add it to GitHub as a **Signing Key** at
  `https://github.com/settings/ssh/new`. Press Enter once you have added it.
- **GitHub CLI auth** — if `gh` is installed but not logged in, it runs
  `gh auth login`.
- **Runtimes via mise** — installing runtimes can take 5–10 minutes (compiling
  from source). It prompts before installing and auto-continues after 10s.

When everything finishes you will see:

```text
  🎉  Bootstrap complete  in 18m 42s
  ─────────────────────────────────────────────────

  Next steps
  1. Edit ~/.zshrc.local with machine-specific config
  2. Open a new terminal  (or: source ~/.zshrc)
  3. Keep everything current: bash ~/dotfiles/update.sh
```

!!! tip "Preview without changing anything"
    Curious before you commit? `bash ~/dotfiles/bootstrap.sh --dry-run` walks
    through every step and the component preview without installing a thing (and
    without persisting a profile or showing the picker). See
    [Dry-Run & Pre-flight](../DRY_RUN_AND_PREFLIGHT.md).

## Step 3 — Open a new shell

The dotfiles set up zsh, the starship prompt, and dozens of tools. Pick up the
new configuration by opening a new terminal tab, or reload in place:

```sh
exec zsh
```

You should now have a starship prompt and aliases like `dotstatus` available.

## Step 4 — Verify the setup

Confirm the environment is healthy with the read-only health check:

```sh
bash ~/dotfiles/verify.sh
```

`verify.sh` covers **nine** areas: symlinks, required tools, stale backups, the
SSH key, git-lfs, mise runtimes, dotfiles git health, Brewfile drift, and the
git config include. A clean run ends with:

```text
  ✅  All checks passed  (3s)
```

Only broken symlinks are treated as an error (exit `1`); everything else is a
non-blocking warning. If you see warnings, the message tells you how to fix
them — for example `missing: <tool> — run: bash ~/dotfiles/bootstrap.sh`.

For an even faster look, use the status snapshot (aliased to `dotstatus`):

```sh
dotstatus
```

```text
  🩺  dotfiles status
  ─────────────────────────────────────────────────
  Profile     personal
  Repo        ~/dotfiles
  Branch      main  (clean)
  Upstream    in sync
  ─────────────────────────────────────────────────
  No update.status yet — run:  bash ~/dotfiles/update.sh
```

`dotstatus` shows the active profile, the repo's git state, and the result of
the last `update.sh` run. Right after bootstrap there is no update status yet —
that is expected.

## Step 5 — The daily loop

From here on, one command keeps everything current:

```sh
bash ~/dotfiles/update.sh
```

`update.sh` runs **seven** self-healing steps: pull the dotfiles
(`git pull --rebase --autostash`), re-run `install.sh` to pick up new symlinks,
upgrade Homebrew, upgrade mise runtimes, update Rust, update Ruby gems, and
finally run `verify.sh`. An individual step failing never aborts the run —
failures are collected and reported at the end:

```text
  ✅  Update complete  in 1m 12s
```

After an update, `dotstatus` reflects the last run:

```text
  Last update 2026-06-16T16:00:00Z
  ✓ result: success  (72s)
```

!!! tip "Make it automatic"
    Schedule a daily run with launchd:
    `bash ~/dotfiles/scripts/setup-scheduler.sh` (runs at 9 AM). See
    [Usage & lifecycle](../usage.md#scheduling-daily-updates-setup-schedulersh)
    for scheduler options and per-machine defaults.

## You're set up

You now have a verified environment and the everyday loop:

- `bash ~/dotfiles/update.sh` — pull, re-symlink, upgrade, verify.
- `dotstatus` — a quick read-only snapshot.
- `bash ~/dotfiles/verify.sh` — the full health check on demand.

## Where to next

- [Set up a work laptop](work-laptop.md) — the guided `work`-profile flow with
  corporate configs, secrets, and commit signing.
- [Adopt a profile on an existing machine](adopt-profile.md) — switch profiles
  without re-bootstrapping.
- [Profiles reference](../profiles.md) — how profiles gate every component.
- [Usage & lifecycle](../usage.md) — the complete command and flag reference.
