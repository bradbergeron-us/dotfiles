#!/bin/bash
# Start vets-api, vets-website, and content-build simultaneously
#
# This script handles:
# - Running all start scripts in parallel
# - Opening multiple terminal tabs for each service
# - Coordinated startup with proper ordering
#
# Usage: ~/dotfiles/scripts/start-all-vets.sh
#        Or use alias: vets-start-all

set -e  # Exit on error

# Resolve script directory and source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
source "$DOTFILES_DIR/scripts/lib/terminal_helpers.sh"

# Ensure terminal is configured before starting
# This prompts the user upfront if needed, not mid-execution
ensure_terminal_configured

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script paths
VETS_API_SCRIPT="$DOTFILES_DIR/scripts/vets-api/start-vets-api.sh"
VETS_WEBSITE_SCRIPT="$DOTFILES_DIR/scripts/vets-website/start-vets-website.sh"
CONTENT_BUILD_SCRIPT="$DOTFILES_DIR/scripts/content-build/start-content-build.sh"

echo "========================================"
echo "Starting ALL VA.gov Services"
echo "========================================"
echo ""

# Check that all scripts exist
if [ ! -f "$VETS_API_SCRIPT" ]; then
  echo -e "${RED}ERROR: vets-api start script not found at $VETS_API_SCRIPT${NC}"
  exit 1
fi

if [ ! -f "$VETS_WEBSITE_SCRIPT" ]; then
  echo -e "${RED}ERROR: vets-website start script not found at $VETS_WEBSITE_SCRIPT${NC}"
  exit 1
fi

if [ ! -f "$CONTENT_BUILD_SCRIPT" ]; then
  echo -e "${RED}ERROR: content-build start script not found at $CONTENT_BUILD_SCRIPT${NC}"
  exit 1
fi

echo -e "${BLUE}Starting services in order:${NC}"
echo "  1. vets-api (Rails backend)"
echo "  2. vets-website (React frontend)"
echo "  3. content-build (Static content generator)"
echo ""

# Start vets-api in the first tab
echo -e "${BLUE}→ Launching vets-api setup...${NC}"
open_terminal_tab "$VETS_API_SCRIPT"

echo -e "${GREEN}  ✓ vets-api setup started in new tab${NC}"
echo ""

# Wait a moment for the vets-api tab to initialize
sleep 2

# Start vets-website in the second tab
echo -e "${BLUE}→ Launching vets-website setup...${NC}"
open_terminal_tab "$VETS_WEBSITE_SCRIPT"

echo -e "${GREEN}  ✓ vets-website setup started in new tab${NC}"
echo ""

# Wait a moment for the vets-website tab to initialize
sleep 2

# Start content-build in the third tab
echo -e "${BLUE}→ Launching content-build setup...${NC}"
open_terminal_tab "$CONTENT_BUILD_SCRIPT"

echo -e "${GREEN}  ✓ content-build setup started in new tab${NC}"
echo ""

# Wait for all services to be ready
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

# Wait for content-build (port 3002)
echo -e "${BLUE}→ Checking content-build...${NC}"
for i in {1..120}; do
  if curl -s -o /dev/null http://localhost:3002; then
    echo -e "${GREEN}  ✓ content-build is ready at http://localhost:3002${NC}"
    break
  fi
  if [ $i -eq 120 ]; then
    echo -e "${YELLOW}  ⚠ content-build not responding yet (may still be building)${NC}"
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
echo "  - content-build: http://localhost:3002"
echo ""
echo "Useful vets-api endpoints:"
echo "  - Flipper features: http://localhost:3000/flipper/features"
echo "  - API docs:         http://localhost:3000/api-docs"
echo ""
echo "Each service is running in its own terminal tab."
echo "Monitor the tabs for logs and build status."
echo "Use Ctrl+C in each tab to stop the services."
echo ""
