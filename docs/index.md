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

`bootstrap.sh` runs once on a fresh Mac: Homebrew, all packages, runtimes (Ruby,
Node, Java, Python, Go, Rust), dotfile symlinks, and — on a first interactive
run — a prompt for this machine's [profile](profiles.md). Open a new terminal
when it finishes.

Preview without changing anything: `bash ~/dotfiles/bootstrap.sh --dry-run`
(see [Dry-Run & Pre-flight](DRY_RUN_AND_PREFLIGHT.md)).

**New here?** Walk through the [Getting Started tutorial](tutorials/getting-started.md)
for a guided first hour.

## Find your way around

This documentation follows the [Diátaxis](https://diataxis.fr) model — pick the
lane that matches what you need.

### Tutorials — learn by doing

- [Getting started: your first hour](tutorials/getting-started.md)
- [Set up a work laptop](tutorials/work-laptop.md)
- [Adopt a profile on an existing machine](tutorials/adopt-profile.md)

### How-to guides — accomplish a task

- [Add a tracked dotfile](how-to/add-a-dotfile.md)
- [Manage packages](how-to/manage-packages.md)
- [Manage secrets](how-to/manage-secrets.md)
- [Add a zsh plugin](how-to/add-a-zsh-plugin.md)
- [Write a test](how-to/write-a-test.md)
- [Schedule updates](how-to/schedule-updates.md)
- [Recover from a failed update](how-to/recover-from-a-failed-update.md)

### Reference — look something up

- [Machine profiles](profiles.md) and [Usage & lifecycle](usage.md)
- [Tool reference](tools.md) and [Shell performance](performance.md)
- [Troubleshooting](troubleshooting.md)
- Setup: [Dry-run & pre-flight](DRY_RUN_AND_PREFLIGHT.md) · [GPG commit signing](GPG_SIGNING.md) · [Encrypted secrets](secrets.md)
- Work machine: [Overview](work-machine.md) · [Complete setup guide](work-setup-complete.md) · [Claude Code SSL fix](claude-code-ssl-fix.md)

### Explanation — understand how it fits

- [Architecture](architecture.md) — how bootstrap, install, update, verify, status, and profiles fit together.
- [Glossary](glossary.md) — terms used across these docs.

## Contributing

See [Contributing](contributing.md) for repo conventions, the bats-core test
workflow, and CI.
