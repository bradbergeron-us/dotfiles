# vets-start vs vets-dev - Quick Comparison

## Side-by-Side Comparison

| Feature | `vets-start` | `vets-dev` |
|---------|-------------|-----------|
| **Git pull** | ✅ Yes (if on main) | ❌ No |
| **Install dependencies** | ✅ Yes | ❌ No |
| **Start dev server** | ✅ Yes | ✅ Yes |
| **Time to run** | 3-5 minutes | 5-15 seconds |
| **Use frequency** | Weekly/when needed | Daily |

## Detailed Breakdown

### `vets-start` - Full Sync & Setup

**Steps performed:**
1. Check git status
2. **Pull latest from main** (if on main branch with clean working tree)
3. Check Node/Yarn versions
4. **Install/update dependencies** via jfrog proxy
5. Start dev server

**Best for:**
- Monday morning "get everything up to date" routine
- After being away from the project for a while
- When you see dependency errors
- First time setup

**Example scenarios:**
```bash
# Monday morning - sync everything
git checkout main
vets-start

# After vacation - get latest everything
vets-start

# Saw "Cannot find module" error
vets-start
```

### `vets-dev` - Quick Start

**Steps performed:**
1. Navigate to project directory
2. Start dev server

**Best for:**
- Daily development (Tuesday-Friday)
- Restarting after making changes
- When you know dependencies are current
- Quick iteration

**Example scenarios:**
```bash
# Starting work in the morning (no updates needed)
vets-dev

# Restarting after making changes
vets-dev --entry=profile,auth

# Testing with remote API
vets-dev --api=https://dev-api.va.gov
```

## Weekly Workflow Example

**Monday:**
```bash
vets-start  # Pull latest + update everything
# Work all day...
```

**Tuesday-Friday:**
```bash
vets-dev    # Just start server, fast!
# Work all day...
```

**After pulling changes yourself:**
```bash
git pull
# If package.json changed:
vets-start  # Update dependencies

# If only code changed:
vets-dev    # Just restart server
```

## Git Pull Behavior in vets-start

The script handles different scenarios automatically:

### ✅ Clean main branch
```
Current branch: main
No uncommitted changes
→ Automatically pulls from origin/main
```

### ⚠️  Uncommitted changes
```
Current branch: main
You have uncommitted changes
→ Skips git pull (commit or stash first)
```

### ⚠️  Feature branch
```
Current branch: feature/my-work
→ Skips git pull (not on main)
→ Tip shown to manually checkout main if needed
```

## Quick Decision Guide

**Use `vets-start` when:**
- It's Monday morning
- You haven't worked on the project in days
- package.json or yarn.lock changed
- You see module/dependency errors
- You want to sync with latest main

**Use `vets-dev` when:**
- You're in the middle of active development
- You just need to restart the server
- Dependencies are already current
- You want to be coding in 10 seconds

## TL;DR

**`vets-start`**: "Update everything and get me ready to work" (slow, thorough)
**`vets-dev`**: "Just start the damn server" (fast, minimal)
