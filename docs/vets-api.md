# Vets-API Development Scripts

Automated workflow script for the VA.gov vets-api project.

---

## Overview

The vets-api project is a Ruby on Rails backend that powers the VA.gov platform. This script handles the complete development lifecycle from dependency installation through Rails server startup with foreman.

**Location**: `~/dotfiles/scripts/vets-api/`

---

## Prerequisites

Before using this script, ensure you have:

- **Ruby** 3.3.6 (managed via rvm)
- **PostgreSQL** (running via Docker or locally)
- **Redis** (running via Docker or locally)
- **Bundler** (Ruby dependency manager)
- **vets-api repository** cloned to `~/Code/va.gov/vets-api`
- **vets-api-mockdata repository** cloned to `~/Code/va.gov/vets-api-mockdata`

---

## Available Scripts

### `start-vets-api.sh` - Full Setup

The comprehensive daily startup script that syncs everything.

**What it does:**

1. Checks vets-api git status and branch
2. **Pulls latest from `origin/main`** (if on main with no uncommitted changes)
3. Updates vets-api-mockdata repository
4. Runs `make_table.rb` to generate mock data tables
5. Validates Ruby version
6. **Installs/updates bundle dependencies**
7. Starts the Rails server with foreman in a new Hyper tab

**Time**: 2-4 minutes

**Use when:**

- Starting your workday
- After being away from the project
- When you see "uninitialized constant" or dependency errors
- After `Gemfile` or `Gemfile.lock` changes
- First time setup

**Example:**

```bash
vets-api-start
# Or: ~/dotfiles/scripts/vets-api/start-vets-api.sh
```

---

## Setup

### 1. Clone the Scripts (Via Dotfiles)

These scripts are included in your dotfiles repository. After cloning or updating your dotfiles:

```bash
cd ~/dotfiles
git pull origin main
```

The scripts will be available at `~/dotfiles/scripts/vets-api/`.

### 2. Shell Aliases

The alias `vets-api-start` is automatically configured in `~/dotfiles/home/zsh/aliases.zsh`:

```bash
alias vets-api-start='bash ~/dotfiles/scripts/vets-api/start-vets-api.sh'
```

Reload your shell:

```bash
source ~/.zshrc
```

---

## Daily Workflow

### Starting Your Day

Start fresh with the latest code and dependencies:

```bash
vets-api-start
```

This will:
- Pull latest changes from vets-api main branch
- Update vets-api-mockdata repository
- Generate mock data tables
- Update bundle dependencies
- Start the Rails server in a new Hyper tab

Expected output:
```
→ Checking vets-api git status...
  Current branch: main
  Pulling latest changes from origin/main...
  ✓ Successfully pulled from main

→ Updating vets-api-mockdata...
  Current branch: main
  Pulling latest mockdata changes...
  ✓ Successfully pulled mockdata

→ Running make_table.rb...
  ✓ Mock data table generated

→ Checking Ruby version...
  Ruby version: ruby 3.3.6

→ Installing bundle dependencies...
  ✓ Bundle install complete

✓ Setup complete!

Rails server is running in the new Hyper tab.
```

### Server Running in Hyper Tab

The script opens a new Hyper terminal tab where you can:
- Monitor Rails server logs
- See incoming API requests
- Watch for errors and warnings
- See live reload messages when code changes

To stop the server: Press `Ctrl+C` in the Hyper tab

---

## Git Pull Behavior

The `vets-api-start` script handles git pull intelligently for both repositories:

### ✅ Clean Main Branch

```
Current branch: main
No uncommitted changes
→ Automatically pulls from origin/main
```

**Result**: Pulls latest changes automatically.

### ⚠️ Uncommitted Changes

```
Current branch: main
⚠ You have uncommitted changes
→ Skips git pull (commit or stash your changes first)
```

**Result**: Skips pull to protect your work. Commit or stash changes first.

### ⚠️ Feature Branch

```
Current branch: feature/my-work
⚠ Not on main branch
→ Skips git pull (not on main)
```

**Result**: Skips pull. Switch to main manually if you want latest.

---

## Rails Server

The Rails server runs on `http://localhost:3000` by default via foreman.

### Foreman Configuration

The script starts foreman with:

```bash
foreman start -m all=1,clamd=0,freshclam=0
```

This starts:
- Rails web server (port 3000)
- Sidekiq background job processor
- Other services (excluding clamd and freshclam)

### Useful Endpoints

Once the server is running:

- **Flipper features**: http://localhost:3000/flipper/features
- **API documentation**: http://localhost:3000/api-docs
- **Health check**: http://localhost:3000/health

---

## Mock Data

### vets-api-mockdata Repository

The script automatically:
1. Navigates to `~/Code/va.gov/vets-api-mockdata`
2. Pulls latest changes (if on main)
3. Runs `make_table.rb` to generate mock data tables

The `make_table.rb` script:
- Scans all mock data files in the repository
- Generates a markdown table in `mock_data_table.md`
- Provides an easy reference for available test data

### Manually Updating Mock Data

If you need to manually update mock data:

```bash
cd ~/Code/va.gov/vets-api-mockdata
git pull origin main
ruby make_table.rb
```

---

## Troubleshooting

### Gem Installation Errors

If you see gem installation errors:

```bash
# Clean reinstall
cd ~/Code/va.gov/vets-api
rm -rf vendor/bundle .bundle Gemfile.lock
bundle install
```

### Database Connection Errors

If you can't connect to the database:

```bash
# Check if PostgreSQL is running
lsof -ti:5432

# Or if using Docker
docker ps | grep postgres
```

Ensure your `config/settings.local.yml` has the correct database configuration.

### Redis Connection Errors

If you can't connect to Redis:

```bash
# Check if Redis is running
lsof -ti:6379

# Or if using Docker
docker ps | grep redis
```

### Port Already in Use

If port 3000 is already in use:

```
Error: Address already in use - bind(2) for 127.0.0.1:3000
```

**Solution**: Kill the process using the port:

```bash
lsof -ti:3000 | xargs kill -9
```

### Ruby Version Mismatch

If you see Ruby version errors:

```bash
# Install correct Ruby version with rvm
rvm install 3.3.6
rvm use 3.3.6

# Verify version
ruby --version
```

---

## Related Documentation

- [Vets-Website Scripts](vets-website.md) - Frontend development scripts
- [Work Machine Setup](work-machine.md) - General work machine configuration
- [Complete Work Setup Guide](work-setup-complete.md) - Full laptop setup walkthrough

---

## Quick Reference

### Commands

```bash
# Daily startup
vets-api-start

# Manual bundle install
cd ~/Code/va.gov/vets-api
bundle install

# Start foreman manually
foreman start -m all=1,clamd=0,freshclam=0

# Update mock data manually
cd ~/Code/va.gov/vets-api-mockdata
git pull origin main
ruby make_table.rb

# Run tests
cd ~/Code/va.gov/vets-api
bundle exec rspec
```

### Server Status

```bash
# Check if server is running
curl http://localhost:3000/health

# View running processes
ps aux | grep foreman

# Kill server process
lsof -ti:3000 | xargs kill -9
```
