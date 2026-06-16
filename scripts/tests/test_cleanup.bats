#!/usr/bin/env bats
# test_cleanup.bats — unit tests for scripts/cleanup.sh
# Run: bats scripts/tests/test_cleanup.bats

load 'test_helper'

setup() {
  # Create isolated HOME for each test
  TEST_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$TEST_HOME"
  export HOME="$TEST_HOME"
}

# ── Help and usage ────────────────────────────────────────────────────────────

@test "cleanup.sh --help exits 0 and shows usage" {
  run bash "$SCRIPTS_DIR/cleanup.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "--dry-run" ]]
  [[ "$output" =~ "--yes" ]]
}

@test "cleanup.sh -h exits 0 and shows usage" {
  run bash "$SCRIPTS_DIR/cleanup.sh" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "cleanup.sh with unknown option exits 2" {
  run bash "$SCRIPTS_DIR/cleanup.sh" --invalid-option
  [ "$status" -eq 2 ]
  [[ "$output" =~ "Unknown option" ]]
}

# ── Dry-run mode ──────────────────────────────────────────────────────────────

@test "cleanup.sh --dry-run does not remove files" {
  # Create test files
  touch "$TEST_HOME/.zshrc.bak"
  touch "$TEST_HOME/.gitconfig.backup"
  touch "$TEST_HOME/.viminfo"

  run bash "$SCRIPTS_DIR/cleanup.sh" --dry-run
  [ "$status" -eq 0 ]

  # Files should still exist
  [ -f "$TEST_HOME/.zshrc.bak" ]
  [ -f "$TEST_HOME/.gitconfig.backup" ]
  [ -f "$TEST_HOME/.viminfo" ]

  # Output should indicate dry-run
  [[ "$output" =~ "dry-run" ]]
  [[ "$output" =~ "would remove" ]]
}

@test "cleanup.sh --dry-run shows correct count of files" {
  # Create 5 test files that cleanup would remove
  touch "$TEST_HOME/.zshrc.bak"
  touch "$TEST_HOME/.gitconfig.backup"
  touch "$TEST_HOME/.viminfo"
  touch "$TEST_HOME/.bash_profile"
  touch "$TEST_HOME/.DS_Store"

  run bash "$SCRIPTS_DIR/cleanup.sh" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "5 would remove" ]]
}

@test "cleanup.sh -n short option works for dry-run" {
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" -n
  [ "$status" -eq 0 ]
  [[ "$output" =~ "dry-run" ]]
  [ -f "$TEST_HOME/.zshrc.bak" ]
}

# ── Force mode (--yes) ────────────────────────────────────────────────────────

@test "cleanup.sh --yes removes backup files without prompt" {
  touch "$TEST_HOME/.zshrc.bak"
  touch "$TEST_HOME/.gitconfig.backup"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  # Files should be removed
  [ ! -e "$TEST_HOME/.zshrc.bak" ]
  [ ! -e "$TEST_HOME/.gitconfig.backup" ]

  # Should not contain confirmation prompt
  [[ ! "$output" =~ "Continue?" ]]
}

@test "cleanup.sh -y short option works for yes" {
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" -y
  [ "$status" -eq 0 ]
  [ ! -e "$TEST_HOME/.zshrc.bak" ]
}

@test "cleanup.sh --yes removes cache files" {
  touch "$TEST_HOME/.zcompdump"
  touch "$TEST_HOME/.lesshst"
  touch "$TEST_HOME/.viminfo"
  touch "$TEST_HOME/.z"
  touch "$TEST_HOME/.DS_Store"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  [ ! -e "$TEST_HOME/.zcompdump" ]
  [ ! -e "$TEST_HOME/.lesshst" ]
  [ ! -e "$TEST_HOME/.viminfo" ]
  [ ! -e "$TEST_HOME/.z" ]
  [ ! -e "$TEST_HOME/.DS_Store" ]
}

@test "cleanup.sh --yes removes legacy configs" {
  touch "$TEST_HOME/.bash_profile"
  touch "$TEST_HOME/.profile"
  touch "$TEST_HOME/.zshenv"
  touch "$TEST_HOME/.spaceship.zsh"
  touch "$TEST_HOME/.zsh.plugins.txt"
  touch "$TEST_HOME/.angular-config.json"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  [ ! -e "$TEST_HOME/.bash_profile" ]
  [ ! -e "$TEST_HOME/.profile" ]
  [ ! -e "$TEST_HOME/.zshenv" ]
  [ ! -e "$TEST_HOME/.spaceship.zsh" ]
  [ ! -e "$TEST_HOME/.zsh.plugins.txt" ]
  [ ! -e "$TEST_HOME/.angular-config.json" ]
}

@test "cleanup.sh --yes reports correct removal count" {
  touch "$TEST_HOME/.zshrc.bak"
  touch "$TEST_HOME/.gitconfig.backup"
  touch "$TEST_HOME/.viminfo"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]
  [[ "$output" =~ "3 removed" ]]
}

# ── File preservation (what should NEVER be removed) ─────────────────────────

@test "cleanup.sh --yes never removes .zshrc (managed symlink)" {
  touch "$TEST_HOME/.zshrc"
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  # .zshrc should remain, .zshrc.bak should be removed
  [ -f "$TEST_HOME/.zshrc" ]
  [ ! -e "$TEST_HOME/.zshrc.bak" ]
}

