#!/bin/bash
# Start both vets-api and vets-website simultaneously
#
# This script handles:
# - Running both start scripts in parallel
# - Opening multiple Hyper tabs for each service
# - Coordinated startup with proper ordering
#
# Usage: ~/dotfiles/scripts/start-all-vets.sh
#        Or use alias: vets-start-all

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script paths
DOTFILES_DIR="$HOME/dotfiles"
VETS_API_SCRIPT="$DOTFILES_DIR/scripts/vets-api/start-vets-api.sh"
VETS_WEBSITE_SCRIPT="$DOTFILES_DIR/scripts/vets-website/start-vets-website.sh"

echo "========================================"
echo "Starting ALL VA.gov Services"
echo "========================================"
echo ""

# Check that both scripts exist
if [ ! -f "$VETS_API_SCRIPT" ]; then
  echo -e "${RED}ERROR: vets-api start script not found at $VETS_API_SCRIPT${NC}"
  exit 1
fi

if [ ! -f "$VETS_WEBSITE_SCRIPT" ]; then
  echo -e "${RED}ERROR: vets-website start script not found at $VETS_WEBSITE_SCRIPT${NC}"
  exit 1
fi

echo -e "${BLUE}Starting services in order:${NC}"
echo "  1. vets-api (Rails backend)"
echo "  2. vets-website (React frontend)"
echo ""

# Start vets-api in the first tab
echo -e "${BLUE}→ Launching vets-api setup...${NC}"
osascript <<EOF
tell application "Hyper"
    activate
    delay 0.3
    tell application "System Events"
        keystroke "t" using {command down}
        delay 0.5
        keystroke "$VETS_API_SCRIPT"
        keystroke return
    end tell
end tell
EOF

echo -e "${GREEN}  ✓ vets-api setup started in new tab${NC}"
echo ""

# Wait a moment for the vets-api tab to initialize
sleep 2

# Start vets-website in the second tab
echo -e "${BLUE}→ Launching vets-website setup...${NC}"
osascript <<EOF
tell application "Hyper"
    activate
    delay 0.3
    tell application "System Events"
        keystroke "t" using {command down}
        delay 0.5
        keystroke "$VETS_WEBSITE_SCRIPT"
        keystroke return
    end tell
end tell
EOF

echo -e "${GREEN}  ✓ vets-website setup started in new tab${NC}"
echo ""

# Wait for both services to be ready
echo "========================================"
echo "Waiting for services to start..."
echo "========================================"
echo ""

# Wait for vets-api (port 3000)
echo -e "${BLUE}→ Checking vets-api...${NC}"
for i in {1..60}; do
  if curl -s -o /dev/null http://localhost:3000; then
    echo -e "${GREEN}  ✓ vets-api is ready at http://localhost:3000${NC}"
    break
  fi
  if [ $i -eq 60 ]; then
    echo -e "${YELLOW}  ⚠ vets-api not responding yet (may still be starting)${NC}"
  fi
  sleep 2
done
echo ""

# Wait for vets-website (port 3001)
echo -e "${BLUE}→ Checking vets-website...${NC}"
for i in {1..60}; do
  if curl -s -o /dev/null http://localhost:3001; then
    echo -e "${GREEN}  ✓ vets-website is ready at http://localhost:3001${NC}"
    break
  fi
  if [ $i -eq 60 ]; then
    echo -e "${YELLOW}  ⚠ vets-website not responding yet (may still be starting)${NC}"
  fi
  sleep 2
done
echo ""

echo "========================================"
echo -e "${GREEN}✓ All services launched!${NC}"
echo "========================================"
echo ""
echo "Service endpoints:"
echo "  - vets-api:     http://localhost:3000"
echo "  - vets-website: http://localhost:3001"
echo ""
echo "Useful vets-api endpoints:"
echo "  - Flipper features: http://localhost:3000/flipper/features"
echo "  - API docs:         http://localhost:3000/api-docs"
echo ""
echo "Each service is running in its own Hyper tab."
echo "Monitor the tabs for logs and build status."
echo "Use Ctrl+C in each tab to stop the services."
echo ""
