#!/usr/bin/env bash
# test_dryrun_helpers.sh — unit tests for dryrun_helpers.sh
# Usage: bash scripts/tests/test_dryrun_helpers.sh
# shellcheck disable=SC1091,SC2030,SC2031,SC2034  # dynamic source; intentional subshell scoping; vars used by sourced fns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
  TESTS_PASSED=$(( TESTS_PASSED + 1 ))
  TESTS_RUN=$(( TESTS_RUN + 1 ))
  printf "  PASS  %s\n" "$1"
}

fail() {
  TESTS_FAILED=$(( TESTS_FAILED + 1 ))
  TESTS_RUN=$(( TESTS_RUN + 1 ))
  printf "  FAIL  %s — %s\n" "$1" "$2"
}

TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Source the bootstrap output helpers (info/success/warn + colors) and the
# dry-run helpers under test ONCE, here at the script's top level. This mirrors
# how bootstrap.sh sources them at top level, and — crucially — keeps the
# `typeset -a DRY_RUN_ACTIONS=()` declaration in a non-function scope so the
# array stays a real (empty) variable instead of becoming unbound under `set -u`.
# Each test runs in its own subshell, which inherits this empty array and these
# functions but cannot leak mutations back to the parent, so every test starts
# from a clean slate.
source "$SCRIPT_DIR/../lib/bootstrap_helpers.sh"
setup_colors
STEP=0
TOTAL_STEPS=13
source "$SCRIPT_DIR/../lib/dryrun_helpers.sh"

# ── Shared fake dotfiles checkout ─────────────────────────────────────────────
# check_dotfile_symlinks reads $DOTFILES_DIR/<src> only for the readlink compare,
# so the files do not need to exist for the symlink-target match to succeed.
FAKE_DOTFILES="$TMPDIR_BASE/dotfiles"
mkdir -p "$FAKE_DOTFILES/config/git"