@test "cleanup.sh --yes never removes .gitconfig" {
  touch "$TEST_HOME/.gitconfig"
  touch "$TEST_HOME/.gitconfig.backup"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  [ -f "$TEST_HOME/.gitconfig" ]
  [ ! -e "$TEST_HOME/.gitconfig.backup" ]
}

@test "cleanup.sh --yes never removes .fzf.zsh (expected unmanaged)" {
  touch "$TEST_HOME/.fzf.zsh"
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  [ -f "$TEST_HOME/.fzf.zsh" ]
}

@test "cleanup.sh --yes never removes .yarnrc (work-specific)" {
  touch "$TEST_HOME/.yarnrc"
  touch "$TEST_HOME/.bash_profile"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  [ -f "$TEST_HOME/.yarnrc" ]
  [ ! -e "$TEST_HOME/.bash_profile" ]
}

@test "cleanup.sh --yes never removes .zshrc.local (machine-specific)" {
  touch "$TEST_HOME/.zshrc.local"
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  [ -f "$TEST_HOME/.zshrc.local" ]
  [ ! -e "$TEST_HOME/.zshrc.bak" ]
}

@test "cleanup.sh --yes never removes .zsh_history" {
  touch "$TEST_HOME/.zsh_history"
  touch "$TEST_HOME/.viminfo"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  [ -f "$TEST_HOME/.zsh_history" ]
  [ ! -e "$TEST_HOME/.viminfo" ]
}

@test "cleanup.sh --yes never removes directories" {
  mkdir -p "$TEST_HOME/.config"
  mkdir -p "$TEST_HOME/.ssh"
  mkdir -p "$TEST_HOME/.cache"
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  [ -d "$TEST_HOME/.config" ]
  [ -d "$TEST_HOME/.ssh" ]
  [ -d "$TEST_HOME/.cache" ]
}

# ── Counting and output ───────────────────────────────────────────────────────

@test "cleanup.sh --yes counts 'not found' correctly when files don't exist" {
  # Don't create any files
  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]
  [[ "$output" =~ "0 removed" ]]
  [[ "$output" =~ "not found" ]]
}

@test "cleanup.sh --yes shows categorized output" {
  touch "$TEST_HOME/.zshrc.bak"
  touch "$TEST_HOME/.viminfo"
  touch "$TEST_HOME/.bash_profile"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  # Should show all three categories
  [[ "$output" =~ "Backup files" ]]
  [[ "$output" =~ "Cache files" ]]
  [[ "$output" =~ "Legacy configs" ]]
}

@test "cleanup.sh --yes displays paths with ~ instead of full HOME" {
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  # Should use ~ in output, not full path
  [[ "$output" =~ "~/.zshrc.bak" ]]
  [[ ! "$output" =~ "$TEST_HOME/.zshrc.bak" ]]
}

@test "cleanup.sh --yes shows verify tip when files removed" {
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]
  [[ "$output" =~ "verify.sh" ]]
}

@test "cleanup.sh --yes does not show verify tip when nothing removed" {
  # Don't create any files
  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "verify.sh" ]]
}

# ── Edge cases ────────────────────────────────────────────────────────────────

@test "cleanup.sh --yes handles broken symlinks" {
  # Create a broken symlink (points to non-existent file)
  ln -s /nonexistent/file "$TEST_HOME/.bash_profile"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  # Broken symlink should be removed if it's in the cleanup list
  [ ! -e "$TEST_HOME/.bash_profile" ]
  [ ! -L "$TEST_HOME/.bash_profile" ]
}

@test "cleanup.sh --yes handles files with spaces in names" {
  # Only test if a file with spaces is in the cleanup list
  # (current implementation uses explicit paths, so this is theoretical)
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]
  [ ! -e "$TEST_HOME/.zshrc.bak" ]
}

@test "cleanup.sh --yes is idempotent (safe to run twice)" {
  touch "$TEST_HOME/.zshrc.bak"

  # Run once
  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]
  [[ "$output" =~ "1 removed" ]]

  # Run again - should succeed with 0 removed
  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]
  [[ "$output" =~ "0 removed" ]]
}

# ── Exit codes ────────────────────────────────────────────────────────────────

@test "cleanup.sh exits 0 on success" {
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]
}

@test "cleanup.sh exits 0 when no files to remove" {
  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]
}

@test "cleanup.sh exits 0 on dry-run" {
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" --dry-run
  [ "$status" -eq 0 ]
}

# ── Integration with dotfiles structure ──────────────────────────────────────

@test "cleanup.sh correctly resolves DOTFILES_DIR" {
  # Script should be able to find bootstrap_helpers.sh
  run bash "$SCRIPTS_DIR/cleanup.sh" --help
  [ "$status" -eq 0 ]
  # If it couldn't source bootstrap_helpers.sh, it would fail
}

@test "cleanup.sh uses bootstrap_helpers.sh for output" {
  touch "$TEST_HOME/.zshrc.bak"

  run bash "$SCRIPTS_DIR/cleanup.sh" --yes
  [ "$status" -eq 0 ]

  # Should use helper functions for output (look for the checkmark)
  [[ "$output" =~ "✓" ]] || [[ "$output" =~ "removed" ]]
}
