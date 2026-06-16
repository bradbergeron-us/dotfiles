# Contributing

How this repository is wired together and the conventions to follow when changing it. For day-to-day usage — install, [profiles](profiles.md), the [lifecycle commands](usage.md) — start there; this page is the maintainer-facing companion to [`CONTRIBUTING.md`](https://github.com/bradbergeron-us/dotfiles/blob/main/CONTRIBUTING.md).

## Repository layout

- **Root** — the four entry-point scripts (`bootstrap.sh`, `install.sh`, `update.sh`, `verify.sh`), package manifests (`Brewfile`, `Brewfile.work`), and repo meta (`README.md`, `CONTRIBUTING.md`).
- **`home/`** — the tracked dotfiles symlinked into `$HOME` (`zshrc`, `zprofile`, `tmux.conf`, …); `home/examples/` holds the `*.local.example` templates. (`gitconfig` lives here too but is loaded via a thin `~/.gitconfig` include rather than symlinked, so global writes never touch the repo.)
- **`scripts/`** — the secondary entry scripts (`macos.sh`, `setup-scheduler.sh`, `uninstall.sh`, `quick-fix.sh`) and supporting/work-setup scripts. Sourced helper libraries live in **`scripts/lib/`** and unit tests in **`scripts/tests/`**.
- **`config/`** — XDG configs symlinked under `~/.config` (`starship.toml`, `mise.toml`, `direnvrc`), plus `config/symlinks.map`, the canonical symlink manifest (see below).
- **`templates/`** — work / secret-bearing configs shipped as `*.template` placeholders.
- **`docs/`** — this MkDocs site. **`.github/workflows/`** — CI.
- **`system/`** — macOS / setup assets: `LaunchAgents/` (the launchd plist), plus the git-ignored `certs/` and `installers/`.

## Adding a tracked dotfile

The dotfile→destination mapping is a **single source of truth** in `config/symlinks.map`; `install.sh`, `verify.sh`, `bootstrap.sh --dry-run`, and the CI install-smoke job all read it. To track a new dotfile:

1. Add the file to the repo (`home/`, or `config/` for XDG configs).
2. **`config/symlinks.map`** — add one `src  dest [tags]` line. `src` is relative to the repo root, `dest` is relative to `$HOME`, and the optional comma-separated profile-tag column (e.g. `gui` for GUI-only configs) controls which [profiles](profiles.md) get the link, via `scripts/lib/profile_helpers.sh`. Every consumer picks it up automatically — no other script or workflow needs editing.
3. **`README.md`** — add a row to the Dotfiles table (human-readable reference).

Non-symlink setup (the thin `~/.gitconfig` include, the `~/.config/git/local.gitconfig` seed, the global pre-commit hook, and VS Code settings/extensions) is intentionally bespoke in `install.sh` and is deliberately not part of the manifest.

## Bootstrap steps, dry-run, and `TOTAL_STEPS`

`bootstrap.sh` is the one-time installer. It prints numbered progress as `[n/TOTAL_STEPS]`, where `TOTAL_STEPS` is a constant near the top of `bootstrap.sh` and the `step()` / `dry_run_step()` helpers consume it. Two rules keep this honest when you add or change a step:

- **Bump the counter.** When you add a real step, increment `TOTAL_STEPS` so the `[n/m]` banner stays accurate (and decrement it if you remove one).
- **Keep the dry-run preview in lockstep.** `bootstrap.sh --dry-run` sources `scripts/lib/dryrun_helpers.sh` and reports what each step *would* do without changing anything, ending in a numbered summary. Every real step has a matching `check_*` preview (e.g. `check_homebrew`, `check_corepack`); when you change a real step, update its preview so dry-run never drifts from reality.

See [Dry-Run & Pre-flight](DRY_RUN_AND_PREFLIGHT.md) for the user-facing detail, and the `bootstrap-dryrun.yml` CI job below, which exercises `--dry-run` across profiles on every PR.

## Shell-script conventions

- New bash scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Reuse the shared helpers in **`scripts/lib/bootstrap_helpers.sh`** for output (`setup_colors`, `step`, `info`, `success`, `warn`; call `setup_colors` once after sourcing) instead of re-rolling colors and logging. Pure check functions for `verify.sh` live in `scripts/lib/verify_helpers.sh`, and the dry-run previews in `scripts/lib/dryrun_helpers.sh`.
- Keep helpers **side-effect-free** — set result globals rather than printing or exiting — so they stay unit-testable.
- `install.sh`, `home/zshrc`, and `home/zprofile` are zsh; everything else is bash.

## Testing with bats-core

Unit tests use [bats-core](https://github.com/bats-core/bats-core) and live in `scripts/tests/test_*.bats`. Install bats with `brew install bats-core` (it's already in the `Brewfile`), then run the whole suite from the repo root:

```bash
bats scripts/tests/
```

You can also run a single file, e.g. `bats scripts/tests/test_verify_helpers.bats`.

Conventions (see `scripts/tests/test_verify_helpers.bats` for the reference implementation):

- Every file is `#!/usr/bin/env bats` and starts with `load 'test_helper'`, which sources `scripts/tests/test_helper.bash` to expose `$LIB_DIR` / `$SCRIPTS_DIR` / `$REPO_ROOT`.
- Write each case as a `@test "description" { ... }` block; a non-zero command inside the block fails the test.
- Use the per-test scratch dir `$BATS_TEST_TMPDIR` for fixtures (bats creates and removes it automatically — no `mktemp -d` or `trap` cleanup needed).
- Source the helper under test once at the file's top level (or in `setup()`), and assert on the result globals it sets.
- Add new tests as `@test` blocks in the `*.bats` file next to the helper they cover; both CI and `bats scripts/tests/` auto-discover them, so no workflow edits are needed.

## Static checks before you commit

- Run `shellcheck -S warning <script>` on any bash you touched.
- Run `zsh -n <file>` on zsh files (`install.sh`, `home/zshrc`, `home/zprofile`, …).
- Run the bats suite with `bats scripts/tests/`.
- For changes to install/verify behavior, exercise them against an isolated `HOME=$(mktemp -d)`.
- A repo-local pre-commit hook runs when `pre-commit` is installed and a `.pre-commit-config.yaml` is present; `gitleaks` scans for accidentally committed secrets in both pre-commit and CI.

## Continuous integration

Four workflows run under `.github/workflows/`:

- **`ci.yml`** — three jobs: `shellcheck` (bash scripts, `-S warning`), `zsh-syntax` (`zsh -n` on the zsh files plus a `Brewfile` parse check), and `install-smoke` (runs `zsh install.sh` against a throwaway `$HOME` and asserts every expected symlink exists).
- **`test-bootstrap.yml`** — installs bats-core and runs the full `scripts/tests/*.bats` suite (auto-discovered via `bats scripts/tests/`), plus `bash -n` syntax checks and a `bats --count` parse-check of every `.bats` file, when the relevant scripts change.
- **`bootstrap-dryrun.yml`** — exercises `bootstrap.sh --dry-run` (which installs nothing) to prove profile gating still behaves: a cheap PR-time guardrail over the `personal` and `minimal` profiles, plus a nightly/manual sweep across all four profiles, asserting exit 0 and the expected gated previews.
- **`docs.yml`** — builds this site with `mkdocs build --strict` on every PR, and on pushes to `main` deploys it to GitHub Pages.

## Pull requests and commits

- **Templates.** New PRs follow `.github/pull_request_template.md` (Summary / Type / Validation / Checklist). Issues use the forms under `.github/ISSUE_TEMPLATE/` (`bug_report.md`, `feature_request.md`).
- **Conventional commits.** Use `type(scope): subject` — e.g. `feat(profiles): add server profile`, `fix(update): abort failed rebase`, `docs(contributing): mirror CONTRIBUTING.md`. Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`.
- **Attribution.** When a change is co-authored (including with an agent), end the commit message with a trailing line:

  ```
  Co-Authored-By: Oz <oz-agent@warp.dev>
  ```

- **Docs PRs** must keep `mkdocs build --strict` clean: new pages belong in the `mkdocs.yml` nav, and links between pages should be relative (e.g. `profiles.md`) so they resolve both in-repo and on the published site.
