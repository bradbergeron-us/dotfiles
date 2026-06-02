#!/usr/bin/env zsh
# setup_gpg_signing.sh — automate GPG setup for signed commits
# Run: zsh scripts/setup_gpg_signing.sh

set -euo pipefail

info()    { print -P "%F{cyan}  → %f$*"; }
success() { print -P "%F{green}  ✓ %f$*"; }
error()   { print -P "%F{red}  ✗ %f$*"; }

echo ""
print -P "%F{cyan}  🔐  GPG Signing Setup%f"
echo "  ─────────────────────────────────────────────────"

# Check if GPG is installed
if ! command -v gpg &>/dev/null; then
  error "GPG not found. Install via: brew install gnupg"
  exit 1
fi
success "GPG installed at $(which gpg)"

# Check for existing GPG keys
info "Checking for existing GPG keys..."
if gpg --list-secret-keys --keyid-format=long | grep -q "sec"; then
  success "Found existing GPG key(s):"
  gpg --list-secret-keys --keyid-format=long | grep -A 1 "^sec" | sed 's/^/       /'
  echo ""

  # Extract the key ID from the first key
  KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "^sec" | head -1 | sed 's|.*/\([A-F0-9]\{16\}\).*|\1|')
  info "Using key: $KEY_ID"

  # Check if key is already configured in local gitconfig
  LOCAL_GITCONFIG="$HOME/.config/git/local.gitconfig"
  if [[ -f "$LOCAL_GITCONFIG" ]] && grep -q "signingkey = $KEY_ID" "$LOCAL_GITCONFIG"; then
    success "Key already configured in $LOCAL_GITCONFIG"
  else
    info "Updating $LOCAL_GITCONFIG with GPG key..."

    # Add or update the signingkey
    if grep -q "signingkey = " "$LOCAL_GITCONFIG"; then
      # Replace existing signingkey line (might be commented out)
      sed -i.bak "s|.*signingkey = .*|	signingkey = $KEY_ID|" "$LOCAL_GITCONFIG"
      rm -f "$LOCAL_GITCONFIG.bak"
    else
      # Add signingkey under [user] section
      if grep -q "^\[user\]" "$LOCAL_GITCONFIG"; then
        sed -i.bak "/^\[user\]/a\\
	signingkey = $KEY_ID
" "$LOCAL_GITCONFIG"
        rm -f "$LOCAL_GITCONFIG.bak"
      else
        echo "[user]" >> "$LOCAL_GITCONFIG"
        echo "	signingkey = $KEY_ID" >> "$LOCAL_GITCONFIG"
      fi
    fi
    success "Updated $LOCAL_GITCONFIG with key: $KEY_ID"
  fi

  # Display public key for uploading to Git hosting providers
  echo ""
  info "To add this key to Bitbucket/GitHub/GitLab:"
  echo "  1. Copy the public key below"
  echo "  2. Go to your Git provider's SSH/GPG keys settings"
  echo "  3. Add a new GPG key and paste the content"
  echo ""
  echo "  ─────────────────────────────────────────────────"
  gpg --armor --export "$KEY_ID"
  echo "  ─────────────────────────────────────────────────"
  echo ""
  info "Bitbucket: https://bitbucket.org/account/settings/gpg-keys/"
  info "GitHub: https://github.com/settings/keys"

else
  info "No GPG keys found. Creating a new one..."
  echo ""
  info "You'll be prompted for:"
  echo "       • Your name"
  echo "       • Your email (use your work email for work repos)"
  echo "       • A secure passphrase (recommended)"
  echo ""

  # Generate key with default settings (RSA 4096)
  gpg --full-generate-key

  # Get the new key ID
  KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "^sec" | head -1 | sed 's|.*/\([A-F0-9]\{16\}\).*|\1|')
  success "Created GPG key: $KEY_ID"

  # Configure in local gitconfig
  LOCAL_GITCONFIG="$HOME/.config/git/local.gitconfig"
  mkdir -p "$(dirname "$LOCAL_GITCONFIG")"

  if [[ -f "$LOCAL_GITCONFIG" ]]; then
    if grep -q "signingkey = " "$LOCAL_GITCONFIG"; then
      sed -i.bak "s|.*signingkey = .*|	signingkey = $KEY_ID|" "$LOCAL_GITCONFIG"
      rm -f "$LOCAL_GITCONFIG.bak"
    else
      if grep -q "^\[user\]" "$LOCAL_GITCONFIG"; then
        sed -i.bak "/^\[user\]/a\\
	signingkey = $KEY_ID
" "$LOCAL_GITCONFIG"
        rm -f "$LOCAL_GITCONFIG.bak"
      else
        echo "[user]" >> "$LOCAL_GITCONFIG"
        echo "	signingkey = $KEY_ID" >> "$LOCAL_GITCONFIG"
      fi
    fi
  else
    cat > "$LOCAL_GITCONFIG" << EOF
# ~/.config/git/local.gitconfig — machine-specific git config
[user]
	signingkey = $KEY_ID
EOF
  fi
  success "Configured key in $LOCAL_GITCONFIG"

  echo ""
  info "Upload this public key to Bitbucket/GitHub/GitLab:"
  echo "  ─────────────────────────────────────────────────"
  gpg --armor --export "$KEY_ID"
  echo "  ─────────────────────────────────────────────────"
fi

echo ""
success "🎉  GPG signing is ready!"
info "Your commits will now be signed automatically."
echo ""
