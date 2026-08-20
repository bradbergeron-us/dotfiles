# Project Configuration

Guide to configuring project paths for VA.gov development scripts.

---

## Overview

The dotfiles use a centralized configuration file (`config/projects.env`) to define project directory locations. This eliminates hardcoded paths and makes scripts portable across different machines and directory structures.

---

## Quick Start

### 1. Check Current Configuration

The default configuration assumes projects are in `$HOME/Code/va.gov/`:

```bash
~/Code/va.gov/
├── vets-api/
├── vets-website/
├── content-build/
└── vets-api-mockdata/
```

If your directories match this structure, **no configuration needed** - scripts will work out of the box.

### 2. Custom Directory Structure

If your projects are in different locations:

**Option A: Edit config/projects.env** (affects all scripts)

```bash
cd ~/dotfiles
vim config/projects.env

# Update paths to match your structure
VAGOVDEV_BASE="${HOME}/work/va"
VETS_API_DIR="${VAGOVDEV_BASE}/vets-api"
# ...
```

**Option B: Create config/projects.local.env** (machine-specific overrides)

```bash
cd ~/dotfiles
cp config/projects.env.example config/projects.local.env
vim config/projects.local.env

# Override only what's different
VETS_API_DIR="$HOME/projects/va/vets-api"
VETS_WEBSITE_DIR="$HOME/projects/va/vets-website"
```

**Option C: Set environment variables** (session-specific)

```bash
export VETS_API_DIR="$HOME/custom/path/vets-api"
vets-api-start
```

### 3. Verify Configuration

```bash
# Source the helpers and check
source ~/dotfiles/scripts/lib/bootstrap_helpers.sh
source ~/dotfiles/scripts/lib/project_helpers.sh
setup_colors
load_project_config
show_project_config
```

Output shows current paths and which directories exist.

---

## Configuration Files

### config/projects.env

**Location**: `~/dotfiles/config/projects.env`

**Purpose**: Main configuration file defining project paths

**Tracked in git**: Yes (so default paths work for team)

**Example**:
```bash
# VA.gov Projects
VAGOVDEV_BASE="${HOME}/Code/va.gov"
VETS_API_DIR="${VAGOVDEV_BASE}/vets-api"
VETS_WEBSITE_DIR="${VAGOVDEV_BASE}/vets-website"
CONTENT_BUILD_DIR="${VAGOVDEV_BASE}/content-build"
VETS_API_MOCKDATA_DIR="${VAGOVDEV_BASE}/vets-api-mockdata"
```

### config/projects.local.env

**Location**: `~/dotfiles/config/projects.local.env`

**Purpose**: Machine-specific overrides (optional)

**Tracked in git**: No (git-ignored via `*.local` pattern)

**Example**:
```bash
# Override only vets-api location
VETS_API_DIR="$HOME/work/vets-api"

# Everything else inherits from projects.env
```

### config/projects.env.example

**Location**: `~/dotfiles/config/projects.env.example`

**Purpose**: Documented template with examples

**Tracked in git**: Yes (reference documentation)

---

## Configuration Priority

Scripts load configuration in this order (later overrides earlier):

1. **Defaults in projects.env.example**: Fallback values
2. **config/projects.env**: Main configuration
3. **config/projects.local.env**: Machine-specific overrides (if exists)
4. **Environment variables**: Session-specific overrides

Example:
```bash
# projects.env defines
VETS_API_DIR="${HOME}/Code/va.gov/vets-api"

# projects.local.env overrides
VETS_API_DIR="${HOME}/work/vets-api"

# Environment variable overrides everything
export VETS_API_DIR="${HOME}/temp/vets-api"
vets-api-start  # Uses /temp/vets-api
```

---

## Supported Variables

### VA.gov Projects

| Variable | Default | Description |
|----------|---------|-------------|
| `VAGOVDEV_BASE` | `$HOME/Code/va.gov` | Base directory for VA.gov projects |
| `VETS_API_DIR` | `${VAGOVDEV_BASE}/vets-api` | Rails backend (Ruby) |
| `VETS_WEBSITE_DIR` | `${VAGOVDEV_BASE}/vets-website` | React frontend (Node.js) |
| `CONTENT_BUILD_DIR` | `${VAGOVDEV_BASE}/content-build` | Static content generator (Node.js) |
| `VETS_API_MOCKDATA_DIR` | `${VAGOVDEV_BASE}/vets-api-mockdata` | Betamocks data repository |

### Adding New Projects

To add new project paths:

1. Edit `config/projects.env.example` to document the new variable
2. Edit `config/projects.env` to add the default value
3. Export the variable at the end of the file
4. Update `scripts/lib/project_helpers.sh` if needed

---

## Scripts Using Configuration

### Development Workflows

- `scripts/vets-api/start-vets-api.sh` - Start Rails backend
- `scripts/vets-website/start-vets-website.sh` - Start React frontend
- `scripts/content-build/start-content-build.sh` - Start content generator
- `scripts/start-all-vets.sh` - Start all services

### How Scripts Load Configuration

```bash
#!/bin/bash
# Any VA.gov development script

# Source helpers
source "$DOTFILES_DIR/scripts/lib/project_helpers.sh"

# Load configuration
load_project_config

# Validate directories exist
validate_project_dir "$VETS_API_DIR" "vets-api"

# Use configured paths
cd "$VETS_API_DIR"
bundle exec rails server
```

