#!/usr/bin/env bats
# test_dryrun_helpers.bats — unit tests for scripts/lib/dryrun_helpers.sh
# Run: bats scripts/tests/test_dryrun_helpers.bats

load 'test_helper'

# Source the bootstrap output helpers (info/success/warn + colors) and the
# dry-run helpers at the FILE's top level — NOT inside setup(). This keeps the
# `typeset -a DRY_RUN_ACTIONS=()` declaration in dryrun_helpers.sh in a
# non-function scope so the array stays a real (empty) global instead of
# becoming local-to-setup() and unbound. bats re-sources this file in a fresh
# process for every @test, so DRY_RUN_ACTIONS starts empty each time.
# shellcheck source=/dev/null
source "$LIB_DIR/bootstrap_helpers.sh"
setup_colors
STEP=0
TOTAL_STEPS=13
# shellcheck source=/dev/null
source "$LIB_DIR/dryrun_helpers.sh"
# check_dotfile_symlinks resolves the active profile (current_profile) and
# filters records by it (profile_includes), exactly as bootstrap.sh does.
# shellcheck source=/dev/null
source "$LIB_DIR/profile_helpers.sh"

# make_fake_tool DIR NAME EXIT_CODE — write a stub executable that exits with
# the given code, used to exercise the "tool present" preview branches.
make_fake_tool() {
  mkdir -p "$1"
  printf '#!/bin/sh\nexit %s\n' "$3" > "$1/$2"
  chmod +x "$1/$2"
}

