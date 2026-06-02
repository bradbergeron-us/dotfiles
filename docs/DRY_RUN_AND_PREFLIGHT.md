# Dry-Run and Pre-flight Check

New safety features for bootstrap.sh to preview changes and validate your system before installation.

## Pre-flight Check

Before running bootstrap, the pre-flight check validates your system:

```bash
bash scripts/preflight.sh
```

### What It Checks

1. **Operating System** — Confirms macOS and version
2. **CPU Architecture** — Detects Apple Silicon vs Intel, checks Rosetta 2
3. **Disk Space** — Ensures 5GB+ free (10GB+ recommended)
4. **Internet** — Verifies connectivity to GitHub
5. **Xcode CLI Tools** — Checks if installed
6. **Conflicting Package Managers** — Warns about MacPorts, Fink
7. **Homebrew** — Validates location matches architecture
8. **Shell** — Confirms zsh is default
9. **Write Permissions** — Tests access to home directory and common paths
10. **System Integrity Protection** — Reports SIP status
11. **Existing Dotfiles** — Detects files that will be backed up
12. **Git Config** — Checks user.name and user.email

### Exit Codes

- `0` — All checks passed, ready to bootstrap
- `1` — Critical failures (blocks bootstrap)
- `2` — Warnings only (bootstrap can proceed)

### Strict Mode

Treat warnings as errors:

```bash
bash scripts/preflight.sh --strict
```

### Integration with Bootstrap

Pre-flight check runs automatically before bootstrap:

```bash
bash bootstrap.sh
```

The check runs before any changes are made. If critical errors are found, bootstrap exits immediately.

To skip pre-flight (not recommended):

```bash
bash bootstrap.sh --skip-preflight
```

## Dry-Run Mode

Preview what bootstrap will do without actually making changes:

```bash
bash bootstrap.sh --dry-run
```

### What Dry-Run Shows

For each step, dry-run reports:

- **Already installed** — Tool is present, skip
- **Would install** — What would be downloaded/compiled
- **Would configure** — Settings that would be applied
- **Would symlink** — Files that would be linked
- **Would backup** — Existing files that would be preserved

### Example Output

```
  🚀  dotfiles bootstrap  —  DRY-RUN MODE
  ─────────────────────────────────────────────────

  ▸ [1/13]  🛠️  Xcode Command Line Tools  (dry-run)
  ✓ Xcode CLI Tools already installed — skip

  ▸ [2/13]  🍺  Homebrew  (dry-run)
  ✓ Homebrew 5.1.14 already installed — skip

  ▸ [3/13]  📦  Packages (brew bundle)  (dry-run)
  → Checking Brewfile packages...
  ✓ All Brewfile packages already installed — skip

  ▸ [7/13]  ⚡  Runtimes via mise  (Ruby · Node · Java · Python · Go)  (dry-run)
  → Would install 5 runtime(s) (can take 5-10 minutes)
  →   - ruby@3.3.6
  →   - node@22
  →   - java@temurin-21
  →   - python@3.12
  →   - go@1.24

  ═════════════════════════════════════════════════
  📋  Dry-Run Summary  —  4 actions planned
  ═════════════════════════════════════════════════

   1. Run: brew bundle --file=~/dotfiles/Brewfile
   2. Install mise runtimes: ruby@3.3.6 node@22 ...
   3. Configure git-lfs
   4. Run: install.sh (symlink dotfiles)

  ─────────────────────────────────────────────────
  → To actually run bootstrap: bash ~/dotfiles/bootstrap.sh
```

### Dry-Run Behavior

- **No installations** — Nothing is downloaded or compiled
- **No configurations** — No settings are changed
- **No symlinks** — No files are linked or backed up
- **No prompts** — Skips interactive steps (SSH key gen, macOS defaults)
- **Fast** — Completes in seconds instead of minutes

### Combining Options

Run dry-run without pre-flight (faster):

```bash
bash bootstrap.sh --dry-run --skip-preflight
```

## Use Cases

### First-Time Setup

```bash
# 1. Pre-flight check
bash scripts/preflight.sh

# 2. Preview changes
bash bootstrap.sh --dry-run

# 3. Run for real
bash bootstrap.sh
```

### Teammate Onboarding

Share dry-run output to show what will be installed:

```bash
bash bootstrap.sh --dry-run > preview.txt
```

Team members can review before running on their machines.

### CI/CD Validation

Pre-flight check in CI to catch issues:

```bash
bash scripts/preflight.sh --strict
if [[ $? -eq 0 ]]; then
  echo "System ready"
else
  echo "System not ready"
  exit 1
fi
```

### Debugging

If bootstrap fails partway through, dry-run shows what remains:

```bash
bash bootstrap.sh --dry-run
```

Check the summary to see which steps still need completion.

## Implementation Notes

### Idempotency

Both dry-run and actual bootstrap are idempotent:

- Already-installed tools are skipped
- Existing symlinks are left alone
- Re-running is safe and fast

### Performance

- **Pre-flight**: ~2 seconds
- **Dry-run**: ~5 seconds (without pre-flight)
- **Full bootstrap**: 5-15 minutes (depends on runtime compilation)

### Limitations

Dry-run cannot predict:

- Interactive prompts (SSH passphrase, work configs)
- Download failures or network issues
- Compilation errors for runtimes
- Permission errors that only appear during write operations

## Future Enhancements

Potential improvements:

1. **Selective dry-run** — Preview only specific steps
2. **Diff mode** — Compare current state to desired state
3. **Export/import** — Save dry-run results, apply elsewhere
4. **Notifications** — Alert when long-running steps complete

## Related

- [Bootstrap guide](../README.md#quick-start)
- [Update script](../update.sh) — Keep everything current
- [Verify script](../verify.sh) — Health check
