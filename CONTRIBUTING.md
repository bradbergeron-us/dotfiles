# Contributing

A maintainer-facing guide to how this repository is wired together and the conventions to follow when changing it. For day-to-day usage (install, update, the tool list), see the [README](README.md).

## Lifecycle

Four entry-point scripts form the pipeline; everything in `scripts/` exists to support them.

1. **`bootstrap.sh`** (bash) — one-time setup on a fresh Mac. Runs `scripts/preflight.sh` first (unless `--skip-preflight` or `--dry-run`), installs Homebrew and the `Brewfile`, language runtimes via `mise`, Rust via `rustup`, and `git-lfs`, then hands off to `install.sh` for symlinks, and finally prompts for work configs (`scripts/setup_work_configs.sh`) and macOS defaults (`macos.sh`). Supports `--dry-run` and `--skip-preflight`.
2. **`install.sh`** (zsh) — the symlinker. Links every tracked dotfile into `$HOME`, backing up any pre-existing real file to `~/.dotfiles_backup/<timestamp>/`. It also seeds `~/.config/git/local.gitconfig` from `home/examples/gitconfig.local.example` and installs a global pre-commit hook at `~/.config/git/hooks/pre-commit`. Idempotent: a second run relinks nothing already correct and reports `linked / current / backed up`.
3. **`update.sh`** (bash) — keep-current. `git pull --rebase --autostash`, re-runs `install.sh` to pick up new symlinks, upgrades Homebrew / `mise` / `rustup` / gems / `uv` tools, then runs `verify.sh`. Schedulable via `setup-scheduler.sh` (launchd, daily at 9 AM).
4. **`verify.sh`** (bash) — health check. Seven checks: symlinks, `mise.toml` vs `bootstrap.sh` version drift, required tools, stale backups, SSH key, global git-lfs init, and mise-installed runtimes. Broken symlinks are the only hard error (exit 1); everything else is a warning (exit 0).

```
bootstrap.sh ──▶ install.sh ──▶ update.sh ──▶ verify.sh
  (preflight)    (symlinks +     (re-link +     (health
                  backups)        upgrades)       check)
```

## Layout

- **Root** — entry scripts (`bootstrap.sh`, `install.sh`, `update.sh`, `verify.sh`, `setup-scheduler.sh`, `macos.sh`).
- **`home/`** — the tracked dotfiles symlinked into `$HOME` (`zshrc`, `zprofile`, `gitconfig`, `tmux.conf`, …); `home/examples/` holds the `*.local.example` templates.
- **`scripts/`** — helpers, supporting/work-setup scripts, and unit tests (see below). Has its own [README](scripts/README.md).
- **`config/`** — XDG configs symlinked under `~/.config` (`starship.toml`, `mise.toml`, `direnvrc`).
- **`templates/`** — work / secret-bearing configs shipped as `*.template` placeholders (see [templates/README.md](templates/README.md)).
- **`docs/`** — long-form documentation. **`.github/workflows/`** — CI.

## Helpers

- **`scripts/bootstrap_helpers.sh`** — sourced by `bootstrap.sh`, `update.sh`, and `verify.sh`. Side-effect-free output helpers: `setup_colors`, `step`, `info`, `success`, `warn`. Call `setup_colors` once after sourcing.
- **`scripts/verify_helpers.sh`** — sourced by `verify.sh`. Pure check functions (`check_symlinks`, `check_mise_version_drift`, `check_required_tools`, `check_ssh_key`, `check_git_lfs_global`, `check_mise_installed`, `check_stale_backups`). Each sets result globals (e.g. `SYMLINK_BROKEN_COUNT`, `SYMLINK_BROKEN_LIST`) rather than printing or exiting, which makes them unit-testable. The canonical symlink map lives here as the `DOTFILES_SYMLINKS` array.
- **`scripts/dryrun_helpers.sh`** — sourced by `bootstrap.sh` only when `--dry-run` is set. Provides `dry_run_step`, per-step `check_*` previews that record intended actions via `dry_run_log`, and `show_dry_run_summary`.
- **`scripts/preflight.sh`** — standalone (defines its own colors and `error`/`warn`/`success`/`info`). Validates the system before bootstrap.

## Dry-run and pre-flight

Two independent safety layers; full user-facing detail is in [docs/DRY_RUN_AND_PREFLIGHT.md](docs/DRY_RUN_AND_PREFLIGHT.md).

