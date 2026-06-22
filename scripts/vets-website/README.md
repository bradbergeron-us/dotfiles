# Vets-Website Development Scripts

Personal workflow scripts for running vets-website with jfrog proxy.

## Location
These scripts live in `~/dotfiles/scripts/vets-website/` (version controlled with your dotfiles)

## Scripts

### `start-vets-website.sh`
Full setup and start script. Use this:
- On first setup
- To pull latest changes and update dependencies
- When dependencies seem broken

**What it does:**
1. Pulls latest changes from `main` (if on main branch with no uncommitted changes)
2. Installs/updates dependencies via jfrog proxy
3. Starts the dev server

```bash
~/dotfiles/scripts/vets-website/start-vets-website.sh
# Or with alias: vets-start
```

### `dev.sh`
Quick start for daily development. Assumes dependencies are already installed.

```bash
# Start with default apps
~/dotfiles/scripts/vets-website/dev.sh
# Or with alias: vets-dev

# Start with specific apps
vets-dev --entry=auth,profile,static-pages

# Start with remote API
vets-dev --entry=auth,profile --api=https://dev-api.va.gov
```

## Creating Aliases (Recommended)

Add to your `~/.zshrc.local`:

```bash
# Vets-website aliases
alias vets-start="~/dotfiles/scripts/vets-website/start-vets-website.sh"
alias vets-dev="~/dotfiles/scripts/vets-website/dev.sh"
alias vets-cd="cd ~/Code/va.gov/vets-website"
```

Then reload your shell:
```bash
source ~/.zshrc
```

Now you can use:
```bash
vets-start      # Full setup and start
vets-dev        # Quick start
vets-cd         # Jump to vets-website directory
```

## Configuration

Both scripts look for vets-website at:
```
~/Code/va.gov/vets-website
```

If your vets-website is in a different location, edit the `VETS_WEBSITE_DIR` variable in both scripts.

## Documentation

See the other markdown files in this directory for detailed documentation:
- `QUICK-REFERENCE.md` - Command cheat sheet
- `SCRIPT-COMPARISON.md` - Detailed comparison of vets-start vs vets-dev
- `STARTUP-INSTRUCTIONS.md` - Complete setup and usage instructions
