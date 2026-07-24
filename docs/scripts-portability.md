# Script Portability and Organization

**Last updated**: 2026-07-24

## Overview

This document covers the portability considerations for dotfiles scripts, particularly the VA.gov project startup scripts, and proposes better organization strategies.

---

## Portability Analysis

### What Makes a Script Portable?

A portable script can run successfully on different machines with minimal modification. Key characteristics:

1. **No hardcoded paths** - Uses configuration files or environment variables
2. **Cross-platform compatibility** - Handles OS differences (macOS, Linux, Windows)
3. **Dependency checking** - Validates required tools before execution
4. **Graceful fallbacks** - Provides alternatives when preferred tools aren't available
5. **Clear error messages** - Tells users exactly what's missing or misconfigured

### Current Portability Issues

#### 1. Hardcoded Directory Paths

**Problem**: Scripts assume specific directory structures

```bash
# Current approach (not portable)
VETS_API_DIR="$HOME/Code/va.gov/vets-api"
VETS_WEBSITE_DIR="$HOME/Code/va.gov/vets-website"
VETS_API_MOCKDATA_DIR="$HOME/Code/va.gov/vets-api-mockdata"
```

**Impact**:
- New team members with different directory structures must edit scripts
- Sharing scripts between machines requires manual updates
- Makes scripts fragile and hard to maintain

**Files affected**:
- `scripts/vets-api/start-vets-api.sh`
- `scripts/vets-website/start-vets-website.sh`
- `scripts/content-build/start-content-build.sh`
- `scripts/start-all-vets.sh`

#### 2. Terminal-Specific Code

**Problem**: Opens new terminal tabs using terminal-specific commands

```bash
# From terminal_helpers.sh
open_terminal_tab() {
  case "$TERMINAL_APP" in
    ghostty)   # Ghostty-specific command ;;
    hyper)     # Hyper-specific command ;;
    iterm2)    # iTerm2-specific command ;;
  esac
}
```

**Impact**:
- Only works on macOS
- Requires specific terminal emulators
- Won't work in CI/CD or remote environments

**Why it's acceptable**: These are local development workflow scripts, not deployment scripts. Terminal integration is a feature, not a bug.

#### 3. macOS-Specific Commands

**Problem**: Uses macOS-specific tools

```bash
# GNU sed vs BSD sed
if command -v gsed &> /dev/null; then
  gsed -i "pattern" file
else
  sed -i '' "pattern" file  # macOS version
fi
```

**Impact**:
- Won't work on Linux without GNU coreutils
- Different behavior across systems

**Current handling**: Scripts already check for `gsed` and fall back to `sed`, which is good!

#### 4. Work-Specific Configuration

**Problem**: Hardcoded work environment assumptions

```bash
# JFrog proxy URLs
source 'https://jfrog.accenturefederaldev.com/artifactory/afs-gems-proxy/'

# AIO gateway URLs
AIO_URL="http://apigw-${username}.ld.afsp.io:32512/vets-service/v1/"
```

**Impact**:
- Scripts only work for specific organization
- Can't be shared with external contributors
- Mixes work-specific and general-purpose code

---

## Current Script Organization

### Directory Structure (As-Is)

```
scripts/
├── lib/                          # ✅ Good: Reusable helpers
│   ├── bootstrap_helpers.sh
│   ├── terminal_helpers.sh
│   └── ...
├── tests/                        # ✅ Good: Unit tests
├── vets-api/                     # ⚠️  Work-specific project
│   └── start-vets-api.sh
├── vets-website/                 # ⚠️  Work-specific project
│   ├── start-vets-website.sh
│   └── *.md
├── content-build/                # ⚠️  Work-specific project
│   └── start-content-build.sh
├── start-all-vets.sh            # ⚠️  Work-specific orchestrator
├── setup_work_configs.sh         # ⚠️  Work-specific setup
├── install_zscaler_cert.sh       # ⚠️  Work-specific tool
├── install_claude_code.sh        # ⚠️  Work-specific tool
├── macos.sh                      # ✅ Good: Platform-specific
├── bootstrap.sh                  # ✅ Good: Core dotfiles
├── verify.sh                     # ✅ Good: Core dotfiles
└── ...
```

### Issues with Current Organization

