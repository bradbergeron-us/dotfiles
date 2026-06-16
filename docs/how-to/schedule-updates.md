# Schedule automatic updates

Run `update.sh` automatically every day with a launchd job, installed by [`scripts/setup-scheduler.sh`](https://github.com/bradbergeron-us/dotfiles/blob/main/scripts/setup-scheduler.sh).

## Install the daily job

```sh
bash ~/dotfiles/scripts/setup-scheduler.sh
```

This renders `system/LaunchAgents/com.dotfiles.update.plist` into `~/Library/LaunchAgents/`, loads it with `launchctl`, and schedules `update.sh` to run **daily at 9 AM**. It's idempotent — re-running reloads the job cleanly.

After install it reports the log, status file, plist path, and the uninstall command.

## Skip upgrades or pulls on the schedule

Pass flags to bake them into the scheduled invocation (e.g. the job runs `update.sh --no-upgrade`):

```sh
bash ~/dotfiles/scripts/setup-scheduler.sh --no-upgrade   # pull + re-symlink + verify only
bash ~/dotfiles/scripts/setup-scheduler.sh --no-pull      # skip the git pull
```

`--no-upgrade` is recommended on work machines with version-sensitive tooling.

!!! note
    These flags affect only the **scheduled** run. For a machine-wide default that also applies to manual `update.sh` runs, set `NO_UPGRADE=true` (or `NO_PULL=true`) in `~/.config/dotfiles/update.conf` instead — `update.sh` reads that file directly, so the launchd job (which never sources `~/.zshrc`) honors it too.

### Set up `update.conf`

```sh
mkdir -p ~/.config/dotfiles
cp ~/dotfiles/home/examples/update.conf.example ~/.config/dotfiles/update.conf
# then edit: NO_UPGRADE=true / NO_PULL=true as desired
```

Precedence is **config file < environment < command-line flags**.

## Change the schedule

Edit the `StartCalendarInterval` in `system/LaunchAgents/com.dotfiles.update.plist`, then re-run `setup-scheduler.sh` to reload the job with the new time.

## Where to find logs and status

- `~/dotfiles/logs/update.log` — scheduled run output (auto-rotated past ~1 MiB, keeps 5 copies via `DOTFILES_LOG_KEEP`).
- `~/dotfiles/logs/update.status` — last-run timestamp, success/failure, failed steps, and duration.

Check the last result quickly with the `dotstatus` alias. On failure, `update.sh` also posts a macOS notification (skipped in CI/headless).

## Uninstall

```sh
bash ~/dotfiles/scripts/setup-scheduler.sh --uninstall
```

This boots out the launchd job and removes the installed plist.
