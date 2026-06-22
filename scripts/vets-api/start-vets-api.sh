#!/bin/bash
# Daily startup script for vets-api
#
# This script handles:
# - Git pull from main (if conditions are right)
# - Updating vets-api-mockdata and running make_table.rb
# - Bundle install for dependencies
# - Starting the Rails server with foreman
#
# Usage: ~/dotfiles/scripts/vets-api/start-vets-api.sh
#        Or use alias: vets-api-start

set -e  # Exit on error

# Navigate to vets-api directory
VETS_API_DIR="$HOME/Code/va.gov/vets-api"
VETS_API_MOCKDATA_DIR="$HOME/Code/va.gov/vets-api-mockdata"

if [ ! -d "$VETS_API_DIR" ]; then
  echo "ERROR: vets-api directory not found at $VETS_API_DIR"
  echo "Please update VETS_API_DIR in this script to point to your vets-api location"
  exit 1
fi

if [ ! -d "$VETS_API_MOCKDATA_DIR" ]; then
  echo "ERROR: vets-api-mockdata directory not found at $VETS_API_MOCKDATA_DIR"
  echo "Please update VETS_API_MOCKDATA_DIR in this script"
  exit 1
fi

cd "$VETS_API_DIR"
echo "Working directory: $VETS_API_DIR"
echo ""

echo "========================================"
echo "Starting vets-api setup..."
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Git pull from main
echo -e "${BLUE}→ Checking vets-api git status...${NC}"
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

# Update vets-api-mockdata
echo -e "${BLUE}→ Updating vets-api-mockdata...${NC}"
cd "$VETS_API_MOCKDATA_DIR"
MOCKDATA_BRANCH=$(git branch --show-current)
echo "  Current branch: $MOCKDATA_BRANCH"

if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo -e "${YELLOW}  ⚠ vets-api-mockdata has uncommitted changes${NC}"
  echo "  Skipping git pull"
  echo ""
else
  if [ "$MOCKDATA_BRANCH" = "main" ]; then
    echo "  Pulling latest mockdata changes..."
    if git pull origin main; then
      echo -e "${GREEN}  ✓ Successfully pulled mockdata${NC}"
    else
      echo -e "${RED}  ✗ Mockdata git pull failed${NC}"
      echo "  Continuing anyway..."
    fi
  else
    echo -e "${YELLOW}  ⚠ Not on main branch${NC}"
  fi
  echo ""
fi

# Run make_table.rb
echo -e "${BLUE}→ Running make_table.rb...${NC}"
if ruby make_table.rb; then
  echo -e "${GREEN}  ✓ Mock data table generated${NC}"
else
  echo -e "${RED}  ✗ Failed to generate mock data table${NC}"
  echo "  Continuing anyway..."
fi
echo ""

# Return to vets-api directory
cd "$VETS_API_DIR"

# Check Ruby version
echo -e "${BLUE}→ Checking Ruby version...${NC}"
RUBY_VERSION=$(ruby --version)
echo "  Ruby version: $RUBY_VERSION"
echo ""

# Configure Gemfile to use jfrog proxy
echo -e "${BLUE}→ Configuring Gemfile for jfrog proxy...${NC}"
if command -v gsed &> /dev/null; then
  SED_CMD="gsed"
else
  SED_CMD="sed"
fi

# Replace rubygems.org with jfrog proxy URL
if grep -q "rubygems.org" Gemfile; then
  $SED_CMD -i.bak "s/rubygems\.org/jfrog.accenturefederaldev.com\/artifactory\/afs-gems-proxy/g" Gemfile
  echo -e "${GREEN}  ✓ Gemfile configured for jfrog proxy${NC}"
else
  echo -e "${YELLOW}  ⚠ Gemfile already configured or doesn't use rubygems.org${NC}"
fi
echo ""

# Install bundle dependencies
echo -e "${BLUE}→ Installing bundle dependencies...${NC}"
if bundle install; then
  echo -e "${GREEN}  ✓ Bundle install complete${NC}"
else
  echo -e "${RED}  ✗ Bundle install failed${NC}"
  exit 1
fi
echo ""

echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""

# Start the Rails server
echo "========================================"
echo "Starting Rails server with foreman..."
echo "========================================"
echo ""
echo "Starting server with: foreman start -m all=1,clamd=0,freshclam=0"
echo ""

# Start foreman in a new Hyper tab
echo "Opening Rails server in new Hyper tab..."
osascript <<EOF
tell application "Hyper"
    activate
    delay 0.3
    tell application "System Events"
        keystroke "t" using {command down}
        delay 0.5
        keystroke "cd '$VETS_API_DIR' && foreman start -m all=1,clamd=0,freshclam=0"
        keystroke return
    end tell
end tell
EOF

# Wait for server to be ready
echo "Waiting for Rails server to start..."
for i in {1..60}; do
  if curl -s -o /dev/null http://localhost:3000; then
    echo -e "${GREEN}✓ Rails server is ready at http://localhost:3000${NC}"
    break
  fi
  sleep 1
done

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Rails server is running in the new Hyper tab."
echo "You can monitor server logs and requests there."
echo "To stop the server, use Ctrl+C in that tab."
echo ""
echo "Useful endpoints:"
echo "  - Flipper features: http://localhost:3000/flipper/features"
echo "  - API docs: http://localhost:3000/api-docs"