1. **Work and personal scripts mixed** - Hard to separate work-specific from general dotfiles
2. **Flat structure at root** - Many top-level scripts without clear grouping
3. **No configuration layer** - Each script hardcodes its own paths
4. **Inconsistent naming** - `start-vets-api.sh` vs `setup_work_configs.sh` (dash vs underscore)

---

## Proposed Improvements

### 1. Configuration-Based Project Paths

Create a configuration file that scripts can source for project locations.

#### Create `config/projects.env`

```bash
# VA.gov project locations
# Edit this file to match your directory structure

# Base directory for VA.gov projects
VAGOVDEV_BASE="${HOME}/Code/va.gov"

# Individual project directories
VETS_API_DIR="${VAGOVDEV_BASE}/vets-api"
VETS_WEBSITE_DIR="${VAGOVDEV_BASE}/vets-website"
CONTENT_BUILD_DIR="${VAGOVDEV_BASE}/content-build"
VETS_API_MOCKDATA_DIR="${VAGOVDEV_BASE}/vets-api-mockdata"

# Optional: Override any of the above in your local file
# This file is git-ignored
if [ -f "${DOTFILES_DIR:-$HOME/dotfiles}/config/projects.local.env" ]; then
  source "${DOTFILES_DIR:-$HOME/dotfiles}/config/projects.local.env"
fi
```

#### Usage in Scripts

```bash
#!/bin/bash
# Start vets-api with configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source project configuration
if [ -f "$DOTFILES_DIR/config/projects.env" ]; then
  source "$DOTFILES_DIR/config/projects.env"
else
  echo "ERROR: Configuration file not found"
  echo "Please copy config/projects.env.example to config/projects.env"
  exit 1
fi

# Now use configured paths
cd "$VETS_API_DIR" || exit 1
```

#### Benefits

- ✅ Single source of truth for project paths
- ✅ Easy for new team members to configure
- ✅ Supports multiple machines with different structures
- ✅ Git-ignored local overrides for machine-specific paths

### 2. Reorganized Directory Structure

#### Proposed Structure

```
scripts/
├── lib/                          # Reusable helper libraries
│   ├── bootstrap_helpers.sh
│   ├── terminal_helpers.sh
│   ├── project_helpers.sh        # NEW: Project path resolution
│   └── ...
├── tests/                        # Unit tests
│   └── ...
├── work/                         # NEW: Work-specific scripts
│   ├── setup/                    # Initial setup scripts
│   │   ├── setup-work-configs.sh
│   │   ├── install-zscaler-cert.sh
│   │   ├── install-claude-code.sh
│   │   └── install-vscode-extensions.sh
│   ├── vagovdev/                 # VA.gov development workflows
│   │   ├── start-vets-api.sh
│   │   ├── start-vets-website.sh
│   │   ├── start-content-build.sh
│   │   ├── start-all.sh
│   │   └── docs/                 # Project-specific docs
│   │       ├── vets-api.md
│   │       ├── vets-website.md
│   │       └── content-build.md
│   └── README.md                 # Work-specific documentation
├── system/                       # NEW: System/platform scripts
│   ├── macos.sh
│   ├── linux.sh
│   └── README.md
├── dev/                          # NEW: General dev workflows
│   ├── setup-gpg-signing.sh
│   ├── verify-git-signing.sh
│   └── README.md
├── core/                         # NEW: Core dotfiles scripts
│   ├── bootstrap.sh
│   ├── verify.sh
│   ├── update.sh
│   ├── cleanup.sh
│   └── README.md
├── maintenance/                  # NEW: Maintenance utilities
│   ├── status.sh
│   ├── profile.sh
│   ├── secrets.sh
│   └── README.md
├── README.md                     # Main scripts documentation
└── PORTABILITY.md                # This document
```

#### Migration Notes

**Backward Compatibility**:
- Keep symlinks at old locations pointing to new ones
- Update aliases gradually
- Add deprecation warnings to old script locations

**Example Symlink**:
```bash
# Keep old location working
ln -s work/vagovdev/start-vets-api.sh scripts/vets-api/start-vets-api.sh
```

### 3. Script Naming Conventions

Standardize on consistent naming:

#### Use Dashes (Preferred)

```bash
# Good: Consistent with CLI conventions
start-vets-api.sh
setup-work-configs.sh
install-zscaler-cert.sh
verify-git-signing.sh
```

