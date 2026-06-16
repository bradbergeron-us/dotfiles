# Contributing

A maintainer-facing guide to how this repository is wired together and the conventions to follow when changing it. For day-to-day usage (install, update, the tool list), see the [README](README.md).

## Lifecycle

Four entry-point scripts form the pipeline; everything in `scripts/` exists to support them.

1. **`bootstrap.sh`** (bash) — one-time setup on a fresh Mac. Runs `scripts/preflight.sh` first (unless `--skip-preflight` or `--dry-run`), installs Homebrew and the `Brewfile`, language runtimes via `mise`, Yarn via Corepack (from the mise-managed Node), Rust via `rustup`, and `git-lfs`, then hands off to `install.sh` for symlinks, and finally prompts for work configs (`scripts/setup_work_configs.sh`) and macOS defaults (`scripts/macos.sh`). Supports `--dry-run` and `--skip-preflight`. Also accepts `--profile <name>` (`minimal`/`personal`/`work`/`server`), resolved via `scripts/lib/profile_helpers.sh` and persisted to `~/.config/dotfiles/profile`; `scripts/profile.sh` shows/sets a machine's profile without a re-bootstrap. Profile *gating* of packages/symlinks/steps is layered in later — today the profile is recorded but does not yet change what's installed.
2. **`install.sh`** (zsh) — the symlinker. Links every tracked dotfile (per `config/symlinks.map`) into `$HOME`, backing up any pre-existing real file to `~/.dotfiles_backup/<timestamp>/`. It also writes a thin `~/.gitconfig` that *includes* the tracked `home/gitconfig` (a real file, not a symlink, so `git config --global` and tools like `gh auth setup-git` never write into the repo), seeds `~/.config/git/local.gitconfig` from `home/examples/gitconfig.local.example`, and installs a global pre-commit hook at `~/.config/git/hooks/pre-commit`. Idempotent: a second run relinks nothing already correct and reports `linked / current / backed up`.
3. **`update.sh`** (bash) — keep-current. `git pull --rebase --autostash`, re-runs `install.sh` to pick up new symlinks, upgrades Homebrew / `mise` / `rustup` / gems / `uv` tools, then runs `verify.sh`. Schedulable via `scripts/setup-scheduler.sh` (launchd, daily at 9 AM). Flags for determinism/safety: `--dry-run` (preview, no changes), `--no-upgrade` (pull + re-symlink + verify only; also via `DOTFILES_UPDATE_NO_UPGRADE=1`), `--no-pull` / `--force-pull`. It skips the pull when the repo work tree is dirty (unless `--force-pull`, see `working_tree_dirty`) and aborts a failed rebase (`rebase_in_progress`) so the repo is left as it was. In `--dry-run` it writes no status file, rotates no logs, and posts no notification. Per-machine defaults live in `~/.config/dotfiles/update.conf` (parsed by `read_config_bool`, so the launchd job honors them even though launchd does not source your shell rc); `scripts/setup-scheduler.sh --no-upgrade` / `--no-pull` bake the corresponding flag into the plist's `ProgramArguments` (via the `__UPDATE_ARGS__` marker).
4. **`verify.sh`** (bash) — health check. Nine checks: symlinks, required tools, stale backups, SSH key, global git-lfs init, mise-installed runtimes, dotfiles git health, Brewfile drift, and git config include. Broken symlinks are the only hard error (exit 1); everything else is a warning (exit 0).

```
bootstrap.sh ──▶ install.sh ──▶ update.sh ──▶ verify.sh
  (preflight)    (symlinks +     (re-link +     (health
                  backups)        upgrades)       check)
```

## Layout

- **Root** — the four entry-point scripts (`bootstrap.sh`, `install.sh`, `update.sh`, `verify.sh`), package manifests (`Brewfile`, `Brewfile.work`), and repo meta (`README.md`, `CONTRIBUTING.md`).
- **`home/`** — the tracked dotfiles symlinked into `$HOME` (`zshrc`, `zprofile`, `tmux.conf`, …); `home/examples/` holds the `*.local.example` templates. (`gitconfig` lives here too but is loaded via a thin `~/.gitconfig` include rather than symlinked, so global writes never touch the repo.)
- **`scripts/`** — the secondary entry scripts (`macos.sh`, `setup-scheduler.sh`, `uninstall.sh`, `quick-fix.sh`) and supporting/work-setup scripts. Sourced helper libraries live in **`scripts/lib/`** and unit tests in **`scripts/tests/`** (see below). Has its own [README](scripts/README.md).
- **`config/`** — XDG configs symlinked under `~/.config` (`starship.toml`, `mise.toml`, `direnvrc`).
- **`templates/`** — work / secret-bearing configs shipped as `*.template` placeholders (see [templates/README.md](templates/README.md)).
- **`docs/`** — long-form documentation. **`.github/workflows/`** — CI.
- **`system/`** — macOS / setup assets: `LaunchAgents/` (the launchd plist), plus the git-ignored `certs/` (SSL certs) and `installers/` (cached binaries).

