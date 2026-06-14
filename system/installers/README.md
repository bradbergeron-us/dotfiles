# Installer Storage

This directory is for storing installer scripts and binaries that may not be publicly available or require manual download.

## Purpose

Some tools (like Claude Code) provide installers that need to be downloaded manually. This directory provides a central location to cache these installers for reuse across machines.

## Usage

### Storing Installers

```bash
# Copy installer to this directory
cp ~/Downloads/claude-code-installer ~/dotfiles/system/installers/
cp ~/Downloads/ClaudeCode-macOS-v1.2.0-20260327/claude ~/dotfiles/system/installers/

# Make executable if needed
chmod +x ~/dotfiles/system/installers/claude-code-installer
```

### Using Stored Installers

Installation scripts in `~/dotfiles/scripts/` will automatically check this directory:

```bash
# If installer is in this directory, setup script will use it
bash ~/dotfiles/scripts/install_claude_code.sh
```

## Supported Installers

### Claude Code CLI

**Current Version**: 1.2.0 (as of March 2026)

**Download**:
- Official: https://claude.com/download
- Direct: Provided by your organization

**Files**:
- `claude-code-installer` - Installation script
- `claude` - CLI binary (184.9 MB)

**Installation**:
```bash
# If you have the installer package
cp ~/Downloads/ClaudeCode-macOS-*/claude-code-installer ~/dotfiles/system/installers/
cp ~/Downloads/ClaudeCode-macOS-*/claude ~/dotfiles/system/installers/

# Install manually
mkdir -p ~/.local/bin
cp ~/dotfiles/system/installers/claude ~/.local/bin/
chmod +x ~/.local/bin/claude

# Or use the installer script
bash ~/dotfiles/system/installers/claude-code-installer --prefix="$HOME/.local/bin"
```

### VS Code Extensions (.vsix files)

Some organizations provide internal VS Code extensions as `.vsix` files.

**Storage**: Place in `~/dotfiles/vscode/extensions/` instead of this directory

**Installation**:
```bash
code --install-extension ~/dotfiles/vscode/extensions/your-extension.vsix
```

## Gitignore

This directory has a `.gitignore` that blocks all binary files by default to prevent accidentally committing large installers to git.

**Why?**
- Installers are often 100+ MB
- GitHub has file size limits (100 MB per file)
- Installers become outdated quickly
- Better to download fresh from official sources

If you need to track a specific installer script (not binary), you can force-add it:

```bash
git add -f system/installers/install-something.sh
```

## Automation

Future scripts may automatically:
1. Check this directory for installers
2. Fall back to official download URLs
3. Cache downloaded installers here for reuse
4. Verify checksums for security

## Security Notes

### ✅ Safe Practices

- Download installers from official sources
- Verify checksums/signatures when available
- Keep installers updated
- Document where installers came from

### ❌ Avoid

- Don't commit large binaries (>10 MB) to git
- Don't use installers from untrusted sources
- Don't modify installers without verification
- Don't share installers that contain licensing/DRM

## Alternative: Download on Demand

Instead of storing installers, scripts can download them:

```bash
#!/usr/bin/env bash
# Example: download installer if not cached

INSTALLER_URL="https://example.com/installer"
INSTALLER_PATH="$HOME/dotfiles/system/installers/tool-installer"

if [[ ! -f "$INSTALLER_PATH" ]]; then
  echo "Downloading installer..."
  curl -L "$INSTALLER_URL" -o "$INSTALLER_PATH"
  chmod +x "$INSTALLER_PATH"
fi

# Use cached installer
bash "$INSTALLER_PATH"
```

## See Also

- [Claude Code Setup](../templates/claude/README.md)
- [Work Configuration Scripts](../scripts/)
