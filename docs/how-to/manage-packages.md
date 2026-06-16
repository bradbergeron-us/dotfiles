# Manage Homebrew packages

Packages are declared in Brewfiles and installed with `brew bundle`. The core file applies to every machine; profile overlays layer GUI and work-only packages on top.

## The three Brewfiles

- [`Brewfile`](https://github.com/bradbergeron-us/dotfiles/blob/main/Brewfile) — **core CLI** formulae for *all* profiles. Keep GUI/cask entries out of this file.
- [`Brewfile.personal`](https://github.com/bradbergeron-us/dotfiles/blob/main/Brewfile.personal) — GUI casks, fonts, and apps for profiles **with a desktop** (`personal`, `work`). Skipped on `minimal`/`server`.
- [`Brewfile.work`](https://github.com/bradbergeron-us/dotfiles/blob/main/Brewfile.work) — **work-only** additions, layered on top for the `work` profile.

`bootstrap.sh` installs the core file plus the active profile's overlays (see [Profiles](../profiles.md)). The same list drives `verify.sh`'s Brewfile-drift check.

## Add a package

Pick the right file for its scope, then add a line. Use `brew "<formula>"` for CLI tools and `cask "<app>"` for GUI apps.

```ruby
# Brewfile (core CLI — every machine)
brew "htop"            # short comment explaining the tool

# Brewfile.personal (GUI app — desktop profiles)
cask "obsidian"

# Brewfile.work (work-only tool)
brew "awscli"
```

Install it:

```sh
brew bundle --file=~/dotfiles/Brewfile            # core
brew bundle --file=~/dotfiles/Brewfile.personal   # GUI overlay
brew bundle --file=~/dotfiles/Brewfile.work       # work overlay
```

`brew bundle` is idempotent — it installs only what's missing, so it's safe to re-run.

## Remove a package

Delete its line from the Brewfile, then uninstall it from the machine (editing the file alone does not remove an installed package):

```sh
brew uninstall htop
```

To prune everything **not** listed in a Brewfile, use cleanup (review the dry run first):

```sh
brew bundle cleanup --file=~/dotfiles/Brewfile            # preview removals
brew bundle cleanup --file=~/dotfiles/Brewfile --force    # actually remove
```

## Check for drift

`brew bundle check` reports whether everything in a Brewfile is installed:

```sh
brew bundle check --file=~/dotfiles/Brewfile
```

`update.sh` and `verify.sh` already iterate the active profile's Brewfiles, so a routine `bash ~/dotfiles/update.sh` keeps installed packages in sync.

## Commit

```sh
git -C ~/dotfiles add Brewfile Brewfile.personal Brewfile.work
git -C ~/dotfiles commit -m "feat: add htop to core Brewfile"
```

!!! tip
    Put a tool in the **lowest** scope that needs it. A CLI used on every machine belongs in `Brewfile`; a desktop app belongs in `Brewfile.personal`; keep work-only tooling in `Brewfile.work` so personal machines stay lean.

## See also

- [Machine Profiles](../profiles.md) — how the core/personal/work Brewfiles map to profiles.
- [Usage & lifecycle](../usage.md) — how `update.sh` and `verify.sh` check Brewfile drift.