# Fixture manifest — the single source of truth check_dotfile_symlinks reads
# (mirrors the real config/symlinks.map; src paths keep their home/ or config/
# prefix). The src files need not exist: only the readlink target is compared.
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
# used to materialize symlinks in the "all linked" case below.
DOTFILE_PAIRS=()
while read -r _s _d; do
  [[ -z "$_s" || "$_s" == \#* ]] && continue
  DOTFILE_PAIRS+=("$_d:$_s")
done < "$FAKE_DOTFILES/config/symlinks.map"

# ── dry_run_log ───────────────────────────────────────────────────────────────
echo ""
echo "=== dry_run_log ==="

# Case 1: appends a single entry
if (
  dry_run_log "first action"
  [[ "${#DRY_RUN_ACTIONS[@]}" -eq 1 ]] || { printf "  FAIL  count: expected 1, got %s\n" "${#DRY_RUN_ACTIONS[@]}"; exit 1; }
  [[ "${DRY_RUN_ACTIONS[0]}" == "first action" ]] || { printf "  FAIL  content: got %s\n" "${DRY_RUN_ACTIONS[0]}"; exit 1; }
); then
  pass "dry_run_log: single call → 1 entry with matching text"
else
  fail "dry_run_log: single call" "subshell exited non-zero"
fi

# Case 2: appends multiple entries in order
if (
  dry_run_log "a"
  dry_run_log "b"
  dry_run_log "c"
  [[ "${#DRY_RUN_ACTIONS[@]}" -eq 3 ]] || { printf "  FAIL  count: expected 3, got %s\n" "${#DRY_RUN_ACTIONS[@]}"; exit 1; }
  [[ "${DRY_RUN_ACTIONS[2]}" == "c" ]] || { printf "  FAIL  order: last entry got %s\n" "${DRY_RUN_ACTIONS[2]}"; exit 1; }
); then
  pass "dry_run_log: three calls → 3 ordered entries"
else
  fail "dry_run_log: three calls" "subshell exited non-zero"
fi

# Case 3: fresh subshell starts with an empty action list
if (
  [[ "${#DRY_RUN_ACTIONS[@]}" -eq 0 ]] || { printf "  FAIL  expected empty, got %s\n" "${#DRY_RUN_ACTIONS[@]}"; exit 1; }
); then
  pass "dry_run_log: DRY_RUN_ACTIONS empty at start of each test"
else
  fail "dry_run_log: empty at start" "subshell exited non-zero"
fi

# ── dry_run_step ──────────────────────────────────────────────────────────────
echo ""
echo "=== dry_run_step ==="

# Case 1: increments STEP
if (
  dry_run_step "first"  >/dev/null
  [[ "$STEP" -eq 1 ]] || { printf "  FAIL  STEP after 1 call: expected 1, got %s\n" "$STEP"; exit 1; }
  dry_run_step "second" >/dev/null
  [[ "$STEP" -eq 2 ]] || { printf "  FAIL  STEP after 2 calls: expected 2, got %s\n" "$STEP"; exit 1; }
); then
  pass "dry_run_step: increments STEP (1, 2)"
else
  fail "dry_run_step: increments STEP" "subshell exited non-zero"
fi

# Case 2: output contains the [STEP/TOTAL] counter and the title
output=$( dry_run_step "Install widgets" )
if echo "$output" | grep -q "1/13"; then
  pass "dry_run_step: output contains counter [1/13]"
else
  fail "dry_run_step: counter" "got: $output"
fi
if echo "$output" | grep -q "Install widgets"; then
  pass "dry_run_step: output contains title text"
else
  fail "dry_run_step: title" "got: $output"
fi

# Case 3: output marks the step as a dry run
if echo "$output" | grep -q "dry-run"; then
  pass "dry_run_step: output marked '(dry-run)'"
else
  fail "dry_run_step: dry-run marker" "got: $output"
fi

# ── check_dotfile_symlinks ────────────────────────────────────────────────────
echo ""
echo "=== check_dotfile_symlinks ==="

# Case 1: nothing linked yet → logs install action + would-symlink all 16 files
FAKE_HOME1="$TMPDIR_BASE/home1"
mkdir -p "$FAKE_HOME1"
out1=$(
  export HOME="$FAKE_HOME1"
  DOTFILES_DIR="$FAKE_DOTFILES"
  check_dotfile_symlinks
  printf '\n--ACTIONS--\n'
  printf '%s\n' "${DRY_RUN_ACTIONS[@]}"
)
if echo "$out1" | grep -q "Would symlink: 16 file(s)"; then
  pass "check_dotfile_symlinks: empty HOME → would symlink all 16"
else
  fail "check_dotfile_symlinks: empty HOME would-symlink count" "got: $out1"
fi
if echo "$out1" | grep -q "Run: install.sh (symlink dotfiles)"; then
  pass "check_dotfile_symlinks: logs install.sh action"
else
  fail "check_dotfile_symlinks: install.sh action logged" "got: $out1"
fi

# Case 2: all destinations already correctly linked → would symlink 0
FAKE_HOME2="$TMPDIR_BASE/home2"
for pair in "${DOTFILE_PAIRS[@]}"; do
  dest_rel="${pair%%:*}"
  src_rel="${pair##*:}"
  mkdir -p "$FAKE_HOME2/$(dirname "$dest_rel")"
  ln -sf "$FAKE_DOTFILES/$src_rel" "$FAKE_HOME2/$dest_rel"
done
out2=$(
  export HOME="$FAKE_HOME2"
  DOTFILES_DIR="$FAKE_DOTFILES"
  check_dotfile_symlinks
)
if echo "$out2" | grep -q "Would symlink: 0 file(s)"; then
  pass "check_dotfile_symlinks: all linked → would symlink 0"
else
  fail "check_dotfile_symlinks: all-linked would-symlink count" "got: $out2"
fi
if echo "$out2" | grep -q "Already linked: 16 file(s)"; then
  pass "check_dotfile_symlinks: all linked → already linked 16"
else
  fail "check_dotfile_symlinks: already-linked count" "got: $out2"
fi

# Case 3: an existing plain file at a destination → reported as a backup
FAKE_HOME3="$TMPDIR_BASE/home3"
mkdir -p "$FAKE_HOME3"
echo "pre-existing" > "$FAKE_HOME3/.zshrc"
out3=$(
  export HOME="$FAKE_HOME3"
  DOTFILES_DIR="$FAKE_DOTFILES"
  check_dotfile_symlinks
)
if echo "$out3" | grep -qE "Would backup: 1 existing file"; then
  pass "check_dotfile_symlinks: plain file at dest → would backup 1"
else
  fail "check_dotfile_symlinks: backup detection" "got: $out3"
fi

# Case 4: missing local configs are logged as create actions
if (
  export HOME="$FAKE_HOME1"
  DOTFILES_DIR="$FAKE_DOTFILES"
  check_dotfile_symlinks >/dev/null
  printf '%s\n' "${DRY_RUN_ACTIONS[@]}" | grep -q "Create ~/.zshrc.local from template" \
    || { printf "  FAIL  missing zshrc.local not logged\n"; exit 1; }
  printf '%s\n' "${DRY_RUN_ACTIONS[@]}" | grep -q "Create ~/.config/git/local.gitconfig from template" \
    || { printf "  FAIL  missing local.gitconfig not logged\n"; exit 1; }
); then
  pass "check_dotfile_symlinks: logs create actions for missing local configs"
else
  fail "check_dotfile_symlinks: local config create actions" "subshell exited non-zero"
fi

# ── check_ssh_key ─────────────────────────────────────────────────────────────
echo ""
echo "=== check_ssh_key ==="

# Case 1: no key present → logs a generate action
if (
  export HOME="$TMPDIR_BASE/ssh_none"
  mkdir -p "$HOME"
  check_ssh_key >/dev/null
  printf '%s\n' "${DRY_RUN_ACTIONS[@]}" | grep -q "Generate SSH key" \
    || { printf "  FAIL  generate action not logged\n"; exit 1; }
); then
  pass "check_ssh_key: missing key → logs generate action"
else
  fail "check_ssh_key: missing key" "subshell exited non-zero"
fi

# Case 2: key already present → no generate action, reports skip
out_key=$(
  export HOME="$TMPDIR_BASE/ssh_have"
  mkdir -p "$HOME/.ssh"
  : > "$HOME/.ssh/id_ed25519"
  check_ssh_key
  printf '\n--ACTIONS--\n'
  printf '%s\n' "${DRY_RUN_ACTIONS[@]}"
)
if echo "$out_key" | grep -q "already exists"; then
  pass "check_ssh_key: existing key → reports skip"
else
  fail "check_ssh_key: existing key skip message" "got: $out_key"
fi
if echo "$out_key" | sed -n '/--ACTIONS--/,$p' | grep -q "Generate SSH key"; then
  fail "check_ssh_key: existing key should not log generate" "got: $out_key"
else
  pass "check_ssh_key: existing key → no generate action logged"
fi

# ── check_brew_bundle (missing Brewfile branch) ───────────────────────────────
echo ""
echo "=== check_brew_bundle ==="

# Case 1: Brewfile path does not exist → warns and logs nothing
out_brew=$(
  check_brew_bundle "$TMPDIR_BASE/no_such_brewfile"
  printf '\n--ACTIONS--\n'
  printf '%s\n' "${DRY_RUN_ACTIONS[@]}"
)
if echo "$out_brew" | grep -q "Brewfile not found"; then
  pass "check_brew_bundle: missing Brewfile → warns"
else
  fail "check_brew_bundle: missing Brewfile warning" "got: $out_brew"
fi
if echo "$out_brew" | sed -n '/--ACTIONS--/,$p' | grep -q "brew bundle"; then
  fail "check_brew_bundle: missing Brewfile should log nothing" "got: $out_brew"
else
  pass "check_brew_bundle: missing Brewfile → no action logged"
fi

# ── check_work_configs ────────────────────────────────────────────────────────
echo ""
echo "=== check_work_configs ==="

# Case 1: setup script present → reports it would prompt
WORK_DOTFILES="$TMPDIR_BASE/work_dotfiles"
mkdir -p "$WORK_DOTFILES/scripts"
: > "$WORK_DOTFILES/scripts/setup_work_configs.sh"
out_work=$(
  DOTFILES_DIR="$WORK_DOTFILES"
  check_work_configs
)
if echo "$out_work" | grep -q "work configuration setup"; then
  pass "check_work_configs: script present → reports prompt"
else
  fail "check_work_configs: script present" "got: $out_work"
fi

# Case 2: setup script absent → no output
out_work_none=$(
  DOTFILES_DIR="$TMPDIR_BASE/work_none"
  mkdir -p "$DOTFILES_DIR"
  check_work_configs
)
if [[ -z "$out_work_none" ]]; then
  pass "check_work_configs: script absent → silent"
else
  fail "check_work_configs: script absent" "expected no output, got: $out_work_none"
fi

# ── show_dry_run_summary ──────────────────────────────────────────────────────
echo ""
echo "=== show_dry_run_summary ==="

# Case 1: no actions → reports already bootstrapped
out_sum_empty=$( show_dry_run_summary )
if echo "$out_sum_empty" | grep -q "0 actions planned"; then
  pass "show_dry_run_summary: empty → '0 actions planned'"
else
  fail "show_dry_run_summary: empty count" "got: $out_sum_empty"
fi
if echo "$out_sum_empty" | grep -q "already bootstrapped"; then
  pass "show_dry_run_summary: empty → 'already bootstrapped' message"
else
  fail "show_dry_run_summary: empty message" "got: $out_sum_empty"
fi

# Case 2: with actions → reports count and enumerates each action
out_sum=$(
  dry_run_log "Install Homebrew"
  dry_run_log "Generate SSH key"
  show_dry_run_summary
)
if echo "$out_sum" | grep -q "2 actions planned"; then
  pass "show_dry_run_summary: 2 logged → '2 actions planned'"
else
  fail "show_dry_run_summary: action count" "got: $out_sum"
fi
if echo "$out_sum" | grep -q "Install Homebrew" && echo "$out_sum" | grep -q "Generate SSH key"; then
  pass "show_dry_run_summary: enumerates logged actions"
else
  fail "show_dry_run_summary: action enumeration" "got: $out_sum"
fi

# ── check_macos_defaults ──────────────────────────────────────────────────────
echo ""
echo "=== check_macos_defaults ==="

# Always informational; logs nothing but mentions the defaults it would apply.
out_macos=$(
  check_macos_defaults
  printf '\n--ACTIONS--\n'
  printf '%s\n' "${DRY_RUN_ACTIONS[@]}"
)
if echo "$out_macos" | grep -q "macOS developer defaults"; then
  pass "check_macos_defaults: reports it would prompt"
else
  fail "check_macos_defaults: prompt message" "got: $out_macos"
fi
macos_actions=$(echo "$out_macos" | awk 'p; /--ACTIONS--/{p=1}' | tr -d '[:space:]')
if [[ -n "$macos_actions" ]]; then
  fail "check_macos_defaults: should not log actions" "got: $out_macos"
else
  pass "check_macos_defaults: logs no actions"
fi

# ── check_* dry-run previews (tool present/absent branches) ───────────────
echo ""
echo "=== check_* previews ==="

# A minimal PATH makes the real tools look "absent"; uname is symlinked in so
# check_homebrew's arch probe still runs cleanly. Per-case bin dirs below add a
# specific fake executable to exercise the "present" branches. Each check runs
# inside a command-substitution subshell so the restricted PATH never leaks.
PREVIEW_EMPTY="$TMPDIR_BASE/preview_empty_bin"
mkdir -p "$PREVIEW_EMPTY"
ln -sf "$(command -v uname)" "$PREVIEW_EMPTY/uname"

make_fake_tool() {  # make_fake_tool DIR NAME EXIT_CODE
  mkdir -p "$1"
  printf '#!/bin/sh\nexit %s\n' "$3" > "$1/$2"
  chmod +x "$1/$2"
}

# ---- tool-absent branches (deterministic on any machine) ----

out=$( export PATH="$PREVIEW_EMPTY"; check_xcode )
if echo "$out" | grep -q "Would prompt to install Xcode CLI Tools"; then
  pass "check_xcode: tools absent → would prompt to install"
else
  fail "check_xcode: absent branch" "got: $out"
fi

out=$( export PATH="$PREVIEW_EMPTY"; check_homebrew )
if echo "$out" | grep -q "Would install Homebrew"; then
  pass "check_homebrew: brew absent → would install Homebrew"
else
  fail "check_homebrew: absent branch" "got: $out"
fi

out=$( export PATH="$PREVIEW_EMPTY"; check_fzf )
if echo "$out" | grep -q "Would skip fzf integration"; then
  pass "check_fzf: fzf absent → would skip integration"
else
  fail "check_fzf: absent branch" "got: $out"
fi

out=$( export PATH="$PREVIEW_EMPTY"; check_gh_auth )
if echo "$out" | grep -q "Would skip GitHub CLI auth"; then
  pass "check_gh_auth: gh absent → would skip auth"
else
  fail "check_gh_auth: absent branch" "got: $out"
fi

out=$( export PATH="$PREVIEW_EMPTY"; check_corepack )
if echo "$out" | grep -q "Would skip Corepack"; then
  pass "check_corepack: corepack absent → would skip"
else
  fail "check_corepack: absent branch" "got: $out"
fi

out=$( export PATH="$PREVIEW_EMPTY"; check_rust )
if echo "$out" | grep -q "Would skip Rust"; then
  pass "check_rust: rustup absent → would skip Rust"
else
  fail "check_rust: absent branch" "got: $out"
fi

out=$( export PATH="$PREVIEW_EMPTY"; check_git_lfs )
if echo "$out" | grep -q "Would skip git-lfs configuration"; then
  pass "check_git_lfs: git-lfs absent → would skip configuration"
else
  fail "check_git_lfs: absent branch" "got: $out"
fi

out=$( export PATH="$PREVIEW_EMPTY"; check_mise_runtimes )
if echo "$out" | grep -q "Would skip runtime installation"; then
  pass "check_mise_runtimes: mise absent → would skip runtimes"
else
  fail "check_mise_runtimes: absent branch" "got: $out"
fi

# ---- tool-present branches (via fake executables) ----

# corepack present, yarn absent → would enable Corepack
COREPACK_BIN="$TMPDIR_BASE/corepack_bin"
make_fake_tool "$COREPACK_BIN" corepack 0
out=$( export PATH="$COREPACK_BIN"; check_corepack )
if echo "$out" | grep -q "Would run: corepack enable"; then
  pass "check_corepack: corepack present, yarn absent → would enable Corepack"
else
  fail "check_corepack: present branch" "got: $out"
fi

# gh present but not authenticated (fake gh exits non-zero) → would run gh auth login
GH_BIN="$TMPDIR_BASE/gh_bin"
make_fake_tool "$GH_BIN" gh 1
out=$( export PATH="$GH_BIN"; check_gh_auth )
if echo "$out" | grep -q "Would run: gh auth login"; then
  pass "check_gh_auth: gh present, unauthenticated → would run gh auth login"
else
  fail "check_gh_auth: present/unauth branch" "got: $out"
fi

# git-lfs present → would configure git-lfs
LFS_BIN="$TMPDIR_BASE/lfs_bin"
make_fake_tool "$LFS_BIN" git-lfs 0
out=$( export PATH="$LFS_BIN"; check_git_lfs )
if echo "$out" | grep -q "Would run: git lfs install"; then
  pass "check_git_lfs: git-lfs present → would configure"
else
  fail "check_git_lfs: present branch" "got: $out"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────"
printf "  %d tests: %d passed, %d failed\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
echo "─────────────────────────────────────"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  exit 1
fi
