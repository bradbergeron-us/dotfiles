#!/bin/bash
# Quick daily dev server startup (assumes dependencies are already installed)
#
# Usage: ~/dotfiles/scripts/vets-website/dev.sh [options]
#        Or use alias: vets-dev [options]
#
# Examples:
#   vets-dev                                    # Start with default apps
#   vets-dev --entry=auth,profile,static-pages  # Start with specific apps
#   vets-dev --api=https://dev-api.va.gov       # Start with remote API

set -e

# Navigate to vets-website directory
VETS_WEBSITE_DIR="$HOME/Code/va.gov/vets-website"

if [ ! -d "$VETS_WEBSITE_DIR" ]; then
  echo "ERROR: vets-website directory not found at $VETS_WEBSITE_DIR"
  echo "Please update VETS_WEBSITE_DIR in this script to point to your vets-website location"
  exit 1
fi

cd "$VETS_WEBSITE_DIR"

# Default applications to load (includes education benefits)
DEFAULT_APPS="auth,login-page,profile,static-pages,terms-of-use,verify,virtual-agent,1990ez-edu-benefits,toe,survivor-dependent-education-benefit-22-5490,1995-edu-benefits,10297-edu-benefits,enrollment-verification,education-letters"

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

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if user provided app list
if [ -n "$1" ]; then
  # User provided apps or options, pass through directly
  echo "Starting dev server with: $@"
  yarn watch "$@"
else
  # Use default apps with interactive prompt
  echo "Starting dev server with default apps (including education benefits)"
  echo ""
  echo "To start with different apps, use:"
  echo "  vets-dev --entry=app1,app2,app3"
  echo ""

  # Start watch mode in background
  yarn watch --entry="$DEFAULT_APPS" &
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
fi
