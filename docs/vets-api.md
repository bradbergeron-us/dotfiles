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
- **gsed** (GNU sed) - install via `brew install gsed`
- **jfrog proxy configured** for gem installation
- **vets-api repository** cloned to `~/Code/va.gov/vets-api`
- **vets-api-mockdata repository** cloned to `~/Code/va.gov/vets-api-mockdata`

### JFrog Proxy Configuration

The script automatically configures the `Gemfile` to use the corporate jfrog proxy instead of rubygems.org:

```
https://jfrog.accenturefederaldev.com/artifactory/afs-gems-proxy/
```

This replacement happens automatically each time the script runs.

---

## Available Scripts

### `start-vets-api.sh` - Full Setup

The comprehensive daily startup script that syncs everything.

**What it does:**

1. Checks vets-api git status and branch
2. **Checks out and pulls latest from `origin/master`** (if no uncommitted changes)
3. **Interactive branch selection** - prompts to run server on a different branch
4. Updates vets-api-mockdata repository (from master)
5. Runs `make_table.rb` to generate mock data tables
6. Validates Ruby version
7. **Configures Gemfile and Bundler to use jfrog proxy** (replaces rubygems.org, sets mirror)
8. **Optionally installs/updates bundle dependencies** (only prompts if gems are out of date)
9. Starts the Rails server with foreman in a new Hyper tab

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

### 2. Configure Shell Aliases

Add the vets-api alias to your `~/.zshrc.local` file for quick access:

```bash
# Vets-api development workflow
alias vets-api-start="~/dotfiles/scripts/vets-api/start-vets-api.sh"
alias vets-api-cd="cd ~/Code/va.gov/vets-api"
```

Then reload your shell:

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
- Checkout and pull latest changes from master branch
- Prompt for branch selection (run server on different branch if needed)
- Update vets-api-mockdata repository
- Generate mock data tables
- Update bundle dependencies
- Start the Rails server in a new Hyper tab

Expected output:
```
→ Checking vets-api git status...
  Current branch: feature-branch
  Switching to master branch...
  ✓ Switched to master
  Pulling latest changes from origin/master...
  ✓ Successfully pulled from master

→ Branch selection for Rails server...
  Current branch: master

Run Rails server on a different branch? (y/N): y

Enter branch name: feature/my-work
  Switching to branch: feature/my-work
  ✓ Switched to feature/my-work

  → Rails server will run on branch: feature/my-work

→ Updating vets-api-mockdata...
  Current branch: master
  Pulling latest mockdata changes...
  ✓ Successfully pulled mockdata

→ Running make_table.rb...
  ✓ Mock data table generated

→ Checking Ruby version...
  Ruby version: ruby 3.3.6

→ Configuring Gemfile for jfrog proxy...
  ✓ Gemfile configured for jfrog proxy

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

## Branch Management

The `vets-api-start` script provides intelligent branch management:

### Default Behavior: Checkout and Pull Master

By default, the script:
1. Checks out the `master` branch (unless you have uncommitted changes)
2. Pulls the latest changes from `origin/master`
3. Prompts you to optionally switch to a different branch for the server

```
→ Checking vets-api git status...
  Current branch: feature/old-work
  Switching to master branch...
  ✓ Switched to master
  Pulling latest changes from origin/master...
  ✓ Successfully pulled from master

→ Branch selection for Rails server...
  Current branch: master

Run Rails server on a different branch? (y/N):
```

### Interactive Branch Selection

After pulling master, you can choose to run the server on a different branch:

**Option 1: Stay on master (default)**
```
Run Rails server on a different branch? (y/N): n
  → Rails server will run on branch: master
```

**Option 2: Switch to feature branch**
```
Run Rails server on a different branch? (y/N): y

Enter branch name: feature/my-api-changes
  Switching to branch: feature/my-api-changes
  ✓ Switched to feature/my-api-changes
  → Rails server will run on branch: feature/my-api-changes
```

### ⚠️ Uncommitted Changes

If you have uncommitted changes, the script skips all git operations:

```
→ Checking vets-api git status...
  Current branch: feature/my-work
  ⚠ You have uncommitted changes
  Skipping git operations (commit or stash your changes first)
```

**Result**: Server runs on your current branch with uncommitted changes intact.

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

If you see gem installation errors related to rubygems.org:

```
Retrying fetcher due to error (2/4): Bundler::HTTPError Could not fetch specs from https://rubygems.org/
```

**Solution**: The script automatically configures the Gemfile to use jfrog proxy. If you see this error, the replacement may have failed. Manually check your Gemfile source:

```bash
cd ~/Code/va.gov/vets-api
# Check current source
grep "source" Gemfile

# Should be using jfrog proxy:
source 'https://jfrog.accenturefederaldev.com/artifactory/afs-gems-proxy/'

# If not, manually replace:
gsed -i "s/rubygems\.org/jfrog.accenturefederaldev.com\/artifactory\/afs-gems-proxy/g" Gemfile
```

For other gem installation errors:

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
