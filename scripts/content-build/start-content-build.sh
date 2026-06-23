#!/bin/bash
# Daily startup script for content-build
#
# This script handles:
# - Git pull from main (if conditions are right)
# - Clean dependency installation via jfrog proxy (configured in ~/.npmrc)
# - Fetching Drupal cache content (optional)
# - Starting the watch server (builds static content and serves)
#
# Usage: ~/dotfiles/scripts/content-build/start-content-build.sh
#        Or use alias: content-build-start

set -e  # Exit on error

# Resolve script directory and source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
source "$DOTFILES_DIR/scripts/lib/terminal_helpers.sh"

# Ensure terminal is configured before starting
ensure_terminal_configured

# Navigate to content-build directory
CONTENT_BUILD_DIR="$HOME/Code/va.gov/content-build"

if [ ! -d "$CONTENT_BUILD_DIR" ]; then
  echo "ERROR: content-build directory not found at $CONTENT_BUILD_DIR"
  echo "Please update CONTENT_BUILD_DIR in this script to point to your content-build location"
  exit 1
fi

cd "$CONTENT_BUILD_DIR"
echo "Working directory: $CONTENT_BUILD_DIR"
echo ""

echo "========================================"
echo "Starting content-build setup..."
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Git branch management and pull from main
echo -e "${BLUE}→ Checking git status...${NC}"
CURRENT_BRANCH=$(git branch --show-current)
echo "  Current branch: $CURRENT_BRANCH"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo -e "${YELLOW}  ⚠ You have uncommitted changes${NC}"
  echo "  Skipping git operations (commit or stash your changes first)"
  echo ""
  BRANCH_TO_USE="$CURRENT_BRANCH"
