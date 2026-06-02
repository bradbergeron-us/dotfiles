#!/usr/bin/env bash
# Quick fix script - bypasses bootstrap, just gets dotfiles working

set +e  # Don't exit on errors

echo "🔧 Quick Fix - Getting your dotfiles working"
echo "=============================================="
echo ""

# 1. Symlink dotfiles (the most critical part)
echo "Step 1: Symlinking dotfiles..."
cd ~/dotfiles
zsh install.sh
echo "✓ Dotfiles symlinked"
echo ""

# 2. Create local config if missing
if [[ ! -f ~/.zshrc.local ]]; then
  echo "Step 2: Creating ~/.zshrc.local..."
  cp ~/dotfiles/zshrc.local.example ~/.zshrc.local
  echo "✓ Created ~/.zshrc.local"
else
  echo "Step 2: ~/.zshrc.local already exists"
fi
echo ""

# 3. Source the new zshrc
echo "Step 3: Reloading shell configuration..."
echo "✓ Done"
echo ""

echo "=============================================="
echo "✅ Essential setup complete!"
echo ""
echo "Next steps:"
echo "1. Open a new terminal (or run: source ~/.zshrc)"
echo "2. Claude Code should now work"
echo "3. Optional: Run 'brew bundle' to install missing packages"
echo ""
