# Vets-Website Quick Reference

## Daily Workflow

```bash
# Pull latest + update dependencies + start (Monday morning routine)
~/dotfiles/scripts/vets-website/start-vets-website.sh
# Or: vets-start

# Quick daily start - assumes dependencies are current (most common)
~/dotfiles/scripts/vets-website/dev.sh
# Or: vets-dev

# With specific apps
vets-dev --entry=auth,profile,static-pages

# With remote API
vets-dev --entry=auth,profile --api=https://dev-api.va.gov
```

## Recommended Shell Aliases

Add to `~/.zshrc.local`:
```bash
alias vets-start="~/dotfiles/scripts/vets-website/start-vets-website.sh"
alias vets-dev="~/dotfiles/scripts/vets-website/dev.sh"
alias vets-cd="cd ~/Code/va.gov/vets-website"
```

## Common Manual Commands

```bash
cd ~/Code/va.gov/vets-website

# Install/update dependencies
NODE_TLS_REJECT_UNAUTHORIZED=0 yarn install-safe

# List available apps
yarn apps

# Start dev server
yarn watch --entry=auth,profile,static-pages

# Run tests
yarn test

# Build for production
yarn build
```

## Key Changes from Webpack

| Old Command | New Command |
|-------------|-------------|
| `yarn watch --env entry=app1,app2` | `yarn watch --entry=app1,app2` |
| Edit `webpack.config.js` | Not needed (esbuild) |
| Install webpack plugins | Not needed |
| Rename patches | Not needed |

## Dev Server

- URL: `http://localhost:3001`
- Port can be changed: `yarn watch --port=3002`

## Troubleshooting

### Clean reinstall
```bash
cd ~/Code/va.gov/vets-website
rm -rf node_modules yarn.lock
NODE_TLS_REJECT_UNAUTHORIZED=0 yarn install-safe
```

### Cypress issues
```bash
npx cypress install
```

## Documentation

- Full instructions: `~/dotfiles/scripts/vets-website/STARTUP-INSTRUCTIONS.md`
- Script info: `~/dotfiles/scripts/vets-website/README.md`
- Script comparison: `~/dotfiles/scripts/vets-website/SCRIPT-COMPARISON.md`
- Repository README: `~/Code/va.gov/vets-website/README.md`
