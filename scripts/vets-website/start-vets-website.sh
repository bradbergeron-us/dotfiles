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

# Start watch mode in background
yarn watch --entry=auth,login-page,profile,static-pages,terms-of-use,verify,virtual-agent,1990ez-edu-benefits,toe,survivor-dependent-education-benefit-22-5490,1995-edu-benefits,10297-edu-benefits,enrollment-verification,education-letters &
WATCH_PID=$!

# Function to cleanup on exit
cleanup() {
  echo ""
  echo "Shutting down dev server..."
  kill $WATCH_PID 2>/dev/null
  exit
}
trap cleanup SIGINT SIGTERM

# Wait for server to be ready
echo "Waiting for dev server to start..."
for i in {1..30}; do
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
read -p "Open pages in browser? (enter numbers like '1 3 5', 'all', or 'n'): " SELECTION
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
  for num in $SELECTION; do
    if [[ $num =~ ^[1-7]$ ]]; then
      idx=$((num-1))
      echo "  → ${EDU_APP_URLS[$idx]}"
      open "${EDU_APP_URLS[$idx]}"
      sleep 0.5
    fi
  done
  echo -e "${GREEN}✓ Opened selected education app pages${NC}"
fi

echo ""
echo "Dev server running (PID: $WATCH_PID)"
echo "Press Ctrl+C to stop"
echo ""

# Wait for yarn watch to finish (keeps script running)
wait $WATCH_PID
