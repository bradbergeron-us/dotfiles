# Recover from a failed update

`update.sh` is self-healing: individual step failures don't abort the run, every step is attempted, and the outcome is recorded. Use this guide when an update reports issues.

## 1. See what failed

Start with the status snapshot (alias `dotstatus`):

```sh
dotstatus
# or: bash ~/dotfiles/scripts/status.sh
```

It prints the repo's git state and the last update result read from `logs/update.status`. A failure shows the failed step(s) and points you at the log.

Inspect `logs/update.status` directly — it's `key=value`:

```sh
cat ~/dotfiles/logs/update.status
# last_run=2026-06-16T09:00:03Z
# status=failure
# failed_steps=Homebrew, Health check
# duration_seconds=87
```

Then read the full output for the failing step:

```sh
less ~/dotfiles/logs/update.log         # current run
ls  ~/dotfiles/logs/update.log.*        # rotated copies (.1 … .5)
```

## 2. Dirty working tree (pull skipped)

If the dotfiles repo has uncommitted changes to **tracked** files, `update.sh` skips `git pull` to avoid a rebase conflict and warns:

> Uncommitted changes in … — skipping pull to avoid a rebase conflict

Resolve it by committing or stashing your changes, then re-run:

```sh
git -C ~/dotfiles status
git -C ~/dotfiles stash          # or: git commit -am "wip"
bash ~/dotfiles/update.sh
```

To pull anyway (autostashing local changes), use `--force-pull`:

```sh
bash ~/dotfiles/update.sh --force-pull
```

## 3. Failed rebase during pull

`update.sh` pulls with `--rebase --autostash`. If that fails, it **automatically aborts the in-progress rebase** and leaves the repo exactly as it was before the pull, then marks the `Dotfiles` step failed. You won't be left mid-rebase.

Re-sync manually if needed:

```sh
git -C ~/dotfiles status                       # confirm no rebase in progress
git -C ~/dotfiles pull --rebase --autostash     # retry once conflicts are understood
```

If a rebase ever *is* left in progress, abort it explicitly:

```sh
git -C ~/dotfiles rebase --abort
```

## 4. A package/runtime step failed

Brew, mise, rustup, or gem failures are isolated and reported but don't stop the rest of the run. Re-run just the upgrades after fixing the underlying issue, or skip them to recover the rest of your environment:

```sh
bash ~/dotfiles/update.sh --no-upgrade   # pull + re-symlink + verify only
```

## 5. Re-run and confirm healthy

```sh
bash ~/dotfiles/update.sh
dotstatus                       # expect: result: success
```

!!! tip
    Use `bash ~/dotfiles/update.sh --dry-run` to preview exactly what the next run will do — including whether it would skip the pull — without changing anything.

## See also

- [Troubleshooting](../troubleshooting.md) — fixes for specific failures.
- [Usage & lifecycle](../usage.md) — the update steps and safety flags.
