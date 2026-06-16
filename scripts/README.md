# Dotfiles Scripts

Automation scripts for system setup, configuration, and maintenance.

## Layout

- **`scripts/`** — runnable scripts (work setup, installers, `macos.sh`, `uninstall.sh`, `validate_templates.sh`, …).
- **`scripts/lib/`** — sourced helper libraries (no side effects): `bootstrap_helpers.sh`, `verify_helpers.sh`, `dryrun_helpers.sh`, `update_helpers.sh`, `status_helpers.sh`, `profile_helpers.sh`.
- **`scripts/tests/`** — [bats-core](https://github.com/bats-core/bats-core) unit tests (`test_*.bats`) for the helpers and validators, plus the shared `test_helper.bash`.

---

## Helper Libraries (`lib/`)

### `lib/bootstrap_helpers.sh`

Shell functions sourced by `bootstrap.sh`, `update.sh`, and `verify.sh`:

- **`setup_colors()`** — Initialize color codes (call once after sourcing)
- **`step()`** — Display numbered progress steps
- **`info()`**, **`success()`**, **`warn()`** — Colored output
- **`parse_mise_runtimes()`** — Read the `[tools]` table of `config/mise.toml`, the single source of truth for runtime versions

**Usage:**
```bash
source "$(dirname "$0")/scripts/lib/bootstrap_helpers.sh"
setup_colors
success "Task completed"
```

---

## Maintenance

### `status.sh`

**Quick, read-only dotfiles health snapshot.**

Prints the dotfiles repo's git state (branch, clean/dirty, ahead/behind upstream) and the result of the last `update.sh` run (read from `logs/update.status`). Fast and side-effect-free.

**Usage:**
```bash
bash ~/dotfiles/scripts/status.sh             # repo + last-update summary
bash ~/dotfiles/scripts/status.sh --verify    # also run the full verify.sh
bash ~/dotfiles/scripts/status.sh --exit-code # exit non-zero if unhealthy (for scripts/CI)
```

Aliased as `dotstatus` in `home/zshrc`. Parsing and git-state helpers live in `lib/status_helpers.sh` (unit-tested by `tests/test_status_helpers.bats`).

### `profile.sh`

**Show or set this machine's profile.**

`bash scripts/profile.sh [show | list | set <name>]` reads/writes `~/.config/dotfiles/profile` so an existing machine can adopt a profile (`personal` | `work` | `minimal` | `server`) without re-running bootstrap. Resolution logic lives in `lib/profile_helpers.sh` (unit-tested by `tests/test_profile_helpers.bats`); aliased `dotprofile`.

---

## Work Configuration Scripts

### `setup_work_configs.sh`

**Main orchestrator for work-specific configurations**

Sets up all work machine configurations in one go:
- Maven (`~/.m2/settings.xml`)
- Yarn (`~/.yarnrc`)
- Bundle (`~/.bundle/config`)
- Continue IDE (`~/.continue/config.yaml`)
- Claude Code (`~/.claude/settings.json`)
- AWS (`~/.aws/config`)
- Claude CLI (`~/.local/bin/claude`)

**Usage:**
```bash
bash ~/dotfiles/scripts/setup_work_configs.sh
```

**Interactive prompts for each component:**
- Automatically backs up existing files before overwriting
- Copies templates from `~/dotfiles/templates/`
- Creates necessary directories
- Provides next steps after completion

**When to run:**
- First-time work machine setup
- After cloning dotfiles on a new work laptop
- When updating work configurations

---

### `install_claude_code.sh`

**Install Claude Code CLI to ~/.local/bin**

Searches for the Claude Code installer in common locations and installs it.

**Usage:**
```bash
bash ~/dotfiles/scripts/install_claude_code.sh
```

**What it does:**
1. Checks if Claude Code is already installed
2. Searches for installer in:
   - `~/dotfiles/system/installers/claude-code-installer`
   - `~/Downloads/ClaudeCode-macOS-*/claude-code-installer`
   - `~/Downloads/claude-code-installer`
3. Installs to `~/.local/bin/claude`
4. Verifies installation with `claude --version`

**Installer locations:**
- Place installer in `~/dotfiles/system/installers/` for automatic detection
- Or provide path when prompted

**Troubleshooting:**
If `claude` command not found after installation:
```bash
# Verify PATH includes ~/.local/bin
echo $PATH | grep ".local/bin"

# If missing, add to ~/.zshrc.local:
export PATH="$HOME/.local/bin:$PATH"

# Restart shell
exec zsh
```

---

### `install_zscaler_cert.sh`

**Install Zscaler root certificate for corporate proxy**

Required for Claude Code, Continue IDE, npm, yarn, and other Node.js tools to work behind corporate firewall.

**Usage:**
```bash
bash ~/dotfiles/scripts/install_zscaler_cert.sh
```

**What it does:**
1. Searches for certificate (`ZscalerRootCertificate-2048-SHA256.crt`) in:
   - `~/dotfiles/system/certs/`
   - `~/.continue/certs/`
   - `~/Downloads/`
   - `~/Downloads/ClaudeCode-macOS-*/`
2. Installs to `~/.continue/certs/`
3. Optionally installs to macOS System Keychain (requires sudo)
4. Adds `NODE_EXTRA_CA_CERTS` to `~/.zshrc.local`
5. Copies certificate to `~/dotfiles/system/certs/` for backup

**Certificate locations after installation:**
- `~/.continue/certs/ZscalerRootCertificate-2048-SHA256.crt` — For Continue IDE
- `~/dotfiles/system/certs/ZscalerRootCertificate-2048-SHA256.crt` — Backup (git-ignored)
- `/Library/Keychains/System.keychain` — System-wide trust (optional)

**Obtaining the certificate:**
- Download from IT portal
- Extract from Claude Code installer package
- Request from IT security team

**After installation:**
```bash
# Restart shell to load NODE_EXTRA_CA_CERTS
exec zsh

# Test Claude Code
claude --version

# Test npm/yarn
npm config get cafile  # Should show cert path
```

---

### `install_vscode_work_extensions.sh`

**Install work-specific VS Code extensions from .vsix files**

Batch install VS Code extensions that aren't available in the public marketplace.

**Usage:**
```bash
bash ~/dotfiles/scripts/install_vscode_work_extensions.sh
```

**Setup:**
1. Create directory:
   ```bash
   mkdir -p ~/dotfiles/vscode/extensions
   ```

2. Place .vsix files there:
   ```bash
   cp continue-1.5.29.vsix ~/dotfiles/vscode/extensions/
   cp afs-code-cred-3.0.0.vsix ~/dotfiles/vscode/extensions/
   ```

3. Run script

**Prerequisites:**
- VS Code CLI must be in PATH
- If `code` command not found:
  - Open VS Code
  - Command Palette (⌘⇧P)
  - "Shell Command: Install 'code' command in PATH"

**What it does:**
1. Checks for VS Code CLI (`code`)
2. Finds all `.vsix` files in `~/dotfiles/vscode/extensions/`
3. Installs each with `code --install-extension --force`
4. Reports success/failure for each extension

**Verify installation:**
```bash
code --list-extensions
```

---

## Tests (`tests/`)

[bats-core](https://github.com/bats-core/bats-core) tests (`test_*.bats`), auto-discovered and run by `.github/workflows/test-bootstrap.yml`. Helper unit tests: `test_bootstrap_helpers.bats`, `test_verify_helpers.bats`, `test_dryrun_helpers.bats`, `test_update_helpers.bats`, `test_status_helpers.bats`, `test_profile_helpers.bats`, and `test_validate_templates.bats`. Plus `test_install.bats`, an integration test that runs the real `install.sh` against an isolated `$HOME`.

**Install bats** (already in the `Brewfile`):
```bash
brew install bats-core
```

**Run the suite** (from the repo root):
```bash
bats scripts/tests/           # whole suite
bats scripts/tests/test_bootstrap_helpers.bats   # a single file
```

**Conventions:**
- Each file is `#!/usr/bin/env bats` and starts with `load 'test_helper'`, sourcing `tests/test_helper.bash` for the `$LIB_DIR` / `$SCRIPTS_DIR` / `$REPO_ROOT` paths.
- Write cases as `@test "description" { ... }` blocks; use the auto-managed scratch dir `$BATS_TEST_TMPDIR` for fixtures.
- Add new tests as `@test` blocks in the `*.bats` file next to the helper they cover — CI and `bats scripts/tests/` discover them automatically.

### `tests/test_bootstrap_helpers.bats`

**Unit tests for bootstrap helper functions**

Tests the shell functions in `lib/bootstrap_helpers.sh`:
- Color code initialization (`setup_colors`)
- Output functions (`info`, `success`, `warn`)
- Step counter (`step`)
- mise runtime parsing (`parse_mise_runtimes`)

**Usage:**
```bash
bats scripts/tests/test_bootstrap_helpers.bats
```

---

### `lib/verify_helpers.sh`

**Pure check functions for verify.sh**

Each sets result globals (counts + lists) instead of printing or exiting, which makes them unit-testable:
- **`check_symlinks`** / **`load_symlink_map`** — validate tracked symlinks loaded from `config/symlinks.map`
- **`check_required_tools`** — report tools missing from `PATH`
- **`check_ssh_key`** / **`check_git_lfs_global`** — signing key + global git-lfs init
- **`check_mise_installed`** — runtimes declared in `config/mise.toml` are actually installed
- **`check_stale_backups`** / **`check_dotfiles_git_health`** / **`check_brewfile_drift`**

**Usage:**
```bash
source "$(dirname "$0")/scripts/lib/verify_helpers.sh"
load_symlink_map "$DOTFILES_DIR/config/symlinks.map"
check_symlinks "$DOTFILES_DIR" "$HOME"
echo "$SYMLINK_BROKEN_COUNT broken"
```

---

### `tests/test_verify_helpers.bats`

**Unit tests for verify helper functions**

Tests the verification utility functions.

**Usage:**
```bash
bats scripts/tests/test_verify_helpers.bats
```

---

## Script Development Guidelines

### Writing New Scripts

**Template:**
```bash
#!/usr/bin/env bash
# Script description
# Part of: [Category]

set -e

# Get dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source helpers if available
if [[ -f "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh" ]]; then
  source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
else
  # Minimal fallback functions
  info() { echo "ℹ️  $*"; }
  success() { echo "✅ $*"; }
  warn() { echo "⚠️  $*"; }
  error() { echo "❌ $*" >&2; }
fi

# Main function
main() {
  info "Starting task..."
  # Do work here
  success "Task completed"
}

# Run main if script executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

### Best Practices

**Safety:**
- Use `set -e` to exit on errors
- Always back up files before overwriting
- Provide `--dry-run` or confirmation prompts for destructive operations
- Check for required commands before using them

**User Experience:**
- Use colored output functions consistently
- Provide clear progress messages
- Show next steps at completion
- Handle both interactive and non-interactive execution

**Idempotency:**
- Scripts should be safe to run multiple times
- Check for existing state before making changes
- Use "already exists" messages instead of errors

**Testing:**
- Write unit tests for helper functions
- Test on clean systems (VMs or containers)
- Document test cases in script comments

**Documentation:**
- Add clear script descriptions at the top
- Document all parameters and options
- Include usage examples
- Note prerequisites and dependencies

### Making Scripts Executable

```bash
chmod +x scripts/my_new_script.sh
```

### Testing Scripts Locally

```bash
# Dry run - see what would happen
bash scripts/setup_work_configs.sh
# Then answer 'n' to each prompt

# Test with shellcheck
shellcheck scripts/setup_work_configs.sh

# Test in a clean environment
docker run -it --rm -v ~/dotfiles:/dotfiles ubuntu:22.04 bash
cd /dotfiles && bash scripts/setup_work_configs.sh
```

---

## Common Issues

### Script Can't Find Helpers

**Symptom:** `bootstrap_helpers.sh: No such file or directory`

**Solution:**
```bash
# Use absolute path from DOTFILES_DIR
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
```

### Permission Denied

**Symptom:** `Permission denied` when running script

**Solution:**
```bash
chmod +x scripts/my_script.sh
```

### Changes Not Taking Effect

**Symptom:** Updated script doesn't reflect changes

**Solution:**
```bash
# Restart shell to reload functions
exec zsh

# Or source the file directly
source ~/dotfiles/scripts/my_script.sh
```

---

## See Also

- [Complete Work Setup Guide](../docs/work-setup-complete.md) — End-to-end work machine setup
- [Work Machine Topics](../docs/work-machine.md) — Brewfile.work, zshrc.local, direnv
- [Main README](../README.md) — Dotfiles overview
- [Templates](../templates/README.md) — Configuration templates

---

*Last updated: June 14, 2026*