---

## Troubleshooting

### Script Can't Find Project Directory

**Error**:
```
ERROR: vets-api directory not found at: /Users/you/Code/va.gov/vets-api
Update project paths in: /Users/you/dotfiles/config/projects.env
```

**Solution**:
1. Check where your project actually is: `find ~ -name vets-api -type d 2>/dev/null`
2. Update `config/projects.env` or `config/projects.local.env`
3. Run script again

### Configuration Not Loading

**Error**:
```
WARN: Project configuration not found: /path/to/config/projects.env
WARN: Using legacy hardcoded paths
```

**Solution**:
1. Verify file exists: `ls ~/dotfiles/config/projects.env`
2. Check `DOTFILES_DIR` is set correctly: `echo $DOTFILES_DIR`
3. Copy example if missing: `cp ~/dotfiles/config/projects.env.example ~/dotfiles/config/projects.env`

### Wrong Directory Being Used

**Symptoms**: Script runs but uses wrong directory

**Solution**:
1. Check configuration priority (environment variables override files)
2. Verify no conflicting env vars: `env | grep VETS_`
3. Show current config: Source helpers and run `show_project_config`

### Permission Denied

**Error**:
```
Permission denied: /path/to/config/projects.env
```

**Solution**:
```bash
chmod +r ~/dotfiles/config/projects.env
```

---

## Migration from Hardcoded Paths

### Old Approach (Hardcoded)

```bash
# In script
VETS_API_DIR="$HOME/Code/va.gov/vets-api"

if [ ! -d "$VETS_API_DIR" ]; then
  echo "ERROR: Update VETS_API_DIR in this script"
  exit 1
fi
```

### New Approach (Configuration)

```bash
# In script
source "$DOTFILES_DIR/scripts/lib/project_helpers.sh"
load_project_config
validate_project_dir "$VETS_API_DIR" "vets-api"
```

### Migration Benefits

- ✅ Configure once in one place
- ✅ Works across all scripts
- ✅ Easy to share configs between machines
- ✅ Better error messages
- ✅ Supports machine-specific overrides

### Backward Compatibility

Scripts still work if `config/projects.env` doesn't exist:
- Falls back to legacy hardcoded paths with warning
- Gives clear instructions to create configuration
- No breaking changes for existing users

---

## Best Practices

### For Team Members

1. **Default setup**: Use `config/projects.env` with standard paths
2. **Custom paths**: Create `config/projects.local.env` for overrides
3. **Multiple machines**: Sync `projects.env` via dotfiles, use `projects.local.env` for differences
4. **Temporary changes**: Use environment variables, don't edit config files

### For Script Authors

1. **Always load config**: Source `project_helpers.sh` and call `load_project_config`
2. **Validate directories**: Use `validate_project_dir` before `cd`
3. **Clear errors**: Let validation helper provide error messages
4. **Document variables**: Add new paths to `projects.env.example`

### For Different Machines

**Work laptop**:
```bash
# config/projects.local.env
VAGOVDEV_BASE="$HOME/Code/va.gov"
```

**Personal laptop**:
```bash
# config/projects.local.env
VAGOVDEV_BASE="$HOME/projects/va"
```

**VM/container**:
```bash
# config/projects.local.env
VAGOVDEV_BASE="/workspace/va"
```

---

## Examples

### Scenario 1: Standard Setup

Your directories match the default structure.

**Action**: None needed - scripts work out of the box

### Scenario 2: Custom Base Directory

All projects in `~/work/va/` instead of `~/Code/va.gov/`

**Solution**:
```bash
# config/projects.local.env
VAGOVDEV_BASE="$HOME/work/va"
# All other paths inherit: $VAGOVDEV_BASE/vets-api, etc.
```

### Scenario 3: Mixed Directory Structure

Projects scattered across different locations.

**Solution**:
```bash
# config/projects.local.env
VETS_API_DIR="$HOME/work/backend/vets-api"
VETS_WEBSITE_DIR="$HOME/projects/frontend/vets-website"
CONTENT_BUILD_DIR="/opt/va/content-build"
VETS_API_MOCKDATA_DIR="$HOME/data/vets-api-mockdata"
```

### Scenario 4: Temporary Override

Test a feature branch in a different directory.

**Solution**:
```bash
# Terminal session
export VETS_API_DIR="$HOME/temp/vets-api-feature-xyz"
vets-api-start
# Uses temporary directory, doesn't affect other terminals
```

### Scenario 5: Multiple VA.gov Environments

Development and staging checkouts.

**Solution**:
```bash
# Use environment variables to switch
alias vets-dev="VAGOVDEV_BASE=$HOME/Code/va.gov vets-api-start"
alias vets-staging="VAGOVDEV_BASE=$HOME/Code/va.gov-staging vets-api-start"
```

---

## Related Documentation

- [Script Portability](scripts-portability.md) - Why configuration system was added
- [VA.gov Development](vets-api.md) - Using vets-api startup script
- [Scripts README](https://github.com/bradbergeron-us/dotfiles/blob/main/scripts/README.md) - All available scripts

---

*Last updated: July 24, 2026*
