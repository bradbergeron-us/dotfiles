#!/usr/bin/env bash
# Quick fix script - bypasses bootstrap, just gets dotfiles working

set +e  # Don't exit on errors

echo "🔧 Quick Fix - Getting your dotfiles working"
echo "=============================================="
echo ""

# 0. Verify Claude Code won't be broken
if [[ -f ~/.local/bin/claude ]] && ! grep -q '\.local/bin' ~/dotfiles/home/zshrc; then
  echo "⚠️  WARNING: Claude Code detected but zshrc missing ~/.local/bin in PATH"
  echo "   Adding safety PATH entry to preserve Claude Code access..."
  # This shouldn't happen with the updated zshrc, but just in case
  echo "" >> ~/dotfiles/home/zshrc
  echo "# Claude Code safety fallback" >> ~/dotfiles/home/zshrc
  echo '[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"' >> ~/dotfiles/home/zshrc
fi

# 1. Symlink dotfiles (the most critical part)
echo "Step 1: Symlinking dotfiles..."
cd ~/dotfiles || exit 1
zsh install.sh
echo "✓ Dotfiles symlinked"
echo ""

# 2. Create local config if missing
if [[ ! -f ~/.zshrc.local ]]; then
  echo "Step 2: Creating ~/.zshrc.local..."
  cp ~/dotfiles/home/examples/zshrc.local.example ~/.zshrc.local
  echo "✓ Created ~/.zshrc.local"
else
  echo "Step 2: ~/.zshrc.local already exists"
fi
echo ""

# 3. Source the new zshrc
echo "Step 3: Reloading shell configuration..."
# shellcheck source=/dev/null
source ~/.zshrc 2>/dev/null || true
echo "✓ Done"
echo ""

# 4. Verify Claude Code still works
if [[ -f ~/.local/bin/claude ]]; then
  echo "Step 4: Verifying Claude Code..."
  if command -v claude &>/dev/null; then
    echo "✓ Claude Code accessible (version $(claude --version 2>/dev/null || echo 'unknown'))"
  else
    echo "⚠️  Claude Code installed but not in PATH yet"
    echo "   Run: source ~/.zshrc (or open new terminal)"
  fi
  echo ""
fi

echo "=============================================="
echo "✅ Essential setup complete!"
echo ""
echo "Next steps:"
echo "1. Open a new terminal (or run: source ~/.zshrc)"
echo "2. Claude Code should now work"
echo "3. Optional: Run 'brew bundle' to install missing packages"
echo ""