setup() {
  # Re-establish step state per test (top-level set it once at source time).
  STEP=0
  TOTAL_STEPS=13

  # Shared fake dotfiles checkout. check_dotfile_symlinks reads
  # $DOTFILES_DIR/config/symlinks.map (the single source of truth) and only
  # compares readlink targets, so the src files need not exist.
  FAKE_DOTFILES="$BATS_TEST_TMPDIR/dotfiles"
  mkdir -p "$FAKE_DOTFILES/config/git"
  cat > "$FAKE_DOTFILES/config/symlinks.map" << 'EOF'
home/zshrc               .zshrc
home/zprofile            .zprofile
home/gitconfig           .gitconfig
home/tmux.conf           .tmux.conf
home/hyper.js            .hyper.js
home/gitignore_global    .gitignore_global
home/gemrc               .gemrc
home/irbrc               .irbrc
home/pryrc               .pryrc
home/psqlrc              .psqlrc
home/npmrc               .npmrc
home/editorconfig        .editorconfig
home/ssh_config          .ssh/config
config/starship.toml     .config/starship.toml
config/direnvrc          .config/direnv/direnvrc
config/mise.toml         .config/mise/config.toml
EOF

  # Destination/source pairs derived from the manifest (dest:src, 16 entries),
  # used to materialize symlinks in the "all linked" case.
  DOTFILE_PAIRS=()
  while read -r _s _d; do
    [[ -z "$_s" || "$_s" == \#* ]] && continue
    DOTFILE_PAIRS+=("$_d:$_s")
  done < "$FAKE_DOTFILES/config/symlinks.map"

  # A minimal PATH makes the real tools look "absent"; uname is symlinked in so
  # check_homebrew's arch probe still runs cleanly.
  PREVIEW_EMPTY="$BATS_TEST_TMPDIR/preview_empty_bin"
  mkdir -p "$PREVIEW_EMPTY"
  ln -sf "$(command -v uname)" "$PREVIEW_EMPTY/uname"
}

# ── dry_run_log ───────────────────────────────────────────────────────────────
@test "dry_run_log: single call → 1 entry with matching text" {
  dry_run_log "first action"
  [ "${#DRY_RUN_ACTIONS[@]}" -eq 1 ]
  [ "${DRY_RUN_ACTIONS[0]}" = "first action" ]
}

@test "dry_run_log: three calls → 3 ordered entries" {
  dry_run_log "a"
  dry_run_log "b"
  dry_run_log "c"
  [ "${#DRY_RUN_ACTIONS[@]}" -eq 3 ]
  [ "${DRY_RUN_ACTIONS[2]}" = "c" ]
}

@test "dry_run_log: DRY_RUN_ACTIONS empty at start of each test" {
  [ "${#DRY_RUN_ACTIONS[@]}" -eq 0 ]
}

# ── dry_run_step ──────────────────────────────────────────────────────────────
@test "dry_run_step: increments STEP (1, 2)" {
  dry_run_step "first"  >/dev/null
  [ "$STEP" -eq 1 ]
  dry_run_step "second" >/dev/null
  [ "$STEP" -eq 2 ]
}

@test "dry_run_step: output contains counter [1/13]" {
  output=$(dry_run_step "Install widgets")
  echo "$output" | grep -q "1/13"
}

@test "dry_run_step: output contains title text" {
  output=$(dry_run_step "Install widgets")
  echo "$output" | grep -q "Install widgets"
}

@test "dry_run_step: output marked '(dry-run)'" {
  output=$(dry_run_step "Install widgets")
  echo "$output" | grep -q "dry-run"
}

# ── check_dotfile_symlinks ────────────────────────────────────────────────────
@test "check_dotfile_symlinks: empty HOME → would symlink all 16" {
  local h="$BATS_TEST_TMPDIR/home1"; mkdir -p "$h"
  out=$(
    export HOME="$h"
    DOTFILES_DIR="$FAKE_DOTFILES"
    check_dotfile_symlinks
  )
  echo "$out" | grep -q "Would symlink: 16 file(s)"
}

@test "check_dotfile_symlinks: logs install.sh action" {
  local h="$BATS_TEST_TMPDIR/home1"; mkdir -p "$h"
  # The install.sh action is recorded via dry_run_log (DRY_RUN_ACTIONS), not
  # printed to stdout, so dump the action list alongside the function output.
  out=$(
    export HOME="$h"
    DOTFILES_DIR="$FAKE_DOTFILES"
    check_dotfile_symlinks
    printf '\n--ACTIONS--\n'
    printf '%s\n' "${DRY_RUN_ACTIONS[@]}"
  )
  echo "$out" | grep -q "Run: install.sh (symlink dotfiles)"
}

@test "check_dotfile_symlinks: all linked → would symlink 0" {
  local h="$BATS_TEST_TMPDIR/home2"
  local pair dest_rel src_rel
  for pair in "${DOTFILE_PAIRS[@]}"; do
    dest_rel="${pair%%:*}"
    src_rel="${pair##*:}"
    mkdir -p "$h/$(dirname "$dest_rel")"
    ln -sf "$FAKE_DOTFILES/$src_rel" "$h/$dest_rel"
  done
  out=$(
    export HOME="$h"
    DOTFILES_DIR="$FAKE_DOTFILES"
    check_dotfile_symlinks
  )
  echo "$out" | grep -q "Would symlink: 0 file(s)"
}

@test "check_dotfile_symlinks: all linked → already linked 16" {
  local h="$BATS_TEST_TMPDIR/home2"
  local pair dest_rel src_rel
  for pair in "${DOTFILE_PAIRS[@]}"; do
    dest_rel="${pair%%:*}"
    src_rel="${pair##*:}"
    mkdir -p "$h/$(dirname "$dest_rel")"
    ln -sf "$FAKE_DOTFILES/$src_rel" "$h/$dest_rel"
  done
  out=$(
    export HOME="$h"
    DOTFILES_DIR="$FAKE_DOTFILES"
    check_dotfile_symlinks
  )
  echo "$out" | grep -q "Already linked: 16 file(s)"
}

@test "check_dotfile_symlinks: plain file at dest → would backup 1" {
  local h="$BATS_TEST_TMPDIR/home3"; mkdir -p "$h"
  echo "pre-existing" > "$h/.zshrc"
  out=$(
    export HOME="$h"
    DOTFILES_DIR="$FAKE_DOTFILES"
    check_dotfile_symlinks
  )
  echo "$out" | grep -qE "Would backup: 1 existing file"
}

@test "check_dotfile_symlinks: logs create actions for missing local configs" {
  local h="$BATS_TEST_TMPDIR/home1"; mkdir -p "$h"
  ( set -e
    export HOME="$h"
    DOTFILES_DIR="$FAKE_DOTFILES"
    check_dotfile_symlinks >/dev/null
    printf '%s\n' "${DRY_RUN_ACTIONS[@]}" | grep -q "Create ~/.zshrc.local from template"
    printf '%s\n' "${DRY_RUN_ACTIONS[@]}" | grep -q "Create ~/.config/git/local.gitconfig from template"
    printf '%s\n' "${DRY_RUN_ACTIONS[@]}" | grep -q "Write ~/.gitconfig thin include"
  )
}

# ── check_ssh_key ─────────────────────────────────────────────────────────────
@test "check_ssh_key: missing key → logs generate action" {
  ( set -e
    export HOME="$BATS_TEST_TMPDIR/ssh_none"
    mkdir -p "$HOME"
    check_ssh_key >/dev/null
    printf '%s\n' "${DRY_RUN_ACTIONS[@]}" | grep -q "Generate SSH key"
  )
}

@test "check_ssh_key: existing key → reports skip" {
  out=$(
    export HOME="$BATS_TEST_TMPDIR/ssh_have"
    mkdir -p "$HOME/.ssh"
    : > "$HOME/.ssh/id_ed25519"
    check_ssh_key
  )
  echo "$out" | grep -q "already exists"
}

@test "check_ssh_key: existing key → no generate action logged" {
  out=$(
    export HOME="$BATS_TEST_TMPDIR/ssh_have"
    mkdir -p "$HOME/.ssh"
    : > "$HOME/.ssh/id_ed25519"
    check_ssh_key
    printf '\n--ACTIONS--\n'
    printf '%s\n' "${DRY_RUN_ACTIONS[@]}"
  )
  ! echo "$out" | sed -n '/--ACTIONS--/,$p' | grep -q "Generate SSH key"
}

# ── check_brew_bundle (missing Brewfile branch) ───────────────────────────────
@test "check_brew_bundle: missing Brewfile → warns" {
  out=$(check_brew_bundle "$BATS_TEST_TMPDIR/no_such_brewfile")
  echo "$out" | grep -q "Brewfile not found"
}

@test "check_brew_bundle: missing Brewfile → no action logged" {
  out=$(
    check_brew_bundle "$BATS_TEST_TMPDIR/no_such_brewfile"
    printf '\n--ACTIONS--\n'
    printf '%s\n' "${DRY_RUN_ACTIONS[@]}"
  )
  ! echo "$out" | sed -n '/--ACTIONS--/,$p' | grep -q "brew bundle"
}

# ── check_work_configs (profile-gated) ────────────────────────────────────────
# DOTFILES_PROFILE is exported per-case so current_profile is deterministic and
# never reads the developer's real ~/.config/dotfiles/profile (env beats file).
@test "check_work_configs: work profile + script present → reports prompt" {
  local wd="$BATS_TEST_TMPDIR/work_dotfiles"
  mkdir -p "$wd/scripts"
  : > "$wd/scripts/setup_work_configs.sh"
  out=$(
    export DOTFILES_PROFILE=work
    DOTFILES_DIR="$wd"
    check_work_configs
  )
  echo "$out" | grep -q "work configuration setup"
}

@test "check_work_configs: non-work profile → would skip" {
  local wd="$BATS_TEST_TMPDIR/work_dotfiles"
  mkdir -p "$wd/scripts"
  : > "$wd/scripts/setup_work_configs.sh"
  out=$(
    export DOTFILES_PROFILE=minimal
    DOTFILES_DIR="$wd"
    check_work_configs
  )
  echo "$out" | grep -q "Would skip work configs"
}

@test "check_work_configs: work profile + script absent → silent" {
  out=$(
    export DOTFILES_PROFILE=work
    DOTFILES_DIR="$BATS_TEST_TMPDIR/work_none"
    mkdir -p "$DOTFILES_DIR"
    check_work_configs
  )
  [ -z "$out" ]
}

# ── show_dry_run_summary ──────────────────────────────────────────────────────
@test "show_dry_run_summary: empty → '0 actions planned'" {
  out=$(show_dry_run_summary)
  echo "$out" | grep -q "0 actions planned"
}

@test "show_dry_run_summary: empty → 'already bootstrapped' message" {
  out=$(show_dry_run_summary)
  echo "$out" | grep -q "already bootstrapped"
}

@test "show_dry_run_summary: 2 logged → '2 actions planned'" {
  out=$(
    dry_run_log "Install Homebrew"
    dry_run_log "Generate SSH key"
    show_dry_run_summary
  )
  echo "$out" | grep -q "2 actions planned"
}

@test "show_dry_run_summary: enumerates logged actions" {
  out=$(
    dry_run_log "Install Homebrew"
    dry_run_log "Generate SSH key"
    show_dry_run_summary
  )
  echo "$out" | grep -q "Install Homebrew"
  echo "$out" | grep -q "Generate SSH key"
}

# ── check_macos_defaults (profile-gated) ──────────────────────────────────────
@test "check_macos_defaults: gui profile → reports it would prompt" {
  out=$(
    export DOTFILES_PROFILE=personal
    check_macos_defaults
  )
  echo "$out" | grep -q "macOS developer defaults"
}

@test "check_macos_defaults: logs no actions" {
  out=$(
    export DOTFILES_PROFILE=personal
    check_macos_defaults
    printf '\n--ACTIONS--\n'
    printf '%s\n' "${DRY_RUN_ACTIONS[@]}"
  )
  macos_actions=$(echo "$out" | awk 'p; /--ACTIONS--/{p=1}' | tr -d '[:space:]')
  [ -z "$macos_actions" ]
}

@test "check_macos_defaults: server profile → would skip" {
  out=$(
    export DOTFILES_PROFILE=server
    check_macos_defaults
  )
  echo "$out" | grep -q "Would skip macOS defaults"
}

# ── check_* previews (tool present/absent branches) ───────────────────────────
# Each check runs inside a command-substitution subshell so the restricted PATH
# never leaks to the rest of the test.

@test "check_xcode: tools absent → would prompt to install" {
  out=$( export PATH="$PREVIEW_EMPTY"; check_xcode )
  echo "$out" | grep -q "Would prompt to install Xcode CLI Tools"
}

@test "check_homebrew: brew absent → would install Homebrew" {
  out=$( export PATH="$PREVIEW_EMPTY"; check_homebrew )
  echo "$out" | grep -q "Would install Homebrew"
}

@test "check_fzf: fzf absent → would skip integration" {
  out=$( export PATH="$PREVIEW_EMPTY"; check_fzf )
  echo "$out" | grep -q "Would skip fzf integration"
}

@test "check_gh_auth: gh absent → would skip auth" {
  out=$( export PATH="$PREVIEW_EMPTY"; check_gh_auth )
  echo "$out" | grep -q "Would skip GitHub CLI auth"
}

@test "check_corepack: corepack absent → would skip" {
  out=$( export PATH="$PREVIEW_EMPTY"; check_corepack )
  echo "$out" | grep -q "Would skip Corepack"
}

@test "check_rust: rustup absent → would skip Rust" {
  out=$( export PATH="$PREVIEW_EMPTY"; check_rust )
  echo "$out" | grep -q "Would skip Rust"
}

@test "check_git_lfs: git-lfs absent → would skip configuration" {
  out=$( export PATH="$PREVIEW_EMPTY"; check_git_lfs )
  echo "$out" | grep -q "Would skip git-lfs configuration"
}

@test "check_mise_runtimes: mise absent → would skip runtimes" {
  out=$( export PATH="$PREVIEW_EMPTY"; check_mise_runtimes )
  echo "$out" | grep -q "Would skip runtime installation"
}

@test "check_corepack: corepack present, yarn absent → would enable Corepack" {
  local d="$BATS_TEST_TMPDIR/corepack_bin"
  make_fake_tool "$d" corepack 0
  out=$( export PATH="$d"; check_corepack )
  echo "$out" | grep -q "Would run: corepack enable"
}

@test "check_gh_auth: gh present, unauthenticated → would run gh auth login" {
  local d="$BATS_TEST_TMPDIR/gh_bin"
  make_fake_tool "$d" gh 1
  out=$( export PATH="$d"; check_gh_auth )
  echo "$out" | grep -q "Would run: gh auth login"
}

@test "check_git_lfs: git-lfs present → would configure" {
  local d="$BATS_TEST_TMPDIR/lfs_bin"
  make_fake_tool "$d" git-lfs 0
  out=$( export PATH="$d"; check_git_lfs )
  echo "$out" | grep -q "Would run: git lfs install"
}
