# Vets-Website Development Scripts

Automated workflow scripts for the VA.gov vets-website project with jfrog proxy support.

---

## Overview

The vets-website project has migrated from webpack to esbuild, requiring updated workflow scripts. These scripts handle the complete development lifecycle from dependency installation through dev server startup, with built-in support for corporate jfrog proxy.

**Location**: `~/dotfiles/scripts/vets-website/`

---

## Prerequisites

Before using these scripts, ensure you have:

- **Node.js** 22.x (required by vets-website)
- **Yarn** 1.19.1 (pinned version)
- **jfrog proxy configured** in `~/.npmrc`
- **vets-website repository** cloned to `~/Code/va.gov/vets-website`

### JFrog Proxy Configuration

Your `~/.npmrc` should contain:

```ini
registry=https://jfrog.accenturefederaldev.com/artifactory/api/npm/afs-npm-proxy/
//jfrog.accenturefederaldev.com/artifactory/api/npm/afs-npm-proxy/:_authToken=<your-token>
```

---

## Available Scripts

### `start-vets-website.sh` - Full Setup

The comprehensive "Monday morning" script that syncs everything.

**What it does:**

1. Checks git status and branch
2. **Checks out and pulls latest from `origin/main`** (if no uncommitted changes)
3. **Interactive branch selection** - prompts to run server on a different branch
4. Validates Node.js and Yarn versions
5. **Installs/updates dependencies** via jfrog proxy
6. Starts the dev server with default applications in a new Hyper tab

**Time**: 3-5 minutes

**Use when:**

- Starting your week (Monday morning routine)
- After being away from the project for several days
- When you see "Cannot find module" errors
- After `package.json` or `yarn.lock` changes
- First time setup

**Example:**

```bash
vets-start
# Or: ~/dotfiles/scripts/vets-website/start-vets-website.sh
```

---

### `dev.sh` - Quick Daily Start

Fast startup for active development. Assumes dependencies are current.

**What it does:**

1. Navigates to vets-website directory
2. Starts the dev server immediately

**Time**: 5-15 seconds

**Use when:**

- Daily development (Tuesday-Friday)
- Restarting the dev server during work
- Dependencies haven't changed
- You want to start coding immediately

**Example:**

```bash
# Start with default apps
vets-dev

# Start with specific apps
vets-dev --entry=auth,profile,static-pages

# Start with remote API
vets-dev --entry=auth,profile --api=https://dev-api.va.gov
```

---

## Setup

### 1. Clone the Scripts (Via Dotfiles)

These scripts are included in your dotfiles repository. After cloning or updating your dotfiles:

```bash
cd ~/dotfiles
git pull origin main
```

The scripts will be available at `~/dotfiles/scripts/vets-website/`.

### 2. Configure Shell Aliases

Add these aliases to `~/.zshrc.local` for quick access:

```bash
# Vets-website development workflow
alias vets-start="~/dotfiles/scripts/vets-website/start-vets-website.sh"
alias vets-dev="~/dotfiles/scripts/vets-website/dev.sh"
alias vets-cd="cd ~/Code/va.gov/vets-website"
```

Then reload your shell:

```bash
source ~/.zshrc
```

### 3. Customize Default Applications (Optional)

Both scripts load a default set of applications. To customize, edit the `--entry` parameter in the scripts:

**Default apps:**
```
auth, login-page, profile, static-pages, terms-of-use, verify, virtual-agent
```

**Education benefit apps (optional):**
```
1990ez-edu-benefits, toe, survivor-dependent-education-benefit-22-5490,
1995-edu-benefits, 10297-edu-benefits, enrollment-verification, education-letters
```

---

## Daily Workflow

### Monday Morning Routine

Start fresh with the latest code and dependencies:

```bash
vets-start
```

This will:
- Pull latest changes from main
- Update all dependencies
- Start the dev server

