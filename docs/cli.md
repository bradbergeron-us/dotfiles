# dotfiles CLI

`scripts/dotfiles.sh` is a single, memorable entry point for the most common
dotfiles operations. It is a thin wrapper: most subcommands just delegate to the
existing scripts (forwarding every argument and the exit code), so nothing about
the underlying behavior changes — you simply have one command to remember.

## Running it

Two equivalent ways:

```bash
dotfiles <command> [args...]                  # when ~/dotfiles/bin is on PATH
bash ~/dotfiles/scripts/dotfiles.sh <command> # always works
```

The bare `dotfiles` command works because `home/zsh/path.zsh` adds
`~/dotfiles/bin` to your `PATH`, and `bin/dotfiles` is a small shim that calls
`scripts/dotfiles.sh`. If `dotfiles` is not found, open a new shell (or
`source ~/.zshrc`) so the updated `PATH` takes effect, or use the full
`bash ~/dotfiles/scripts/dotfiles.sh` form.

## Commands

| Command | What it does | Delegates to |
|---------|--------------|--------------|
| `help` | Show usage (also the default with no command) | — |
| `status` | Repo git state + last `update.sh` result | `scripts/status.sh` |
| `verify` | Full environment health check | `verify.sh` |
| `doctor` | Read-only health check: status + verify + shell & terminal config | _(built-in)_ |
| `update` | Pull, re-symlink, upgrade packages/runtimes, verify | `update.sh` |
| `profile` | Show or set this machine's profile | `scripts/profile.sh` |
| `cleanup` | Remove common dotfile cruft (backups, cache, legacy configs) | `scripts/cleanup.sh` |

Arguments are passed straight through to the underlying script, so every flag the
delegated script supports still works:

```bash
dotfiles status --verify      # status.sh --verify
dotfiles update --dry-run     # update.sh --dry-run
dotfiles update --no-upgrade  # update.sh --no-upgrade
dotfiles cleanup --dry-run    # cleanup.sh --dry-run
dotfiles profile set work     # profile.sh set work
```

An unknown command prints a helpful message and exits non-zero.

## `doctor`

`doctor` is a read-only snapshot of dotfiles health. It never changes your
system; it runs a few checks and exits non-zero if any of them fail, so it is
safe to use in scripts and CI. The flow is:

1. **Repository status** — `status.sh --exit-code` (repo git state + last update).
2. **Verification** — `verify.sh` (symlinks, required tools, runtimes, git health, …).
3. **Shell configuration** — `zsh -n` on `home/zshrc` and every `home/zsh/*.zsh` module.
4. **Terminal configuration** — validates `config/ghostty/config` with
   `ghostty +validate-config` when Ghostty is installed (otherwise confirms the
   config is present); notes the Hyper fallback.

```bash
dotfiles doctor
```

## Help & man page

Every command has help text:

- **Top-level usage**: `dotfiles`, `dotfiles help`, `dotfiles -h`, or `dotfiles --help`.
- **Per-command help**: `dotfiles <command> --help`. For delegating commands this
  is forwarded to the underlying script — e.g. `dotfiles status --help`,
  `dotfiles update --help`, `dotfiles cleanup --help`, `dotfiles profile --help`.
  `dotfiles verify --help` and `dotfiles doctor --help` also print command-specific
  usage (without running the checks).

A man page is bundled at `man/man1/dotfiles.1`:

```bash
man dotfiles                 # works in a new shell (MANPATH is set by path.zsh)
man ./man/man1/dotfiles.1    # or view the file directly, from the repo
```

`home/zsh/path.zsh` adds `~/dotfiles/man` to `MANPATH`, so `man dotfiles` works
after opening a new shell — nothing needs to be installed.

## See also

- [Usage & Lifecycle](usage.md) — bootstrap, update, verify, status, scheduling
- [Zsh configuration](zsh.md) — the module layout `doctor` syntax-checks
- [Ghostty](ghostty.md) — terminal config `doctor` validates
