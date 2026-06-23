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

# Resolve script directory and source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
source "$DOTFILES_DIR/scripts/lib/terminal_helpers.sh"

# Ensure terminal is configured before starting
ensure_terminal_configured

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
  echo -e "${BLUE}→ Branch selection for dev server...${NC}"
  echo "  Current branch: main"
  echo ""
  read -p "Run dev server on a different branch? (y/N): " SWITCH_BRANCH

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
  echo -e "${GREEN}  → Dev server will run on branch: $BRANCH_TO_USE${NC}"
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

# Education app URLs (from manifest.json files)
EDU_APP_URLS=(
  "http://localhost:3001/education/apply-for-gi-bill-form-22-1990"
  "http://localhost:3001/family-and-caregiver-benefits/education-and-careers/transferred-gi-bill-benefits/apply-form-22-1990e"
  "http://localhost:3001/family-and-caregiver-benefits/education-and-careers/apply-for-dea-fry-form-22-5490"
  "http://localhost:3001/education/apply-for-education-benefits/application/1995"
  "http://localhost:3001/education/other-va-education-benefits/vet-tec-2/apply-for-program-form-22-10297"
  "http://localhost:3001/education/verify-school-enrollment/enrollment-verifications"
  "http://localhost:3001/education/download-letters/letters"
)

# Start the dev server
echo "========================================"
echo "Starting development server..."
echo "========================================"
echo ""
echo "Default applications loaded:"
echo "  - auth, login-page, profile, static-pages"
echo "  - terms-of-use, verify, virtual-agent"
echo "  - Education benefits: 1990ez, toe, 22-5490, 1995, 10297"
echo "  - enrollment-verification, education-letters"
echo ""
echo "To customize applications, edit this script and modify the --entry parameter"
echo "See available apps: yarn apps"
echo ""

# Start watch mode in a new terminal tab
echo "Opening dev server in new terminal tab..."
open_terminal_tab "cd '$VETS_WEBSITE_DIR' && yarn watch --entry=auth,login-page,profile,static-pages,terms-of-use,verify,virtual-agent,1990ez-edu-benefits,toe,survivor-dependent-education-benefit-22-5490,1995-edu-benefits,10297-edu-benefits,enrollment-verification,education-letters"

# Wait for server to be ready
echo "Waiting for dev server to start..."
for _ in {1..30}; do
  if curl -s -o /dev/null http://localhost:3001; then
    echo -e "${GREEN}✓ Dev server is ready at http://localhost:3001${NC}"
    break
  fi
  sleep 1
done

# Interactive prompt to open education app pages
echo ""
echo "Education app pages:"
echo "  1) Apply for GI Bill (22-1990)"
echo "  2) Transfer of Benefits (22-1990e)"
echo "  3) Survivor Benefits (22-5490)"
echo "  4) Update Benefits (22-1995)"
echo "  5) VET TEC (22-10297)"
echo "  6) Enrollment Verification"
echo "  7) Education Letters"
echo ""
echo "Options:"
echo "  - Enter page numbers separated by spaces (e.g., 1 3 5)"
echo "  - Enter 'all' to open all pages"
echo "  - Press Enter or 'n' to skip"
echo ""
read -p "Your selection: " SELECTION
echo ""

if [[ $SELECTION =~ ^[Nn]$ ]] || [[ -z $SELECTION ]]; then
  echo "Skipping browser open. App URLs:"
  for i in "${!EDU_APP_URLS[@]}"; do
    echo "  $((i+1)). ${EDU_APP_URLS[$i]}"
  done
elif [[ $SELECTION == "all" ]]; then
  echo "Opening all education app pages..."
  for url in "${EDU_APP_URLS[@]}"; do
    echo "  → $url"
    open "$url"
    sleep 0.5  # Slight delay between opens
  done
  echo -e "${GREEN}✓ Opened ${#EDU_APP_URLS[@]} education app pages${NC}"
else
  echo "Opening selected pages..."
  OPENED_COUNT=0
  for num in $SELECTION; do
    if [[ $num =~ ^[1-7]$ ]]; then
      idx=$((num-1))
      echo "  → ${EDU_APP_URLS[$idx]}"
      open "${EDU_APP_URLS[$idx]}"
      OPENED_COUNT=$((OPENED_COUNT+1))
      sleep 0.5
    else
      echo -e "  ${YELLOW}⚠ Skipping invalid selection: $num${NC}"
    fi
  done
  if [ $OPENED_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ Opened $OPENED_COUNT education app page(s)${NC}"
  else
    echo -e "${RED}✗ No valid pages selected${NC}"
  fi
fi

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Dev server is running in the new terminal tab."
echo "You can monitor build status and errors there."
echo "To stop the server, use Ctrl+C in that tab."
