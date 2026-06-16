# Adopt a profile on an existing machine

Already set up a machine and want to **change** its profile — say, turn a
`personal` laptop into a `work` one, or trim a desktop down to `minimal`? You do
**not** need to re-run `bootstrap.sh`. This tutorial switches a profile in place
with `dotprofile` (the alias for `scripts/profile.sh`) and re-applies it with
`install.sh` + `update.sh`.

A profile is the durable identity of a machine, persisted at
`~/.config/dotfiles/profile` and honored by every lifecycle script. For the
conceptual model and the per-component matrix, see the
[Profiles reference](../profiles.md).

## Step 1 — See the current profile

Check what this machine is set to today:

```sh
dotprofile
```

```text
  Active profile  personal
  ℹ set in ~/.config/dotfiles/profile
```

If no profile file exists yet, you will instead see that it is the default
(`personal`) with a hint to set one. List the available profiles any time:

```sh
dotprofile list
```

```text
  Available profiles: minimal personal work server
  Active: personal
```

!!! info "`dotprofile` is `scripts/profile.sh`"
    The alias is shorthand for `bash ~/dotfiles/scripts/profile.sh`. If the alias
    isn't loaded yet (for example in a non-interactive shell), call the script
    directly.

## Step 2 — Set the new profile

Persist the new profile. For example, adopt `work`:

```sh
dotprofile set work
```

```text
  ✓ profile set to 'work'  (~/.config/dotfiles/profile)
  ℹ Apply it: zsh ~/dotfiles/install.sh  &&  bash ~/dotfiles/update.sh
```

`set` validates the name against `minimal | personal | work | server` (an
unknown name is rejected), then writes it to `~/.config/dotfiles/profile` via
`persist_profile`. Setting the profile only records the choice — it does not yet
change what is installed or linked. That is the next step.

!!! tip "Try it without persisting"
    To preview a profile's effect for a single command instead of persisting it,
    set the `DOTFILES_PROFILE` environment variable, which outranks the file:
    `DOTFILES_PROFILE=work bash ~/dotfiles/verify.sh`. A one-off `--profile` flag
    on `bootstrap.sh` outranks everything. Precedence is
    `--profile flag > DOTFILES_PROFILE env > profile file > default`.

## Step 3 — Re-link dotfiles for the new profile

Re-run the symlink installer so the set of linked dotfiles matches the new
profile (adopting `work`/`gui`-tagged files, or skipping them when you downgrade):

```sh
zsh ~/dotfiles/install.sh
```

`install.sh` is idempotent and reads `current_profile`, creating only the links
that apply to the now-active profile. Records tagged for other profiles are
skipped, and any real file already at a destination is backed up to
`~/.dotfiles_backup/` before a link replaces it — nothing is overwritten in
place. Each link is reported as **current**, **linked**, **backed up**, or
**skip**.

## Step 4 — Re-run update to install the rest

Pull in the profile's packages and run the health check:

```sh
bash ~/dotfiles/update.sh
```

This re-runs `install.sh`, then upgrades Homebrew (installing any newly relevant
overlay packages on the next `brew bundle`/drift cycle), mise runtimes, Rust, and
gems, and finishes with `verify.sh`. Because `update.sh` reads `current_profile`,
it only touches the components the new profile includes.

!!! note "Switching *to* `work`?"
    The work-configs prompt (Maven/Yarn/Continue/Claude/AWS) and corporate
    certificates are part of bootstrap's `work` step, not `update.sh`. Run that
    setup explicitly: `bash ~/dotfiles/scripts/setup_work_configs.sh`. The
    [Set up a work laptop](work-laptop.md) tutorial covers the full work flow.

## Step 5 — Confirm the switch

Verify the machine is healthy under the new profile and confirm the banner shows
it:

```sh
bash ~/dotfiles/verify.sh
```

`verify.sh` prints `Profile  work` (or whichever you chose) and filters its
symlink and Brewfile-drift checks by that profile, so it won't flag dotfiles or
packages intentionally excluded by the new profile. A quick recap:

```sh
dotstatus
```

The status snapshot's `Profile` line should now read the profile you adopted.

## Done

Switching a machine's profile is just: `dotprofile set <name>` →
`zsh ~/dotfiles/install.sh` → `bash ~/dotfiles/update.sh`. No re-bootstrap
required, because every lifecycle script reads the same persisted profile.

## Where to next

- [Profiles reference](../profiles.md) — the precedence rules and the full
  per-component matrix.
- [Set up a work laptop](work-laptop.md) — the complete `work`-profile flow.
- [Usage & lifecycle](../usage.md) — every command and flag for `install.sh`,
  `update.sh`, `verify.sh`, and `status.sh`.
