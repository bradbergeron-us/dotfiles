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

# Test VA.gov repository
if [[ -d ~/Code/va.gov ]]; then
    VA_REPO=$(find ~/Code/va.gov -maxdepth 1 -type d -name "vets-*" | head -1)
    if [[ -n "$VA_REPO" ]]; then
        # Read expected values from config file
        if [[ -f ~/.config/git/va.gitconfig ]]; then
            VA_EMAIL=$(grep "email = " ~/.config/git/va.gitconfig | head -1 | awk '{print $3}')
            VA_KEY=$(grep "signingkey = " ~/.config/git/va.gitconfig | head -1 | awk '{print $3}')
            test_repo "$VA_REPO" "$VA_EMAIL" "$VA_KEY" "true" "VA.gov"
        else
            echo -e "${RED}❌ FAIL${NC} VA.gov configuration"
            echo "  ~/.config/git/va.gitconfig not found"
            echo "  Run: cp ~/dotfiles/templates/config/git/va.gitconfig.template ~/.config/git/va.gitconfig"
            echo ""
            ALL_PASSED=false
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Skipping VA.gov: ~/Code/va.gov/ not found${NC}"
    echo ""
fi

# Test AFS repository
if [[ -d ~/Code/AFS ]]; then
    AFS_REPO=$(find ~/Code/AFS -maxdepth 1 -type d -name "dgi-*" | head -1)
    if [[ -n "$AFS_REPO" ]]; then
        # Read expected values from config file
        if [[ -f ~/.config/git/afs.gitconfig ]]; then
            AFS_EMAIL=$(grep "email = " ~/.config/git/afs.gitconfig | head -1 | awk '{print $3}')
            AFS_KEY=$(grep "signingkey = " ~/.config/git/afs.gitconfig | head -1 | awk '{print $3}')
            test_repo "$AFS_REPO" "$AFS_EMAIL" "$AFS_KEY" "true" "Accenture Federal Services (AFS)"
        else
            echo -e "${RED}❌ FAIL${NC} AFS configuration"
            echo "  ~/.config/git/afs.gitconfig not found"
            echo "  Run: cp ~/dotfiles/templates/config/git/afs.gitconfig.template ~/.config/git/afs.gitconfig"
            echo ""
            ALL_PASSED=false
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Skipping AFS: ~/Code/AFS/ not found${NC}"
    echo ""
fi

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

# Test exception repository (should be unsigned)
if [[ -d ~/Code/DGI-AGENTS ]]; then
    test_repo ~/Code/DGI-AGENTS "$PERSONAL_EMAIL" "NONE" "false" "Exception (DGI-AGENTS)"
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
