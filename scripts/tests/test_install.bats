#!/usr/bin/env bats
# test_install.bats — integration tests for the top-level install.sh symlinker.
# Run: bats scripts/tests/test_install.bats
#
# Unlike the helper-library suites (which source a side-effect-free *_helpers.sh
# and assert on result globals), install.sh is a zsh entry-point with no
# extractable pure functions. So these tests run the *real* script against an
# isolated $HOME — the same approach as the CI install-smoke job — and assert on
# its observable effects. install.sh derives DOTFILES_DIR from its own path, so
# it always links the repo's real files; pointing $HOME at the per-test scratch
# dir keeps every change contained (and auto-removed) by bats.

load 'test_helper'

setup() {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not available"
  fi
  INSTALL="$REPO_ROOT/install.sh"
  # Isolated fake HOME; install.sh links the real repo files into here.
  TEST_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$TEST_HOME"
}

# Run install.sh against the isolated HOME under an explicit profile. The VS Code
# block is skipped automatically because $TEST_HOME has no Code/User dir, so no
# extensions are ever installed.
run_install() {
  local profile="${1:-personal}"
  run env HOME="$TEST_HOME" DOTFILES_PROFILE="$profile" zsh "$INSTALL"
}

# ── linking ───────────────────────────────────────────────────────────────────
@test "install.sh: personal profile links core + gui dotfiles into HOME" {
  run_install personal
  [ "$status" -eq 0 ]
  # A core (untagged) record …
  [ -L "$TEST_HOME/.zshrc" ]
  [[ "$(readlink "$TEST_HOME/.zshrc")" == *"/home/zshrc" ]]
  # … and a gui-tagged record (gui applies to personal).
  [ -L "$TEST_HOME/.hyper.js" ]
}

@test "install.sh: ~/.gitconfig is a real thin include, not a symlink" {
  run_install personal
  [ "$status" -eq 0 ]
  [ -f "$TEST_HOME/.gitconfig" ]
  [ ! -L "$TEST_HOME/.gitconfig" ]
  grep -q "home/gitconfig" "$TEST_HOME/.gitconfig"
}

@test "install.sh: seeds local.gitconfig and the global pre-commit hook" {
  run_install personal
  [ "$status" -eq 0 ]
  [ -f "$TEST_HOME/.config/git/local.gitconfig" ]
  [ -x "$TEST_HOME/.config/git/hooks/pre-commit" ]
}

# ── idempotency / backups ───────────────────────────────────────────────────
@test "install.sh: a second run is idempotent (reports 0 backed up)" {
  run_install personal
  [ "$status" -eq 0 ]
  run_install personal
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "0 backed up"
}

@test "install.sh: backs up a pre-existing real dotfile before linking" {
  echo "pre-existing" > "$TEST_HOME/.zshrc"   # a real file, not a symlink
  run_install personal
  [ "$status" -eq 0 ]
  # Original is replaced by the managed symlink …
  [ -L "$TEST_HOME/.zshrc" ]
  echo "$output" | grep -q "backed up"
  # … and the old file is preserved under the timestamped backup dir.
  run find "$TEST_HOME/.dotfiles_backup" -name '.zshrc' -type f
  [ -n "$output" ]
}

# ── profile gating ──────────────────────────────────────────────────────────
@test "install.sh: minimal profile skips gui-tagged links" {
  run_install minimal
  [ "$status" -eq 0 ]
  [ -L "$TEST_HOME/.zshrc" ]                        # core link still created
  [ ! -e "$TEST_HOME/.hyper.js" ]                   # gui-tagged → skipped
  [ ! -e "$TEST_HOME/.config/ghostty/config" ]      # gui-tagged → skipped
}
