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

# Default applications to load
DEFAULT_APPS="auth,login-page,profile,static-pages,terms-of-use,verify,virtual-agent"

# Education benefit apps (from your old workflow)
EDU_APPS="1990ez-edu-benefits,toe,survivor-dependent-education-benefit-22-5490,1995-edu-benefits,10297-edu-benefits,enrollment-verification,education-letters"

# Check if user provided app list
if [ -n "$1" ]; then
  # User provided apps or options, pass through
  echo "Starting dev server with: $@"
  yarn watch "$@"
else
  # Use default apps
  echo "Starting dev server with default apps: $DEFAULT_APPS"
  echo ""
  echo "To start with different apps, use:"
  echo "  vets-dev --entry=app1,app2,app3"
  echo ""
  echo "To include education apps, use:"
  echo "  vets-dev --entry=$DEFAULT_APPS,$EDU_APPS"
  echo ""
  yarn watch --entry="$DEFAULT_APPS"
fi
