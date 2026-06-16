# Troubleshooting

Common failures and how to fix them. Most problems surface through
[`verify.sh`](architecture.md#verifysh-read-only-health-check) or the summary at
the end of an `update.sh` run. When in doubt, start with the health check:

```sh
bash ~/dotfiles/verify.sh
bash ~/dotfiles/scripts/status.sh   # quick repo + last-update snapshot (dotstatus)
```

## FAQ

??? question "How do I change my machine's profile without re-bootstrapping?"
    Use the `dotprofile` alias, then re-apply:
    ```sh
    dotprofile set work          # persist the new profile
    zsh ~/dotfiles/install.sh    # re-link dotfiles for it
    bash ~/dotfiles/update.sh    # re-run packages + health check
    ```
    See [Machine Profiles](profiles.md).

??? question "Is it safe to re-run bootstrap / install / update?"
    Yes. All of them are idempotent — already-installed tools are skipped and
    correct symlinks are left alone. Re-running is the normal way to heal a
    machine.

??? question "Where are my old dotfiles after bootstrap?"
    `install.sh` backs up any real file it replaces to
    `~/.dotfiles_backup/<timestamp>/`. `verify.sh` warns when backups are older
    than 30 days; clear them with `rm -rf ~/.dotfiles_backup`.

??? question "Why didn't my change to ~/.zshrc stick?"
    `~/.zshrc` is a symlink into the repo. Machine-specific config belongs in
    `~/.zshrc.local` (seeded from a template on first bootstrap), which is not
    tracked.

## Failed update or rebase

`update.sh` pulls with `git pull --rebase --autostash`. It is defensive by
design:

- **Uncommitted changes in the dotfiles repo** → the pull step is **skipped**
  with a warning so it never starts a rebase it can't finish. Commit or stash
  your work, or force it:
  ```sh
  cd ~/dotfiles && git status        # see what's uncommitted
  git stash                          # or commit
  bash ~/dotfiles/update.sh
  # or, to pull over local changes (autostash):
  bash ~/dotfiles/update.sh --force-pull
  ```
- **A pull that fails mid-rebase** → `update.sh` automatically runs
  `git rebase --abort`, leaving the repo exactly as it was. Resolve manually:
  ```sh
  cd ~/dotfiles
  git rebase --abort                 # if a rebase is still in progress
  git pull --rebase --autostash      # re-attempt once the tree is clean
  ```
- **A failed step does not abort the run.** `update.sh` collects failures and
  reports them in the final banner and in `logs/update.status`. Inspect details
  with:
  ```sh
  bash ~/dotfiles/scripts/status.sh  # shows last result + failed steps
  cat ~/dotfiles/logs/update.log     # full output (rotated, keeps 5 copies)
  ```

## Broken symlinks

A broken symlink is the only condition `verify.sh` treats as an **error**
(exit 1). It usually means a file was moved/renamed in the repo, or a link was
deleted. Re-running the installer heals them:

```sh
bash ~/dotfiles/verify.sh      # lists each broken link
zsh ~/dotfiles/install.sh      # re-create links for the active profile
```

If `verify.sh` flags a link you expected to be **skipped**, check the `tags`
column in [`config/symlinks.map`](architecture.md#configsymlinksmap) — the link
only applies to profiles that match its tag, and `verify.sh` filters by the
active profile, so an intentionally-skipped link is never reported.

## Missing tools

`verify.sh` checks a list of required tools (`brew`, `mise`, `git`, `gh`,
`delta`, `lazygit`, `rg`, `fd`, `bat`, `fzf`, `zoxide`, `rustup`/`rustc`/`cargo`,
`jq`, `shellcheck`, `direnv`, `starship`, `pre-commit`, `yarn`). A missing tool
is a warning, not an error. Re-run bootstrap to install the gaps:

```sh
bash ~/dotfiles/bootstrap.sh             # re-installs from the profile Brewfiles
# or install one package directly:
brew install <tool>
```

If a command exists but isn't found in a new shell, confirm `mise` is active
(`eval "$(mise activate zsh)"` runs from `home/zshrc`) and that tool shims are on
`PATH` — open a fresh shell or `source ~/.zshrc`.

## Brewfile drift

`verify.sh` warns when installed packages no longer match the profile's
Brewfiles (core + `Brewfile.personal` + `Brewfile.work` as applicable). To
reconcile:

```sh
# Install anything declared but missing:
brew bundle --file=~/dotfiles/Brewfile
brew bundle --file=~/dotfiles/Brewfile.personal   # GUI profiles
brew bundle --file=~/dotfiles/Brewfile.work       # work profile

# See exactly what differs (declared vs installed):
brew bundle check --file=~/dotfiles/Brewfile --verbose
```

If you installed something you want to keep, add it to the appropriate Brewfile
so it becomes tracked; otherwise `brew uninstall` it.

## GitHub CLI authentication

`bootstrap.sh` runs `gh auth login` if `gh` is installed but not authenticated.
If `gh` commands fail later:

```sh
gh auth status        # check current state
gh auth login         # re-authenticate (choose SSH for git operations)
gh auth setup-git     # configure git to use gh credentials
```

Because `~/.gitconfig` is a real file (a thin include of the tracked config),
`gh auth setup-git` writes safely into it without touching the repo. If git
operations break after auth changes, run `bash ~/dotfiles/verify.sh` — the
"Git config include" check confirms the include is intact and `git config`
parses cleanly.

## mise runtimes

`verify.sh` warns if a runtime declared in
[`config/mise.toml`](architecture.md#configmisetoml) isn't installed. Install
the declared set:

```sh
mise install               # install everything in config/mise.toml
mise current               # show active versions
mise use --global node@22  # pin/switch a global version
```

Compiling runtimes (especially Ruby) can take several minutes. If a runtime
isn't picked up, ensure `mise` is activated in your shell and reopen the
terminal.

## Encrypted secrets (sops + age)

- **`age key not found`** when editing/decrypting → generate or restore your key:
  ```sh
  age-keygen -o ~/.config/sops/age/keys.txt
  ```
  Then make sure your public key is a recipient in `.sops.yaml`. See
  [Encrypted Secrets](secrets.md).
- **`sops` can't decrypt a file** → your public key isn't (or no longer is) a
  recipient. Have an existing holder add it and re-key:
  ```sh
  sops updatekeys <file>
  ```
- **Lost private key** → encrypted files are unrecoverable. Rotate the affected
  credentials and generate a new key. Always back up `keys.txt` to a password
  manager.

See [Encrypted Secrets](secrets.md) for the full setup and safety model.

## Scheduled updates

Daily updates run via a launchd agent installed by `scripts/setup-scheduler.sh`
(runs `update.sh` at 9 AM). Because launchd does **not** source your shell rc,
the job reads `~/.config/dotfiles/update.conf` for defaults like
`NO_UPGRADE=true`.

```sh
bash ~/dotfiles/scripts/setup-scheduler.sh              # install (9 AM daily)
bash ~/dotfiles/scripts/setup-scheduler.sh --no-upgrade # scheduled run skips upgrades
bash ~/dotfiles/scripts/setup-scheduler.sh --uninstall  # remove the job
```

If scheduled runs aren't happening:

```sh
launchctl print gui/$(id -u)/com.dotfiles.update   # is the agent loaded?
cat ~/dotfiles/logs/update.log                      # what happened last run
cat ~/dotfiles/logs/update.status                   # last result + failed steps
```

Re-installing is idempotent (it boots out any existing agent first). For a
machine-wide default that also applies to manual runs, set `NO_UPGRADE=true` in
`~/.config/dotfiles/update.conf` rather than only on the scheduled job.

## Pre-flight failures

`bootstrap.sh` runs [`scripts/preflight.sh`](DRY_RUN_AND_PREFLIGHT.md) first.
Critical errors (not macOS, no internet, <5 GB disk, unwritable `$HOME`,
conflict markers in tracked dotfiles) abort the run; warnings prompt to
continue. Run it standalone any time:

```sh
bash ~/dotfiles/scripts/preflight.sh           # 0 = ok, 2 = warnings, 1 = errors
bash ~/dotfiles/scripts/preflight.sh --strict  # treat warnings as errors
```

If you must proceed past pre-flight (not recommended):

```sh
bash ~/dotfiles/bootstrap.sh --skip-preflight
```

## Docs / Pages build issues

The docs site is built with MkDocs Material and deployed to GitHub Pages. The
build runs in **strict** mode, which **fails on any warning** — most commonly a
page missing from the `nav` in `mkdocs.yml`, or a broken relative link. Build
locally before pushing:

```sh
uvx --with mkdocs-material mkdocs build --strict   # must finish with zero warnings
uvx --with mkdocs-material mkdocs serve             # live preview at localhost:8000
```

If the build fails:

- **"is not found in the documentation files" / not in nav** → add the new page
  to `nav:` in `mkdocs.yml`.
- **"contains a link … that is not found"** → fix the relative link so it
  resolves to an existing page.

See [Contributing](contributing.md) for the full docs workflow.