Expected output:
```
→ Checking git status...
  Current branch: main
  Pulling latest changes from origin/main...
  ✓ Successfully pulled from main

→ Checking Node version...
  Node version: v22.23.0 (Required: >=22.0.0 <23)

→ Checking Yarn version...
  Yarn version: 1.19.1 (Required: 1.19.1)

→ Installing dependencies via jfrog proxy...
  (This uses NODE_TLS_REJECT_UNAUTHORIZED=0 for jfrog SSL)

✓ Installation complete!

Starting development server...
```

### Tuesday-Friday

Quick start without updating dependencies:

```bash
vets-dev
```

### Working on Specific Apps

```bash
# Frontend features
vets-dev --entry=auth,login-page,profile

# Claims and appeals
vets-dev --entry=claims-status,0996-higher-level-review

# Education benefits
vets-dev --entry=1990ez-edu-benefits,toe,education-letters
```

### Using Remote API

When you need to test against a deployed environment:

```bash
vets-dev --entry=auth,profile --api=https://dev-api.va.gov
```

!!! warning "CORS Required"
    When using a non-local API, you must disable CORS in your browser. See the [troubleshooting section](#cors-issues) below.

---

## Branch Management

The `vets-start` script provides intelligent branch management:

### Default Behavior: Checkout and Pull Main

By default, the script:
1. Checks out the `main` branch (unless you have uncommitted changes)
2. Pulls the latest changes from `origin/main`
3. Prompts you to optionally switch to a different branch for the dev server

```
→ Checking git status...
  Current branch: feature/old-work
  Switching to main branch...
  ✓ Switched to main
  Pulling latest changes from origin/main...
  ✓ Successfully pulled from main

→ Branch selection for dev server...
  Current branch: main

Run dev server on a different branch? (y/N):
```

### Interactive Branch Selection

After pulling main, you can choose to run the server on a different branch:

**Option 1: Stay on main (default)**
```
Run dev server on a different branch? (y/N): n
  → Dev server will run on branch: main
```

**Option 2: Switch to feature branch**
```
Run dev server on a different branch? (y/N): y

Enter branch name: feature/my-ui-changes
  Switching to branch: feature/my-ui-changes
  ✓ Switched to feature/my-ui-changes
  → Dev server will run on branch: feature/my-ui-changes
```

### ⚠️ Uncommitted Changes

If you have uncommitted changes, the script skips all git operations:

```
→ Checking git status...
  Current branch: feature/my-work
  ⚠ You have uncommitted changes
  Skipping git operations (commit or stash your changes first)
```

**Result**: Server runs on your current branch with uncommitted changes intact.

---

## Dev Server

The dev server runs on `http://localhost:3001` by default.

### Available Options

```bash
yarn watch [options]

Options:
  --entry=<apps>              Comma-separated list of app entry names
  --api=<url>                 Remote API URL (proxied through dev server)
  --port=<num>                Dev server port (default: 3001)
  --host=<addr>               Dev server host (default: 127.0.0.1)
  --scaffold                  Generate HTML scaffold pages
  --verbose                   Show all esbuild output
  --local-proxy-rewrite       Enable proxy for testing injected header/footer
```

### Finding Application Names

List all available applications:

```bash
cd ~/Code/va.gov/vets-website
yarn apps
```

Or search for manifests:

```bash
find src/applications -name "manifest.json" -exec grep -l "entryName" {} \;
```

---

## Troubleshooting

### SSL Certificate Errors

If you see SSL errors when installing dependencies:

```
Error: unable to get local issuer certificate
```

**Solution**: The scripts automatically use `NODE_TLS_REJECT_UNAUTHORIZED=0` for jfrog proxy SSL. If you're running manual commands, ensure you include it:

```bash
NODE_TLS_REJECT_UNAUTHORIZED=0 yarn install-safe
```

### Module Not Found Errors

If you see "Cannot find module" errors:

```bash
# Clean reinstall
cd ~/Code/va.gov/vets-website
rm -rf node_modules yarn.lock
vets-start
```

Or manually:

```bash
rm -rf node_modules yarn.lock
NODE_TLS_REJECT_UNAUTHORIZED=0 yarn install-safe
```

### Port Already in Use

If port 3001 is already in use:

```
Error: listen EADDRINUSE: address already in use 127.0.0.1:3001
```

**Solution**: Kill the process using the port:

```bash
lsof -ti:3001 | xargs kill -9
```

Or use a different port:

```bash
vets-dev --port=3002
```

### Cypress Binary Not Installed

The postinstall script should handle this automatically, but if needed:

```bash
npx cypress install
```

### CORS Issues

When using a remote API (`--api=https://...`), you must disable CORS in your browser:

**Chrome/Edge:**
```bash
open -na "Google Chrome" --args --disable-web-security --user-data-dir=/tmp/chrome-dev
```

**Safari:**
Develop menu → Disable Cross-Origin Restrictions

**Firefox:**
Install a CORS extension from the Firefox Add-ons store

---

## Webpack to esbuild Migration

The vets-website project has migrated from webpack to esbuild. Old instructions are obsolete.

### What Changed

| Old (webpack) | New (esbuild) | Notes |
|---------------|---------------|-------|
| `yarn watch --env entry=...` | `yarn watch --entry=...` | Flag changed |
| Edit `webpack.config.js` | Not needed | File removed |
| Install `copy-webpack-plugin` | Not needed | No webpack plugins |
| Rename patches directory | Not needed | No patches needed |
| Complex postinstall steps | `yarn install-safe` | Simplified |

### Old Instructions (Obsolete)

If you have old setup notes that include:

- ❌ Removing and renaming patches
- ❌ Installing webpack plugins
- ❌ Modifying `webpack.config.js`
- ❌ Complex `NODE_PUPPETEER` flags

**Discard them**. The new workflow is much simpler.

---

## Understanding `yarn install-safe`

This custom command is defined in `package.json` and is equivalent to:

```bash
yarn install --ignore-scripts && yarn postinstall
```

**Why it's safer:**

- `--ignore-scripts` prevents potentially untrusted scripts from running during install
- The custom `postinstall` script only runs scripts from trusted packages
- Works correctly with jfrog proxy and corporate SSL certificates

---

## Quick Reference

### Commands

```bash
# Monday morning (full sync)
vets-start

# Daily quick start
vets-dev

# Jump to directory
vets-cd

# Manual dependency install
NODE_TLS_REJECT_UNAUTHORIZED=0 yarn install-safe

# List all apps
yarn apps

# Start with specific apps
yarn watch --entry=app1,app2,app3

# Build for production
yarn build

# Run tests
yarn test
```

### Script Comparison

| Feature | `vets-start` | `vets-dev` |
|---------|-------------|-----------|
| Git pull | ✅ Yes (if on main) | ❌ No |
| Install dependencies | ✅ Yes | ❌ No |
| Start dev server | ✅ Yes | ✅ Yes |
| Time | 3-5 minutes | 5-15 seconds |
| Use frequency | Weekly | Daily |

---

## Additional Resources

- **VA Platform Documentation**: [Setting up your local frontend environment](https://depo-platform-documentation.scrollhelp.site/developer-docs/Setting-up-your-local-frontend-environment.1844215878.html)
- **esbuild Documentation**: [esbuild.github.io](https://esbuild.github.io)
- **vets-website README**: `~/Code/va.gov/vets-website/README.md`
- **Script Documentation**: `~/dotfiles/scripts/vets-website/`
  - `README.md` - Overview
  - `QUICK-REFERENCE.md` - Command cheat sheet
  - `SCRIPT-COMPARISON.md` - Detailed comparison
  - `STARTUP-INSTRUCTIONS.md` - Complete guide

---

## Related Documentation

- [Work Machine Setup](work-machine.md) - General work machine configuration
- [Complete Work Setup Guide](work-setup-complete.md) - Full laptop setup walkthrough
- [Claude Code SSL Fix](claude-code-ssl-fix.md) - Corporate SSL certificate setup