## Helpers

- **`scripts/lib/bootstrap_helpers.sh`** — sourced by `bootstrap.sh`, `update.sh`, and `verify.sh`. Side-effect-free output helpers (`setup_colors`, `step`, `info`, `success`, `warn`; call `setup_colors` once after sourcing) plus `parse_mise_runtimes`, which reads the `[tools]` table of `config/mise.toml` — the single source of truth for runtime versions.
- **`scripts/lib/verify_helpers.sh`** — sourced by `verify.sh`. Pure check functions (`check_symlinks`, `check_required_tools`, `check_ssh_key`, `check_git_lfs_global`, `check_mise_installed`, `check_stale_backups`, `check_dotfiles_git_health`, `check_brewfile_drift`, `check_gitconfig_include`). Each sets result globals (e.g. `SYMLINK_BROKEN_COUNT`, `SYMLINK_BROKEN_LIST`) rather than printing or exiting, which makes them unit-testable. `load_symlink_map` populates the `DOTFILES_SYMLINKS` array from `config/symlinks.map`, the canonical symlink manifest (see below).
- **`scripts/lib/dryrun_helpers.sh`** — sourced by `bootstrap.sh` only when `--dry-run` is set. Provides `dry_run_step`, per-step `check_*` previews (including `check_corepack`) that record intended actions via `dry_run_log`, and `show_dry_run_summary`.
- **`scripts/preflight.sh`** — standalone (defines its own colors and `error`/`warn`/`success`/`info`). Validates the system before bootstrap.

## Dry-run and pre-flight

Two independent safety layers; full user-facing detail is in [docs/DRY_RUN_AND_PREFLIGHT.md](docs/DRY_RUN_AND_PREFLIGHT.md).

- **Pre-flight** (`scripts/preflight.sh`) — read-only system checks (OS, arch, disk, network, permissions, existing dotfiles, …). Exit codes: `0` ready, `1` critical failure, `2` warnings only; `--strict` promotes warnings to failure. `bootstrap.sh` runs it automatically and aborts on exit 1.
- **Dry-run** (`bootstrap.sh --dry-run`) — sources `dryrun_helpers.sh` and reports what each step *would* do without changing anything, ending in a numbered summary. When you change a real bootstrap step, update its matching `check_*` preview in `dryrun_helpers.sh` in lockstep so dry-run stays honest.

## Tests

