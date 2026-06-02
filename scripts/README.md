# Dotfiles Scripts

Automation scripts for system setup, configuration, and maintenance.

---

## Core Scripts

### `bootstrap_helpers.sh`

Shell functions used by `bootstrap.sh` and other scripts:

- **`step()`** — Display numbered progress steps
- **`info()`**, **`success()`**, **`warn()`**, **`error()`** — Colored output
- **`setup_colors()`** — Initialize color codes
- **`check_internet()`** — Verify network connectivity

**Usage:**
```bash
source "$(dirname "$0")/scripts/bootstrap_helpers.sh"
setup_colors
success "Task completed"
```

---

## Work Configuration Scripts

### `setup_work_configs.sh`

**Main orchestrator for work-specific configurations**

Sets up all work machine configurations in one go:
- Maven (`~/.m2/settings.xml`)
- Yarn (`~/.yarnrc`)
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
   - `~/dotfiles/installers/claude-code-installer`
   - `~/Downloads/ClaudeCode-macOS-*/claude-code-installer`
   - `~/Downloads/claude-code-installer`
3. Installs to `~/.local/bin/claude`
4. Verifies installation with `claude --version`

**Installer locations:**
- Place installer in `~/dotfiles/installers/` for automatic detection
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
   - `~/dotfiles/certs/`
   - `~/.continue/certs/`
   - `~/Downloads/`
   - `~/Downloads/ClaudeCode-macOS-*/`
2. Installs to `~/.continue/certs/`
3. Optionally installs to macOS System Keychain (requires sudo)
4. Adds `NODE_EXTRA_CA_CERTS` to `~/.zshrc.local`
5. Copies certificate to `~/dotfiles/certs/` for backup

**Certificate locations after installation:**
- `~/.continue/certs/ZscalerRootCertificate-2048-SHA256.crt` — For Continue IDE
- `~/dotfiles/certs/ZscalerRootCertificate-2048-SHA256.crt` — Backup (git-ignored)
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

## Testing Scripts

### `test_bootstrap_helpers.sh`

**Unit tests for bootstrap helper functions**

Tests the shell functions in `bootstrap_helpers.sh`:
- Color code initialization
- Output functions (info, success, warn, error)
- Step counter
- Helper utilities

**Usage:**
```bash
bash ~/dotfiles/scripts/test_bootstrap_helpers.sh
```

**Run in CI:**
```yaml
# .github/workflows/test-bootstrap.yml
- name: Test bootstrap helpers
  run: bash scripts/test_bootstrap_helpers.sh
```

---

### `verify_helpers.sh`

**Helper functions for verify.sh**

Utility functions used by the verification script:
- Check if command exists
- Verify file symlinks
- Check version strings
- Report findings

**Usage:**
```bash
source "$(dirname "$0")/scripts/verify_helpers.sh"
check_command git
verify_symlink ~/.zshrc
```

---

### `test_verify_helpers.sh`

**Unit tests for verify helper functions**

Tests the verification utility functions.

**Usage:**
```bash
bash ~/dotfiles/scripts/test_verify_helpers.sh
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
if [[ -f "$DOTFILES_DIR/scripts/bootstrap_helpers.sh" ]]; then
  source "$DOTFILES_DIR/scripts/bootstrap_helpers.sh"
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
source "$DOTFILES_DIR/scripts/bootstrap_helpers.sh"
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

*Last updated: June 1, 2026*