- **Pre-flight** (`scripts/preflight.sh`) — read-only system checks (OS, arch, disk, network, permissions, existing dotfiles, …). Exit codes: `0` ready, `1` critical failure, `2` warnings only; `--strict` promotes warnings to failure. `bootstrap.sh` runs it automatically and aborts on exit 1.
- **Dry-run** (`bootstrap.sh --dry-run`) — sources `dryrun_helpers.sh` and reports what each step *would* do without changing anything, ending in a numbered summary. When you change a real bootstrap step, update its matching `check_*` preview in `dryrun_helpers.sh` in lockstep so dry-run stays honest.

## Tests

Tests are plain bash scripts under `scripts/test_*.sh` — there is no test framework. Run one directly:

```bash
bash scripts/test_verify_helpers.sh
bash scripts/test_bootstrap_helpers.sh
```

Convention (see `scripts/test_verify_helpers.sh` for the reference implementation):

- `set -euo pipefail`; `pass` / `fail` helpers that increment run/pass/fail counters.
- Build fixtures under a single `mktemp -d` directory and clean it up with `trap '...' EXIT`.
- Source the helper under test inside a subshell `( ... )` so its globals don't leak between cases.
- Assert on the result globals the helper sets, and `exit 1` at the end if any test failed.

Because the helpers are side-effect-free, tests exercise them directly against temporary `$HOME` / fixture directories.

## CI

- **`.github/workflows/ci.yml`** — three jobs: `shellcheck` (bash scripts, `-S warning`), `zsh-syntax` (`zsh -n` on the zsh files plus a `Brewfile` parse check), and `install-smoke` (runs `zsh install.sh` against a throwaway `$HOME` and asserts every expected symlink exists).
- **`.github/workflows/test-bootstrap.yml`** — runs the `scripts/test_*.sh` unit tests (currently `test_bootstrap_helpers.sh` and `test_verify_helpers.sh`) plus `bash -n` syntax checks when the relevant scripts change.

## Common tasks

### Add a managed dotfile

A tracked dotfile is represented in several independent lists. Update all of them so install, verify, dry-run, CI, and the docs stay in agreement:

1. Add the file to the repo (`home/`, or `config/` for XDG configs).
2. **`install.sh`** — add a `symlink "$DOTFILES_DIR/home/<src>" "$HOME/<dest>"` line.
3. **`scripts/verify_helpers.sh`** — add `"home/<src>:<dest>"` to the `DOTFILES_SYMLINKS` array so `verify.sh` checks it.
4. **`scripts/dryrun_helpers.sh`** — add the same pair to the list in `check_dotfile_symlinks` so `--dry-run` previews it.
5. **`README.md`** — add a row to the Dotfiles table.
6. **`.github/workflows/ci.yml`** — add the destination to the install-smoke symlink list so the smoke test verifies it.

### Add a configuration template

Templates exist for configs that can't be committed verbatim because they carry environment-specific or secret values. See [templates/README.md](templates/README.md).

1. Add `templates/<area>/<file>.template` (or a top-level `*.template`).
2. **Placeholders only** — never commit real secrets, tokens, keys, or internal URLs. Use obvious placeholders such as `REPLACE_WITH_YOUR_USERNAME`, `your-org.example.com`, or `{encrypted-password-here}`, to be replaced after the file is copied into place.
3. Document it: add a short README in the template directory and a row to the index table in `templates/README.md`.
4. If it is part of work-machine setup, wire copying into `scripts/setup_work_configs.sh`.

### Add a verify check

Add a side-effect-free `check_*` function to `scripts/verify_helpers.sh` that sets result globals, add cases for it to `scripts/test_verify_helpers.sh`, then wire a `step` + report block into `verify.sh`.

## Before you commit

- Run `shellcheck -S warning <script>` on any bash you touched, and `zsh -n <file>` on zsh files (`install.sh`, `scripts/setup_gpg_signing.sh`, `home/zshrc`, `home/zprofile`).
- Run the relevant `scripts/test_*.sh`.
- For changes to install/verify behavior, exercise them against an isolated `HOME=$(mktemp -d)`.
- New bash scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`, and reuse `scripts/bootstrap_helpers.sh` for output.
- A repo-local pre-commit hook runs when `pre-commit` is installed and a `.pre-commit-config.yaml` is present.
