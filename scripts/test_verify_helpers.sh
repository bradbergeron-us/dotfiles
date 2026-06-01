#!/usr/bin/env bash
# test_verify_helpers.sh — unit tests for verify_helpers.sh
# Usage: bash scripts/test_verify_helpers.sh
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

# ── Shared fake dotfiles dir ───────────────────────────────────────────────────
FAKE_DOTFILES="$TMPDIR_BASE/dotfiles"
mkdir -p "$FAKE_DOTFILES/config"
touch "$FAKE_DOTFILES/zshrc"
touch "$FAKE_DOTFILES/gitconfig"
touch "$FAKE_DOTFILES/config/mise.toml"

# ── check_symlinks ────────────────────────────────────────────────────────────
echo ""
echo "=== check_symlinks ==="

# Case 1: all correct symlinks
FAKE_HOME="$TMPDIR_BASE/home1"
mkdir -p "$FAKE_HOME/.config/mise"
ln -sf "$FAKE_DOTFILES/zshrc"            "$FAKE_HOME/.zshrc"
ln -sf "$FAKE_DOTFILES/gitconfig"        "$FAKE_HOME/.gitconfig"
ln -sf "$FAKE_DOTFILES/config/mise.toml" "$FAKE_HOME/.config/mise/config.toml"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=(
    "zshrc:.zshrc"
    "gitconfig:.gitconfig"
    "config/mise.toml:.config/mise/config.toml"
  )
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME"
  [[ "$SYMLINK_OK_COUNT"     -eq 3 ]] || { printf "  FAIL  ok count: expected 3, got %s\n"     "$SYMLINK_OK_COUNT";     exit 1; }
  [[ "$SYMLINK_BROKEN_COUNT" -eq 0 ]] || { printf "  FAIL  broken count: expected 0, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: all correct → OK=3, BROKEN=0"
else
  fail "check_symlinks: all correct" "subshell exited non-zero"
fi

# Case 2: one missing destination
FAKE_HOME2="$TMPDIR_BASE/home2"
mkdir -p "$FAKE_HOME2"
ln -sf "$FAKE_DOTFILES/zshrc" "$FAKE_HOME2/.zshrc"
# gitconfig symlink intentionally absent

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=("zshrc:.zshrc" "gitconfig:.gitconfig")
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME2"
  [[ "$SYMLINK_OK_COUNT"     -eq 1 ]] || { printf "  FAIL  ok count: expected 1, got %s\n"     "$SYMLINK_OK_COUNT";     exit 1; }
  [[ "$SYMLINK_BROKEN_COUNT" -eq 1 ]] || { printf "  FAIL  broken count: expected 1, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: one missing destination → BROKEN=1"
else
  fail "check_symlinks: one missing destination" "subshell exited non-zero"
fi

# Case 3: symlink points to wrong target
FAKE_HOME3="$TMPDIR_BASE/home3"
mkdir -p "$FAKE_HOME3"
ln -sf "/some/completely/different/path" "$FAKE_HOME3/.zshrc"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=("zshrc:.zshrc")
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME3"
  [[ "$SYMLINK_BROKEN_COUNT" -eq 1 ]] || { printf "  FAIL  broken count: expected 1, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: wrong symlink target → BROKEN=1"
else
  fail "check_symlinks: wrong symlink target" "subshell exited non-zero"
fi

# Case 4: destination is a plain file (not a symlink)
FAKE_HOME4="$TMPDIR_BASE/home4"
mkdir -p "$FAKE_HOME4"
echo "not a symlink" > "$FAKE_HOME4/.zshrc"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=("zshrc:.zshrc")
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME4"
  [[ "$SYMLINK_BROKEN_COUNT" -eq 1 ]] || { printf "  FAIL  broken count: expected 1, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: plain file (not symlink) → BROKEN=1"
else
  fail "check_symlinks: plain file" "subshell exited non-zero"
fi

# Case 5: source file missing from dotfiles checkout
FAKE_HOME5="$TMPDIR_BASE/home5"
mkdir -p "$FAKE_HOME5"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=("nonexistent_src:.zshrc")
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME5"
  [[ "$SYMLINK_BROKEN_COUNT" -eq 1 ]] || { printf "  FAIL  broken count: expected 1, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: source file missing in dotfiles → BROKEN=1"
else
  fail "check_symlinks: source file missing" "subshell exited non-zero"
fi

# Case 6: empty symlink list → all counts zero
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=()
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME"
  [[ "$SYMLINK_OK_COUNT"     -eq 0 ]] || { printf "  FAIL  ok: expected 0, got %s\n"     "$SYMLINK_OK_COUNT";     exit 1; }
  [[ "$SYMLINK_BROKEN_COUNT" -eq 0 ]] || { printf "  FAIL  broken: expected 0, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: empty DOTFILES_SYMLINKS → all counts zero"
else
  fail "check_symlinks: empty list" "subshell exited non-zero"
fi

# ── check_mise_version_drift ──────────────────────────────────────────────────
echo ""
echo "=== check_mise_version_drift ==="

TOML_MATCH="$TMPDIR_BASE/mise_match.toml"
TOML_DRIFT="$TMPDIR_BASE/mise_drift.toml"
TOML_MISSING_RUBY="$TMPDIR_BASE/mise_missing_ruby.toml"
BOOTSTRAP_REF="$TMPDIR_BASE/bootstrap_ref.sh"

cat > "$TOML_MATCH" << 'EOF'
[tools]
ruby = "3.3.6"
node = "22"
java = "temurin-21"
python = "3.12"
go = "1.24"
EOF

cat > "$TOML_DRIFT" << 'EOF'
[tools]
ruby = "3.3.0"
node = "20"
java = "temurin-21"
python = "3.12"
go = "1.24"
EOF

cat > "$TOML_MISSING_RUBY" << 'EOF'
[tools]
node = "22"
java = "temurin-21"
python = "3.12"
go = "1.24"
EOF

cat > "$BOOTSTRAP_REF" << 'EOF'
mise install ruby@3.3.6 node@22 java@temurin-21 python@3.12 go@1.24
mise use --global ruby@3.3.6 node@22 java@temurin-21 python@3.12 go@1.24
EOF

# Case 1: no drift
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_mise_version_drift "$TOML_MATCH" "$BOOTSTRAP_REF"
  [[ "$DRIFT_COUNT" -eq 0 ]] || { printf "  FAIL  drift: expected 0, got %s\n" "$DRIFT_COUNT"; exit 1; }
); then
  pass "check_mise_version_drift: matching versions → DRIFT=0"
else
  fail "check_mise_version_drift: matching versions" "subshell exited non-zero"
fi

# Case 2: 2 drifted tools (ruby 3.3.0 vs 3.3.6, node 20 vs 22)
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_mise_version_drift "$TOML_DRIFT" "$BOOTSTRAP_REF"
  [[ "$DRIFT_COUNT" -eq 2 ]] || { printf "  FAIL  drift: expected 2, got %s\n" "$DRIFT_COUNT"; exit 1; }
); then
  pass "check_mise_version_drift: ruby+node drifted → DRIFT=2"
else
  fail "check_mise_version_drift: 2 drifted tools" "subshell exited non-zero"
fi

# Case 3: drift list names the correct tools
drift_items=$(
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_mise_version_drift "$TOML_DRIFT" "$BOOTSTRAP_REF"
  printf '%s\n' "${DRIFT_LIST[@]}"
)
if echo "$drift_items" | grep -q "^ruby:"; then
  pass "check_mise_version_drift: DRIFT_LIST contains ruby entry"
else
  fail "check_mise_version_drift: DRIFT_LIST contains ruby entry" "got: $drift_items"
fi
if echo "$drift_items" | grep -q "^node:"; then
  pass "check_mise_version_drift: DRIFT_LIST contains node entry"
else
  fail "check_mise_version_drift: DRIFT_LIST contains node entry" "got: $drift_items"
fi

# Case 4: ruby absent from toml → detected as drift
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_mise_version_drift "$TOML_MISSING_RUBY" "$BOOTSTRAP_REF"
  [[ "$DRIFT_COUNT" -ge 1 ]] || { printf "  FAIL  drift: expected >= 1, got %s\n" "$DRIFT_COUNT"; exit 1; }
); then
  pass "check_mise_version_drift: ruby missing from toml → DRIFT>=1"
else
  fail "check_mise_version_drift: ruby missing from toml" "subshell exited non-zero"
fi

# ── check_required_tools ──────────────────────────────────────────────────────
echo ""
echo "=== check_required_tools ==="

# Case 1: all present (universally available commands)
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_required_tools bash cat ls
  [[ "$TOOLS_PRESENT_COUNT" -eq 3 ]] || { printf "  FAIL  present: expected 3, got %s\n" "$TOOLS_PRESENT_COUNT"; exit 1; }
  [[ "$TOOLS_MISSING_COUNT" -eq 0 ]] || { printf "  FAIL  missing: expected 0, got %s\n" "$TOOLS_MISSING_COUNT"; exit 1; }
); then
  pass "check_required_tools: all present (bash, cat, ls) → MISSING=0"
else
  fail "check_required_tools: all present" "subshell exited non-zero"
fi

# Case 2: one clearly non-existent tool
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_required_tools bash __nonexistent_tool_xyz__
  [[ "$TOOLS_PRESENT_COUNT" -eq 1 ]] || { printf "  FAIL  present: expected 1, got %s\n" "$TOOLS_PRESENT_COUNT"; exit 1; }
  [[ "$TOOLS_MISSING_COUNT" -eq 1 ]] || { printf "  FAIL  missing: expected 1, got %s\n" "$TOOLS_MISSING_COUNT"; exit 1; }
); then
  pass "check_required_tools: one missing → MISSING=1"
else
  fail "check_required_tools: one missing" "subshell exited non-zero"
fi

# Case 3: missing tool name appears in TOOLS_MISSING_LIST
missing_names=$(
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_required_tools bash __nonexistent_tool_xyz__
  printf '%s\n' "${TOOLS_MISSING_LIST[@]}"
)
if echo "$missing_names" | grep -q "^__nonexistent_tool_xyz__$"; then
  pass "check_required_tools: missing tool name in TOOLS_MISSING_LIST"
else
  fail "check_required_tools: missing tool name in TOOLS_MISSING_LIST" "got: $missing_names"
fi

# Case 4: no tools passed → all counts zero
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_required_tools
  [[ "$TOOLS_PRESENT_COUNT" -eq 0 ]] || { printf "  FAIL  present: expected 0, got %s\n" "$TOOLS_PRESENT_COUNT"; exit 1; }
  [[ "$TOOLS_MISSING_COUNT" -eq 0 ]] || { printf "  FAIL  missing: expected 0, got %s\n" "$TOOLS_MISSING_COUNT"; exit 1; }
); then
  pass "check_required_tools: empty list → all counts zero"
