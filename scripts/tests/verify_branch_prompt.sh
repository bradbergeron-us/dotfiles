#!/bin/bash
# Verification script to test branch prompt behavior in startup scripts
# This helps diagnose why the interactive branch prompt might not appear

set -e

echo "========================================"
echo "Branch Prompt Verification Test"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test repositories
REPOS=(
  "$HOME/Code/va.gov/vets-website"
  "$HOME/Code/va.gov/vets-api"
  "$HOME/Code/va.gov/content-build"
)

REPO_NAMES=(
  "vets-website"
  "vets-api"
  "content-build"
)

for i in "${!REPOS[@]}"; do
  REPO_PATH="${REPOS[$i]}"
  REPO_NAME="${REPO_NAMES[$i]}"

  echo -e "${BLUE}→ Testing: $REPO_NAME${NC}"
  echo "  Path: $REPO_PATH"

  if [ ! -d "$REPO_PATH" ]; then
    echo -e "${RED}  ✗ Repository not found${NC}"
    echo ""
    continue
  fi

  cd "$REPO_PATH"

  # Test 1: Check current branch
  CURRENT_BRANCH=$(git branch --show-current)
  echo "  Current branch: $CURRENT_BRANCH"

  # Test 2: Check for uncommitted changes
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}  ⚠ Status: HAS UNCOMMITTED CHANGES${NC}"
    echo -e "${YELLOW}  → Branch prompt will be SKIPPED (this is the issue!)${NC}"
    echo ""
    echo "  Details:"
    git status --short | head -n 5 | sed 's/^/    /'
    if [ "$(git status --short | wc -l)" -gt 5 ]; then
      echo "    ... and more"
    fi
    echo ""
    echo -e "${YELLOW}  Impact: The script skips ALL git operations when you have${NC}"
    echo -e "${YELLOW}  uncommitted changes, including the branch selection prompt.${NC}"
    echo ""
    echo -e "${BLUE}  Solutions:${NC}"
    echo "    1. Commit your changes: git add . && git commit -m 'message'"
    echo "    2. Stash your changes: git stash"
    echo "    3. Update the script to show branch prompt even with changes"
  else
    echo -e "${GREEN}  ✓ Status: CLEAN (no uncommitted changes)${NC}"
    echo -e "${GREEN}  → Branch prompt WILL appear${NC}"

    # Test 3: Check if on main/master
    if [ "$REPO_NAME" = "vets-api" ]; then
      DEFAULT_BRANCH="master"
    else
      DEFAULT_BRANCH="main"
    fi

    if [ "$CURRENT_BRANCH" = "$DEFAULT_BRANCH" ]; then
      echo "  ✓ Already on default branch ($DEFAULT_BRANCH)"
      echo "  → Script will pull latest, then prompt for branch switch"
    else
      echo "  ℹ Currently on non-default branch: $CURRENT_BRANCH"
      echo "  → Script will switch to $DEFAULT_BRANCH, pull, then prompt"
    fi
  fi

  echo ""
  echo "----------------------------------------"
  echo ""
done

echo "========================================"
echo "Summary"
echo "========================================"
echo ""
echo "The branch selection prompt is ONLY shown when:"
echo "  1. You have NO uncommitted changes"
echo "  2. The git checkout/pull operations succeed"
echo ""
echo "If you have uncommitted changes in a repo, the entire"
echo "git operations block (including the branch prompt) is skipped."
echo ""
echo -e "${BLUE}Recommendation:${NC}"
echo "Update the scripts to show branch prompt even with uncommitted"
echo "changes. The prompt would let you switch branches without pulling."
echo ""