else
  # Checkout and pull from main
  if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "  Switching to main branch..."
    if git checkout main; then
      echo -e "${GREEN}  ✓ Switched to main${NC}"
    else
      echo -e "${RED}  ✗ Failed to checkout main${NC}"
      echo "  Continuing with current branch: $CURRENT_BRANCH"
      BRANCH_TO_USE="$CURRENT_BRANCH"
    fi
  fi

  # Pull latest from main
  echo "  Pulling latest changes from origin/main..."
  if git pull origin main; then
    echo -e "${GREEN}  ✓ Successfully pulled from main${NC}"
  else
    echo -e "${RED}  ✗ Git pull failed${NC}"
    echo "  Continuing anyway..."
  fi
  echo ""

  # Interactive branch selection
  echo -e "${BLUE}→ Branch selection for watch server...${NC}"
  echo "  Current branch: main"
  echo ""
  read -p "Run watch server on a different branch? (y/N): " SWITCH_BRANCH

  if [[ $SWITCH_BRANCH =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Enter branch name: " BRANCH_NAME

    if [ -n "$BRANCH_NAME" ]; then
      echo "  Switching to branch: $BRANCH_NAME"
      if git checkout "$BRANCH_NAME"; then
        echo -e "${GREEN}  ✓ Switched to $BRANCH_NAME${NC}"
        BRANCH_TO_USE="$BRANCH_NAME"
      else
        echo -e "${RED}  ✗ Failed to checkout $BRANCH_NAME${NC}"
        echo "  Continuing with main branch"
        BRANCH_TO_USE="main"
      fi
    else
      echo -e "${YELLOW}  No branch name provided, using main${NC}"
      BRANCH_TO_USE="main"
    fi
  else
    BRANCH_TO_USE="main"
  fi
  echo ""
  echo -e "${GREEN}  → Watch server will run on branch: $BRANCH_TO_USE${NC}"
  echo ""
fi

# Check Node version
echo -e "${BLUE}→ Checking Node version...${NC}"
NODE_VERSION=$(node --version)
echo "  Node version: $NODE_VERSION (Required: >=22.22.0)"
echo ""

# Check Yarn version
echo -e "${BLUE}→ Checking Yarn version...${NC}"
YARN_VERSION=$(yarn --version)
echo "  Yarn version: $YARN_VERSION (Required: 1.19.1)"
echo ""

# Install dependencies using jfrog proxy
# The install-safe command handles security concerns with postinstall scripts
echo -e "${BLUE}→ Installing dependencies via jfrog proxy...${NC}"
echo "  (This uses NODE_TLS_REJECT_UNAUTHORIZED=0 for jfrog SSL)"
NODE_TLS_REJECT_UNAUTHORIZED=0 yarn install-safe
echo ""

# Note: yarn install-safe is equivalent to:
# yarn install --ignore-scripts && yarn run-postinstall
# This approach is more secure as it only runs trusted postinstall scripts

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""

# Optional: Fetch Drupal cache content
echo -e "${BLUE}→ Drupal content cache...${NC}"
echo "  Content-build can use cached Drupal content for faster builds"
echo "  The cached content is stored in .cache/localhost/"
echo ""
read -p "Fetch latest Drupal content cache from S3? (y/N): " FETCH_CACHE

if [[ $FETCH_CACHE =~ ^[Yy]$ ]]; then
  echo ""
  echo -e "${BLUE}→ Fetching Drupal cache from S3...${NC}"
  if yarn fetch-drupal-cache; then
    echo -e "${GREEN}  ✓ Drupal cache fetched successfully${NC}"
  else
    echo -e "${RED}  ✗ Failed to fetch Drupal cache${NC}"
    echo "  Continuing anyway (will use existing cache or fetch on first build)"
  fi
else
  echo -e "${YELLOW}  Skipping Drupal cache fetch${NC}"
  echo "  Note: Run 'yarn fetch-drupal-cache' manually if needed"
fi
echo ""

# Check for .env file with Drupal credentials
echo -e "${BLUE}→ Checking Drupal configuration...${NC}"
if [ -f "$CONTENT_BUILD_DIR/.env" ]; then
  echo -e "${GREEN}  ✓ Found .env file with Drupal credentials${NC}"

  # Show current Drupal endpoint (without exposing password)
  if grep -q "DRUPAL_ADDRESS" .env; then
    DRUPAL_ADDR=$(grep "DRUPAL_ADDRESS" .env | cut -d'=' -f2)
    echo "  Drupal endpoint: $DRUPAL_ADDR"
  fi
else
  echo -e "${YELLOW}  ⚠ No .env file found${NC}"
  echo "  To pull fresh content from Drupal, copy .env.example to .env"
  echo "  and configure your Drupal credentials"
fi
echo ""

# Start the watch server
echo "========================================"
echo "Starting watch server..."
echo "========================================"
echo ""
echo "The watch server will:"
echo "  - Build static HTML content from templates"
echo "  - Watch for template/CSS changes and rebuild"
echo "  - Serve the site on http://localhost:3002"
echo "  - Create symlink to vets-website apps (../vets-website/build/localhost/generated)"
echo ""
echo "Note: Initial build can take time depending on content"
echo ""
echo "To optimize build time (skip templates you don't need):"
echo "  - Edit src/site/stages/build/drupal/individual-queries.js"
echo "  - Comment out content types you won't be testing"
echo ""

# Start watch mode in a new terminal tab
echo "Opening watch server in new terminal tab..."
open_terminal_tab "cd '$CONTENT_BUILD_DIR' && yarn watch"

# Wait for server to be ready
echo "Waiting for watch server to start..."
echo "(This may take a few minutes on first run while building content)"
for _ in {1..120}; do
  if curl -s -o /dev/null http://localhost:3002; then
    echo -e "${GREEN}✓ Watch server is ready at http://localhost:3002${NC}"
    break
  fi
  sleep 2
done

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Watch server is running in the new terminal tab."
echo "You can monitor build progress and errors there."
echo "To stop the server, use Ctrl+C in that tab."
echo ""
echo "Useful commands:"
echo "  - yarn serve         : Start static server without watching"
echo "  - yarn build         : Build all content once (no watch)"
echo "  - yarn preview       : Add preview routes for Drupal nodes"
echo "  - yarn test:unit     : Run unit tests"
echo ""
echo "Content-build connects to vets-website apps via symlink"
echo "Make sure vets-website is built and running if testing applications"
echo ""