Unit tests use [bats-core](https://github.com/bats-core/bats-core) and live in `scripts/tests/test_*.bats`. Install bats with `brew install bats-core` (it's already in the `Brewfile`), then run the whole suite from the repo root:

```bash
bats scripts/tests/
```

You can also run a single file, e.g. `bats scripts/tests/test_verify_helpers.bats`.

Convention (see `scripts/tests/test_verify_helpers.bats` for the reference implementation):

- Every file is `#!/usr/bin/env bats` and starts with `load 'test_helper'`, which sources `scripts/tests/test_helper.bash` to expose `$LIB_DIR` / `$SCRIPTS_DIR` / `$REPO_ROOT`.
- Write each case as a `@test "description" { ... }` block; a non-zero command inside the block fails the test.
- Use the per-test scratch dir `$BATS_TEST_TMPDIR` for fixtures (bats creates and removes it automatically — no `mktemp -d` or `trap` cleanup needed).
- Source the helper under test once at the file's top level (or in `setup()`), and assert on the result globals it sets.
- Add new tests as `@test` blocks in the `*.bats` file next to the helper they cover; both CI and `bats scripts/tests/` auto-discover them, so no workflow edits are needed.

Because the helpers are side-effect-free, tests exercise them directly against temporary `$HOME` / fixture directories.

## CI

- **`.github/workflows/ci.yml`** — three jobs: `shellcheck` (bash scripts, `-S warning`), `zsh-syntax` (`zsh -n` on the zsh files plus a `Brewfile` parse check), and `install-smoke` (runs `zsh install.sh` against a throwaway `$HOME` and asserts every expected symlink exists).
- **`.github/workflows/test-bootstrap.yml`** — installs bats-core and runs the full `scripts/tests/*.bats` suite (auto-discovered via `bats scripts/tests/`), plus `bash -n` syntax checks on the scripts under test and a `bats --count` parse-check of every `.bats` file, when the relevant scripts change.
- **`.github/workflows/release.yml`** — release automation (see [Releasing](#releasing)).

## Releasing

Releases are automated with [release-please](https://github.com/googleapis/release-please-action) — there is no manual tagging or hand-editing of `CHANGELOG.md`. Versioning follows [Semantic Versioning](https://semver.org/) and the changelog stays in [Keep a Changelog](https://keepachangelog.com/) format.

The flow, driven by Conventional Commits:

1. **Land PRs with Conventional-Commit titles/commits** on `main` (`feat:` → minor bump, `fix:` → patch bump, `feat!:`/`fix!:` or a `BREAKING CHANGE:` footer → major bump; `chore:`/`docs:`/`ci:`/etc. don't trigger a release on their own).
2. **release-please opens (and keeps updating) a release PR** titled like `chore: release 1.2.0`. That PR rolls up everything since the last release: it bumps the version, prepends a new `CHANGELOG.md` section, and updates `.release-please-manifest.json`. It refreshes automatically as more PRs land.
3. **Merge the release PR** when you're ready to cut the release. Merging it tags the commit (`vX.Y.Z`) and publishes the matching GitHub release with the generated notes.

Configuration lives in `release-please-config.json` (release strategy `simple` — this is a shell/dotfiles repo, not a language package — with a `v` tag prefix and `CHANGELOG.md` as the managed changelog) and `.release-please-manifest.json` (the current released version, seeded at `1.1.0`). The workflow runs on every push to `main` using the default `GITHUB_TOKEN`. The handwritten `1.0.0`/`1.1.0` history is preserved; release-please appends new entries above it.

To force a specific version (e.g. an out-of-band `1.2.0`), add a `Release-As: 1.2.0` footer to a commit on `main`; manual `git tag` pushes are no longer the release path.

## Common tasks

### Add a managed dotfile

The dotfile→destination mapping is a single source of truth in `config/symlinks.map`; `install.sh`, `verify.sh`, `bootstrap.sh --dry-run`, and the CI install-smoke job all read it. To track a new dotfile:

1. Add the file to the repo (`home/`, or `config/` for XDG configs).
2. **`config/symlinks.map`** — add one `src  dest [tags]` line (src relative to the repo root, dest relative to `$HOME`; an optional comma-separated profile-tag column — e.g. `gui` for GUI-only configs — controls which profiles get the link, see `scripts/lib/profile_helpers.sh`). Every consumer picks it up automatically — no other script or workflow needs editing.
3. **`README.md`** — add a row to the Dotfiles table (human-readable reference).

Non-symlink setup (the thin `~/.gitconfig` include, the `~/.config/git/local.gitconfig` seed, the global pre-commit hook, and VS Code settings/extensions) is intentionally bespoke in `install.sh` and is deliberately not part of the manifest.

### Add a configuration template

Templates exist for configs that can't be committed verbatim because they carry environment-specific or secret values. See [templates/README.md](templates/README.md).

1. Add `templates/<area>/<file>.template` (or a top-level `*.template`).
2. **Placeholders only** — never commit real secrets, tokens, keys, or internal URLs. Use obvious placeholders such as `REPLACE_WITH_YOUR_USERNAME`, `your-org.example.com`, or `{encrypted-password-here}`, to be replaced after the file is copied into place.
3. Document it: add a short README in the template directory and a row to the index table in `templates/README.md`.
4. If it is part of work-machine setup, wire copying into `scripts/setup_work_configs.sh`.

### Add a verify check

Add a side-effect-free `check_*` function to `scripts/lib/verify_helpers.sh` that sets result globals, add `@test` cases for it to `scripts/tests/test_verify_helpers.bats`, then wire a `step` + report block into `verify.sh`.

## Before you commit

- Run `shellcheck -S warning <script>` on any bash you touched, and `zsh -n <file>` on zsh files (`install.sh`, `scripts/setup_gpg_signing.sh`, `home/zshrc`, `home/zprofile`).
- Run the bats suite with `bats scripts/tests/` (install via `brew install bats-core` if needed).
- For changes to install/verify behavior, exercise them against an isolated `HOME=$(mktemp -d)`.
- New bash scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`, and reuse `scripts/lib/bootstrap_helpers.sh` for output.
- A repo-local pre-commit hook runs when `pre-commit` is installed and a `.pre-commit-config.yaml` is present.