else
  fail "check_required_tools: empty list" "subshell exited non-zero"
fi

# ── check_stale_backups ───────────────────────────────────────────────────────
echo ""
echo "=== check_stale_backups ==="

# Case 1: backup dir does not exist
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_stale_backups "$TMPDIR_BASE/nonexistent_backup_dir"
  [[ "$STALE_BACKUP_COUNT" -eq 0 ]] || { printf "  FAIL  count: expected 0, got %s\n" "$STALE_BACKUP_COUNT"; exit 1; }
); then
  pass "check_stale_backups: no backup dir → STALE=0"
else
  fail "check_stale_backups: no backup dir" "subshell exited non-zero"
fi

# Case 2: backup dir exists but is empty
BACKUP_EMPTY="$TMPDIR_BASE/backup_empty"
mkdir -p "$BACKUP_EMPTY"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_stale_backups "$BACKUP_EMPTY"
  [[ "$STALE_BACKUP_COUNT" -eq 0 ]] || { printf "  FAIL  count: expected 0, got %s\n" "$STALE_BACKUP_COUNT"; exit 1; }
); then
  pass "check_stale_backups: empty backup dir → STALE=0"
else
  fail "check_stale_backups: empty backup dir" "subshell exited non-zero"
fi

# Case 3: recent backup should not be stale (threshold=30)
BACKUP_RECENT="$TMPDIR_BASE/backup_recent"
mkdir -p "$BACKUP_RECENT/20260601_120000"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_stale_backups "$BACKUP_RECENT" 30
  [[ "$STALE_BACKUP_COUNT" -eq 0 ]] || { printf "  FAIL  count: expected 0, got %s\n" "$STALE_BACKUP_COUNT"; exit 1; }
); then
  pass "check_stale_backups: recent backup → not stale"