#### Rationale

- More readable with multiple words
- Standard in Unix/Linux tools
- Easier to tab-complete
- Matches existing `bootstrap.sh`, `verify.sh` pattern

### 4. Portable Script Template

#### Template for New Scripts

```bash
#!/usr/bin/env bash
#
# Script: script-name.sh
# Description: Brief description of what this script does
# Category: [work|system|dev|core|maintenance]
# Portability: [portable|macos-only|work-only]
#
# Usage:
#   bash script-name.sh [options]
#
# Requirements:
#   - tool1 (check with: command -v tool1)
#   - tool2 (install with: brew install tool2)
#
# Configuration:
#   - Reads from: config/projects.env
#   - Environment variables: VAR1, VAR2

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script metadata
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Source helpers
if [[ -f "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh" ]]; then
  source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
else
  # Minimal fallback functions
  info() { echo "ℹ️  $*"; }
  success() { echo "✅ $*"; }
  warn() { echo "⚠️  $*" >&2; }
  error() { echo "❌ $*" >&2; exit 1; }
fi

# Check dependencies
check_dependencies() {
  local missing=()

  for cmd in tool1 tool2; do
    if ! command -v "$cmd" &> /dev/null; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    error "Missing required tools: ${missing[*]}"
  fi
}

# Load configuration
load_config() {
  local config_file="$DOTFILES_DIR/config/projects.env"

  if [[ -f "$config_file" ]]; then
    source "$config_file"
  else
    warn "Configuration not found: $config_file"
    info "Using default values..."
  fi
}

# Main function
main() {
  info "Starting $SCRIPT_NAME..."

  check_dependencies
  load_config

  # Do work here

  success "Completed successfully"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

### 5. Work-Specific vs General Scripts

#### Clear Separation

**Work-specific scripts** (`scripts/work/`):
- VA.gov project workflows
- Corporate tool installation
- Proxy/certificate configuration
- Internal service URLs

**General scripts** (`scripts/core/`, `scripts/dev/`):
- Dotfiles bootstrap/verify
- Git configuration
- Shell setup
- Cross-platform system setup

#### Benefits

- Easier to fork dotfiles for personal use
- Clear licensing boundaries
- Simpler onboarding documentation
- Can share core dotfiles publicly while keeping work scripts private

---

## Implementation Guide

### Phase 1: Add Configuration Layer (Non-Breaking)

1. Create `config/projects.env.example` with documented defaults
2. Create `config/projects.env` (git-ignored)
3. Update `.gitignore` to exclude `config/*.local.env`
4. Document in README how to set up configuration

### Phase 2: Update Scripts to Use Configuration (Non-Breaking)

1. Modify existing scripts to source `config/projects.env`
2. Keep hardcoded defaults as fallbacks
3. Add warnings when using fallback paths
4. Test on multiple machines

### Phase 3: Reorganize Directory Structure (Breaking)

1. Create new directory structure
2. Move scripts to new locations
3. Create symlinks at old locations
4. Update documentation
5. Add deprecation notices to old locations
6. Update shell aliases

### Phase 4: Clean Up (After Transition Period)

1. Remove symlinks
2. Remove old directory structure
3. Update all documentation
4. Remove deprecation warnings

### Testing Strategy

#### Before Each Phase

```bash
# Run test suite
bats scripts/tests/

# Verify on clean machine (VM or Docker)
# Test basic workflows:
./scripts/core/bootstrap.sh
./scripts/core/verify.sh
./scripts/work/vagovdev/start-vets-api.sh
```

#### Portability Checklist

- [ ] No hardcoded paths (use config)
- [ ] Dependencies clearly documented
- [ ] Graceful fallbacks for missing tools
- [ ] Platform detection when needed
- [ ] Works on fresh clone of dotfiles
- [ ] Works with different directory structures

---

## Best Practices for Portable Scripts

### 1. Use Configuration, Not Hardcoding

```bash
# Bad
cd "$HOME/Code/va.gov/vets-api"

# Good
source "$DOTFILES_DIR/config/projects.env"
cd "$VETS_API_DIR" || error "Cannot find vets-api directory"
```

### 2. Check Dependencies Early

```bash
# Check required tools before doing work
check_dependencies() {
  local required=(ruby node postgres redis)
  local missing=()

  for tool in "${required[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      missing+=("$tool")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    error "Missing required tools: ${missing[*]}"
    info "Install with: brew install ${missing[*]}"
    exit 1
  fi
}
```

### 3. Provide Clear Error Messages

```bash
# Bad
cd "$VETS_API_DIR"

# Good
if [ ! -d "$VETS_API_DIR" ]; then
  error "vets-api directory not found at: $VETS_API_DIR"
  info "Update VETS_API_DIR in: $DOTFILES_DIR/config/projects.env"
  exit 1
fi
cd "$VETS_API_DIR"
```

### 4. Handle Platform Differences

```bash
# Handle sed differences
if command -v gsed &> /dev/null; then
  SED_CMD="gsed"
else
  SED_CMD="sed"
  # macOS sed requires -i ''
  SED_INPLACE_FLAG="-i ''"
fi

$SED_CMD $SED_INPLACE_FLAG "s/pattern/replacement/" file
```

### 5. Make Terminal Features Optional

```bash
# Open in new tab if terminal helpers available
if command -v open_terminal_tab &> /dev/null; then
  open_terminal_tab "rails server"
else
  # Fallback: Run in current terminal
  info "Terminal helpers not available, running in current shell"
  rails server
fi
```

### 6. Use Environment Variable Overrides

```bash
# Allow override via environment variable
VETS_API_DIR="${VETS_API_DIR:-$HOME/Code/va.gov/vets-api}"

# Or even better: load from config with env override
load_config
VETS_API_DIR="${VETS_API_DIR:-${VAGOVDEV_BASE}/vets-api}"
```

### 7. Document Everything

```yaml
# In script header
# Requirements:
#   - Ruby 3.3.6 (install: rvm install 3.3.6)
#   - PostgreSQL (install: brew install postgresql)
#   - Redis (install: brew install redis)
#
# Configuration:
#   - Edit: config/projects.env
#   - Set: VETS_API_DIR to your vets-api location
#
# Portability:
#   - macOS only (uses terminal_helpers.sh)
#   - Requires work proxy configuration
```

---

## Current Portability Status

### Highly Portable (Works Anywhere)

- `scripts/lib/bootstrap_helpers.sh` - Pure shell functions
- `scripts/lib/verify_helpers.sh` - Checking logic only
- `scripts/tests/*.bats` - Test files (portable with bats)

### Moderately Portable (Minor Changes Needed)

- `scripts/macos.sh` - Platform-specific by design
- `scripts/setup_gpg_signing.sh` - Needs GPG installed
- `scripts/verify_git_signing.sh` - Needs Git configured

### Low Portability (Work-Specific)

- `scripts/vets-api/start-vets-api.sh` - Hardcoded paths, JFrog proxy
- `scripts/vets-website/start-vets-website.sh` - Hardcoded paths, work proxy
- `scripts/content-build/start-content-build.sh` - Hardcoded paths
- `scripts/setup_work_configs.sh` - Work-specific configuration
- `scripts/install_zscaler_cert.sh` - Corporate certificate

### Not Portable (By Design)

- `scripts/start-all-vets.sh` - Orchestrates work projects
- Terminal integration features - macOS local development only

---

## Related Documentation

- [Scripts README](../scripts/README.md) - Main scripts documentation
- [Work Setup Guide](work-setup-complete.md) - End-to-end work machine setup
- [VA.gov Development](vets-api.md) - Project-specific workflows

---

## Questions & Considerations

### Q: Should startup scripts be portable?

**A**: It depends on the audience:

- **Team scripts** (current): Optimized for local development workflow, team-specific configuration is acceptable
- **Open-source scripts**: Should be highly portable with minimal dependencies
- **Our approach**: Document portability level, provide configuration layer for paths

### Q: What about CI/CD usage?

**A**: Startup scripts are designed for local development with terminal integration. For CI/CD:
- Create separate CI-specific scripts
- Use Docker containers with fixed paths
- Or parameterize startup scripts to skip interactive features

### Q: Should we separate work and personal dotfiles?

**A**: Possible approaches:

1. **Current**: Single repo with work-specific subdirectory
2. **Separate repos**: Fork for personal use, keep work private
3. **Modular**: Core dotfiles + work-specific plugin

**Recommendation**: Use current approach with clear separation in `scripts/work/`

---

*This document will be updated as portability improvements are implemented.*
