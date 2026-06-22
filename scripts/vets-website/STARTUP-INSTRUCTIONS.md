# Vets-Website Startup Instructions (with jfrog proxy)

## Prerequisites

- Node.js 22.x
- Yarn 1.19.1
- jfrog proxy configured in `~/.npmrc`

## Build System Update

**Important:** The platform has migrated from webpack to esbuild. Old webpack-based instructions are obsolete.

### What Changed

- ❌ ~~webpack~~ → ✅ esbuild
- ❌ ~~`yarn watch --env entry=...`~~ → ✅ `yarn watch --entry=...`
- ❌ No need to modify `config/webpack.config.js` (file doesn't exist anymore)
- ❌ No need to install `copy-webpack-plugin`
- ❌ No need to rename patches or do complex setup

## Daily Startup

### Option 1: Use the automated scripts (Recommended)

```bash
# Full setup (Monday morning routine)
~/dotfiles/scripts/vets-website/start-vets-website.sh
# Or: vets-start

# Quick start (daily use)
~/dotfiles/scripts/vets-website/dev.sh
# Or: vets-dev
```

The full `start-vets-website.sh` script will:
1. Pull latest changes from main (if on main branch with clean working tree)
2. Check your Node and Yarn versions
3. Install dependencies via jfrog proxy
4. Start the dev server with common applications

### Option 2: Manual commands

If you prefer to run commands manually:

```bash
cd ~/Code/va.gov/vets-website

# Pull latest and install dependencies
git pull
NODE_TLS_REJECT_UNAUTHORIZED=0 yarn install-safe

# Start the dev server with specific applications
yarn watch --entry=auth,login-page,profile,static-pages

# Or with all education benefit apps
yarn watch --entry=auth,login-page,profile,static-pages,terms-of-use,verify,virtual-agent,1990ez-edu-benefits,toe,survivor-dependent-education-benefit-22-5490,1995-edu-benefits,10297-edu-benefits,enrollment-verification,education-letters
```

## Common Commands

| Task | Command |
|------|---------|
| Install dependencies | `NODE_TLS_REJECT_UNAUTHORIZED=0 yarn install-safe` |
| List available apps | `yarn apps` |
| Start dev server (all apps) | `yarn watch` |
| Start dev server (specific apps) | `yarn watch --entry=app1,app2,app3` |
| Build for production | `yarn build` |
| Run tests | `yarn test` |
| Start with remote API | `yarn watch --api=https://dev-api.va.gov` |

## Understanding `yarn install-safe`

This command is equivalent to:
```bash
yarn install --ignore-scripts && yarn postinstall
```

It's more secure because:
- `--ignore-scripts` prevents potentially untrusted scripts from running during install
- The custom `postinstall` script only runs scripts from trusted packages

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

### Example: Watch specific apps with remote API

```bash
yarn watch --entry=auth,profile --api=https://dev-api.va.gov
```

**Note:** When using a non-local API, you'll need to disable CORS in your browser.

## Finding Application Entry Names

Each application has a `manifest.json` file that contains its `entryName`. You can:

1. List all apps:
   ```bash
   yarn apps
   ```

2. Or search manually:
   ```bash
   find src/applications -name "manifest.json" -exec grep -l "entryName" {} \;
   ```

## Troubleshooting

### Certificate/SSL Issues with jfrog

If you get SSL errors, ensure your command includes:
```bash
NODE_TLS_REJECT_UNAUTHORIZED=0
```

This is already included in the automated scripts.

### Dependencies out of sync

If you see weird errors after pulling changes:
```bash
# Clean and reinstall
cd ~/Code/va.gov/vets-website
rm -rf node_modules yarn.lock
NODE_TLS_REJECT_UNAUTHORIZED=0 yarn install-safe
```

### Cypress binary not installed

The postinstall script should handle this, but if needed:
```bash
npx cypress install
```

## What Happened to the Old Webpack Instructions?

Old webpack-based instructions are obsolete. Here's the mapping:

| Old (webpack) | New (esbuild) | Notes |
|---------------|---------------|-------|
| Remove yarn.lock & node_modules | Not needed | Clean install only when dependencies are broken |
| Rename patches | Not needed | Patches directory doesn't exist anymore |
| Install copy-webpack-plugin | Not needed | esbuild doesn't use webpack plugins |
| Edit webpack.config.js | Not needed | File doesn't exist; esbuild config is different |
| yarn watch --env entry=... | yarn watch --entry=... | Changed from --env to --entry |
| Complex postinstall | yarn install-safe | Simplified and secured |

## Additional Resources

- [Platform Documentation](https://depo-platform-documentation.scrollhelp.site/developer-docs/Setting-up-your-local-frontend-environment.1844215878.html)
- [esbuild Documentation](https://esbuild.github.io)
- Main README: `~/Code/va.gov/vets-website/README.md`
- Script comparison: `SCRIPT-COMPARISON.md` in this directory