else
  fail "check_stale_backups: recent backup" "subshell exited non-zero"
fi

# Case 4: old backup detected as stale (backdate via touch -t to Jan 2023)
BACKUP_OLD="$TMPDIR_BASE/backup_old"
mkdir -p "$BACKUP_OLD/20230101_120000"
touch -t 202301010000 "$BACKUP_OLD/20230101_120000"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_stale_backups "$BACKUP_OLD" 30
  [[ "$STALE_BACKUP_COUNT" -eq 1 ]] || { printf "  FAIL  count: expected 1, got %s\n" "$STALE_BACKUP_COUNT"; exit 1; }
); then
  pass "check_stale_backups: backdated backup (Jan 2023) → STALE=1"
else
  fail "check_stale_backups: backdated backup" "subshell exited non-zero"
fi

# Case 5: stale path appears in STALE_BACKUP_LIST
stale_paths=$(
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_stale_backups "$BACKUP_OLD" 30
  printf '%s\n' "${STALE_BACKUP_LIST[@]}"
)
if echo "$stale_paths" | grep -q "20230101_120000"; then
  pass "check_stale_backups: stale dir path in STALE_BACKUP_LIST"
else
  fail "check_stale_backups: stale dir path in STALE_BACKUP_LIST" "got: $stale_paths"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────"
printf "  %d tests: %d passed, %d failed\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
echo "─────────────────────────────────────"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  exit 1
fi
