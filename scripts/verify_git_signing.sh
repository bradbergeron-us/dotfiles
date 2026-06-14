#!/usr/bin/env bash
# Verify conditional git signing is configured correctly

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall status
ALL_PASSED=true

echo "🔍 Verifying git signing configuration..."
echo ""

# Function to test a repository
test_repo() {
    local repo_path="$1"
    local expected_email="$2"
    local expected_key="$3"
    local expected_sign="$4"
    local repo_name="$5"

    if [[ ! -d "$repo_path" ]]; then
        echo -e "${YELLOW}⚠️  Skipping ${repo_name}: directory not found${NC}"
        return
    fi

    cd "$repo_path"
    local actual_email actual_key actual_sign
    actual_email=$(git config user.email || true)
    actual_key=$(git config user.signingkey 2>/dev/null || echo "NONE")
    actual_sign=$(git config commit.gpgsign || true)

    local status="✅ PASS"
    local color=$GREEN

    if [[ "$actual_email" != "$expected_email" ]] || \
       [[ "$actual_key" != "$expected_key" ]] || \
       [[ "$actual_sign" != "$expected_sign" ]]; then
        status="❌ FAIL"
        color=$RED
        ALL_PASSED=false
    fi

    echo -e "${color}${status}${NC} ${repo_name}"
    echo "  Email:      ${actual_email} (expected: ${expected_email})"
    echo "  Signing key: ${actual_key} (expected: ${expected_key})"
    echo "  Auto-sign:  ${actual_sign} (expected: ${expected_sign})"
    echo ""
}

# Test work organization repositories (generic work1 / work2).
# These mirror the includeIf "gitdir:~/Code/workN/" entries in gitconfig:
#   ~/Code/work1/ → ~/.config/git/work1.gitconfig
#   ~/Code/work2/ → ~/.config/git/work2.gitconfig
for org in work1 work2; do
    org_dir="$HOME/Code/$org"
    org_config="$HOME/.config/git/$org.gitconfig"

    if [[ ! -d "$org_dir" ]]; then
        echo -e "${YELLOW}⚠️  Skipping ${org}: ~/Code/${org}/ not found${NC}"
        echo ""
        continue
    fi

    org_repo=$(find "$org_dir" -mindepth 1 -maxdepth 1 -type d | head -1)
    if [[ -z "$org_repo" ]]; then
        echo -e "${YELLOW}⚠️  Skipping ${org}: no repositories under ~/Code/${org}/${NC}"
        echo ""
        continue
    fi

    if [[ -f "$org_config" ]]; then
        org_email=$(grep "email = " "$org_config" | head -1 | awk '{print $3}')
        org_key=$(grep "signingkey = " "$org_config" | head -1 | awk '{print $3}')
        test_repo "$org_repo" "$org_email" "$org_key" "true" "Work org (${org})"
    else
        echo -e "${RED}❌ FAIL${NC} ${org} configuration"
        echo "  ${org_config} not found"
        echo "  Run: cp ~/dotfiles/templates/config/git/work.gitconfig.template ${org_config}"
        echo ""
        ALL_PASSED=false
    fi
done

# Test personal repository (dotfiles)
if [[ -d ~/dotfiles ]]; then
    PERSONAL_EMAIL=$(grep "email = " ~/dotfiles/gitconfig | head -1 | awk '{print $3}')
    # Check if dotfiles has local signing key configured
    cd ~/dotfiles
    DOTFILES_KEY=$(git config --local user.signingkey 2>/dev/null || echo "NONE")
    DOTFILES_SIGN=$(git config --local commit.gpgsign 2>/dev/null || git config commit.gpgsign)

    test_repo ~/dotfiles "$PERSONAL_EMAIL" "$DOTFILES_KEY" "$DOTFILES_SIGN" "Personal (dotfiles)"
else
    echo -e "${YELLOW}⚠️  Skipping personal repos: ~/dotfiles/ not found${NC}"
    echo ""
fi

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$ALL_PASSED" = true ]]; then
    echo -e "${GREEN}✅ All git signing configurations are correct!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some git signing configurations failed.${NC}"
    echo ""
    echo "To fix:"
    echo "  1. Check that config files exist in ~/.config/git/"
    echo "  2. Verify GPG keys are set up: gpg --list-secret-keys"
    echo "  3. Update config files with correct email and key IDs"
    echo ""
    exit 1
fi
