#!/bin/bash
# Daily startup script for vets-website
# Updated for esbuild-based build system (post-webpack removal)
#
# This script handles:
# - Git pull from main (if conditions are right)
# - Clean dependency installation via jfrog proxy (configured in ~/.npmrc)
# - Starting the dev server with specific applications
#
# Usage: ~/dotfiles/scripts/vets-website/start-vets-website.sh
#        Or use alias: vets-start

set -e  # Exit on error

# Navigate to vets-website directory
VETS_WEBSITE_DIR="$HOME/Code/va.gov/vets-website"

if [ ! -d "$VETS_WEBSITE_DIR" ]; then
  echo "ERROR: vets-website directory not found at $VETS_WEBSITE_DIR"
  echo "Please update VETS_WEBSITE_DIR in this script to point to your vets-website location"
  exit 1
fi

cd "$VETS_WEBSITE_DIR"
echo "Working directory: $VETS_WEBSITE_DIR"
echo ""

echo "========================================"
echo "Starting vets-website setup..."
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Git pull from main
echo -e "${BLUE}→ Checking git status...${NC}"
CURRENT_BRANCH=$(git branch --show-current)
echo "  Current branch: $CURRENT_BRANCH"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo -e "${YELLOW}  ⚠ You have uncommitted changes${NC}"
  echo "  Skipping git pull (commit or stash your changes first)"
  echo ""
else
  if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "  Pulling latest changes from origin/main..."
    if git pull origin main; then
      echo -e "${GREEN}  ✓ Successfully pulled from main${NC}"
    else
      echo -e "${RED}  ✗ Git pull failed${NC}"
      echo "  Continuing anyway..."
    fi
  else
    echo -e "${YELLOW}  ⚠ Not on main branch${NC}"
    echo "  Tip: Run 'git checkout main && git pull' if you want latest main"
  fi
  echo ""
fi

# Check Node version
echo -e "${BLUE}→ Checking Node version...${NC}"
NODE_VERSION=$(node --version)
echo "  Node version: $NODE_VERSION (Required: >=22.0.0 <23)"
echo ""

# Check Yarn version
echo -e "${BLUE}→ Checking Yarn version...${NC}"
YARN_VERSION=$(yarn --version)
echo "  Yarn version: $YARN_VERSION (Required: 1.19.1)"
echo ""

# Install dependencies using jfrog proxy
# The --ignore-scripts flag prevents potentially untrusted scripts from running
# The postinstall script runs only trusted package postinstall scripts
echo -e "${BLUE}→ Installing dependencies via jfrog proxy...${NC}"
echo "  (This uses NODE_TLS_REJECT_UNAUTHORIZED=0 for jfrog SSL)"
NODE_TLS_REJECT_UNAUTHORIZED=0 yarn install-safe
echo ""

# Note: yarn install-safe is equivalent to:
# yarn install --ignore-scripts && yarn postinstall
# This approach is more secure as it only runs trusted postinstall scripts

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""

# Start the dev server
echo "========================================"
echo "Starting development server..."
echo "========================================"
echo ""
echo "Default applications loaded:"
echo "  - auth"
echo "  - login-page"
echo "  - profile"
echo "  - static-pages"
echo "  - terms-of-use"
echo "  - verify"
echo "  - virtual-agent"
echo ""
echo "To add more applications, edit this script and modify the --entry parameter"
echo "See available apps: yarn apps"
echo ""

# Start watch mode with specified applications
# You can customize the --entry parameter to include the apps you need
yarn watch --entry=auth,login-page,profile,static-pages,terms-of-use,verify,virtual-agent

# Alternative: Start with all education benefit apps (from your old instructions)
# yarn watch --entry=auth,login-page,profile,static-pages,terms-of-use,verify,virtual-agent,1990ez-edu-benefits,toe,survivor-dependent-education-benefit-22-5490,1995-edu-benefits,10297-edu-benefits,enrollment-verification,education-letters
