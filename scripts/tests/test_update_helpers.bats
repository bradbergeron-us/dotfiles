#!/usr/bin/env bats
# test_update_helpers.bats — unit tests for scripts/lib/update_helpers.sh
# Run: bats scripts/tests/test_update_helpers.bats

load 'test_helper'

setup() {
  # shellcheck source=/dev/null
  source "$LIB_DIR/update_helpers.sh"
}

# Init an isolated repo with one commit, no hooks, no signing.
_mkrepo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email t@t
  git -C "$repo" config user.name t
  git -C "$repo" config commit.gpgsign false
  git -C "$repo" config core.hooksPath /dev/null
  printf 'hello\n' > "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -q -m init --no-verify
}

# ── rotate_log ────────────────────────────────────────────────────────────────
@test "rotate_log: under threshold → no rotation" {
  LOG_FILE="$BATS_TEST_TMPDIR/under.log"
  LOG_MAX_BYTES=1048576
  LOG_KEEP=5
  printf 'small\n' > "$LOG_FILE"
  rotate_log
  [ -f "$LOG_FILE" ]
  [ "$(cat "$LOG_FILE")" = "small" ]
  [ ! -e "$LOG_FILE.1" ]
}

@test "rotate_log: over threshold → truncate in place + copy to .1" {
  LOG_FILE="$BATS_TEST_TMPDIR/over.log"
  LOG_MAX_BYTES=10
  LOG_KEEP=5
  printf 'this content exceeds ten bytes\n' > "$LOG_FILE"
  rotate_log
  [ -f "$LOG_FILE" ]
  [ ! -s "$LOG_FILE" ]
  [ -f "$LOG_FILE.1" ]
  grep -q "exceeds ten bytes" "$LOG_FILE.1"
}

@test "rotate_log: shifts .1→.2 and respects LOG_KEEP" {
  LOG_FILE="$BATS_TEST_TMPDIR/shift.log"
  LOG_MAX_BYTES=10
  LOG_KEEP=2
  printf 'NEW oversized current content\n' > "$LOG_FILE"
  printf 'OLD1\n' > "$LOG_FILE.1"
  rotate_log
  grep -q "NEW"  "$LOG_FILE.1"
  grep -q "OLD1" "$LOG_FILE.2"
  [ ! -e "$LOG_FILE.3" ]
}

@test "rotate_log: missing log file → no-op" {
  LOG_FILE="$BATS_TEST_TMPDIR/nonexistent.log"
  LOG_MAX_BYTES=10
  LOG_KEEP=5
  rotate_log
  [ ! -e "$LOG_FILE.1" ]
}

# ── write_status ──────────────────────────────────────────────────────────────
@test "write_status: success → file contains all four keys" {
  LOG_DIR="$BATS_TEST_TMPDIR/logs_ok"
  STATUS_FILE="$LOG_DIR/update.status"
  write_status "2026-06-14T00:00:00Z" "success" "" "42"
  [ -f "$STATUS_FILE" ]
  grep -q "^last_run=2026-06-14T00:00:00Z$" "$STATUS_FILE"
  grep -q "^status=success$"                "$STATUS_FILE"
  grep -q "^failed_steps=$"                 "$STATUS_FILE"
  grep -q "^duration_seconds=42$"           "$STATUS_FILE"
}

@test "write_status: failure → records failed step list" {
  LOG_DIR="$BATS_TEST_TMPDIR/logs_fail"
  STATUS_FILE="$LOG_DIR/update.status"
  write_status "2026-06-14T00:00:00Z" "failure" "Homebrew, Rust" "100"
  grep -q "^status=failure$"              "$STATUS_FILE"
  grep -q "^failed_steps=Homebrew, Rust$" "$STATUS_FILE"
}

# ── can_notify ────────────────────────────────────────────────────────────────
@test "can_notify: CI set → returns false" {
  # Never posts notifications in CI/headless.
  CI=1 run can_notify
  [ "$status" -ne 0 ]
}

# ── working_tree_dirty / rebase_in_progress ───────────────────────────────────
@test "working_tree_dirty: clean repo → false" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  _mkrepo "$BATS_TEST_TMPDIR/wt_clean"
  run working_tree_dirty "$BATS_TEST_TMPDIR/wt_clean"
  [ "$status" -ne 0 ]
}

@test "working_tree_dirty: unstaged change → true" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  _mkrepo "$BATS_TEST_TMPDIR/wt_unstaged"
  printf 'changed\n' >> "$BATS_TEST_TMPDIR/wt_unstaged/file.txt"
  run working_tree_dirty "$BATS_TEST_TMPDIR/wt_unstaged"
  [ "$status" -eq 0 ]
}

@test "working_tree_dirty: staged change → true" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  _mkrepo "$BATS_TEST_TMPDIR/wt_staged"
  printf 'changed\n' >> "$BATS_TEST_TMPDIR/wt_staged/file.txt"
  git -C "$BATS_TEST_TMPDIR/wt_staged" add file.txt
  run working_tree_dirty "$BATS_TEST_TMPDIR/wt_staged"
  [ "$status" -eq 0 ]
}

@test "working_tree_dirty: untracked-only → false" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  _mkrepo "$BATS_TEST_TMPDIR/wt_untracked"
  printf 'new\n' > "$BATS_TEST_TMPDIR/wt_untracked/other.txt"
  run working_tree_dirty "$BATS_TEST_TMPDIR/wt_untracked"
  [ "$status" -ne 0 ]
}

@test "working_tree_dirty: non-git dir → false" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  mkdir -p "$BATS_TEST_TMPDIR/wt_nogit"
  run working_tree_dirty "$BATS_TEST_TMPDIR/wt_nogit"
  [ "$status" -ne 0 ]
}

@test "rebase_in_progress: no rebase → false" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  _mkrepo "$BATS_TEST_TMPDIR/rip_no"
  run rebase_in_progress "$BATS_TEST_TMPDIR/rip_no"
  [ "$status" -ne 0 ]
}

@test "rebase_in_progress: rebase-merge present → true" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  _mkrepo "$BATS_TEST_TMPDIR/rip_yes"
  _gd=$(git -C "$BATS_TEST_TMPDIR/rip_yes" rev-parse --git-dir)
  [[ "$_gd" = /* ]] || _gd="$BATS_TEST_TMPDIR/rip_yes/$_gd"
  mkdir -p "$_gd/rebase-merge"
  run rebase_in_progress "$BATS_TEST_TMPDIR/rip_yes"
  [ "$status" -eq 0 ]
}

# ── read_config_bool ──────────────────────────────────────────────────────────
write_config_fixture() {
  cat > "$BATS_TEST_TMPDIR/update.conf" <<'EOF'
# sample update config
NO_UPGRADE=true
NO_PULL = false
QUOTED="true"
EOF
}

@test "read_config_bool: NO_UPGRADE=true → true" {
  write_config_fixture
  [ "$(read_config_bool "$BATS_TEST_TMPDIR/update.conf" NO_UPGRADE)" = "true" ]
}

@test "read_config_bool: 'NO_PULL = false' (spaces) → false" {
  write_config_fixture
  [ "$(read_config_bool "$BATS_TEST_TMPDIR/update.conf" NO_PULL)" = "false" ]
}

@test "read_config_bool: quoted value → true" {
  write_config_fixture
  [ "$(read_config_bool "$BATS_TEST_TMPDIR/update.conf" QUOTED)" = "true" ]
}

@test "read_config_bool: absent key → empty" {
  write_config_fixture
  [ -z "$(read_config_bool "$BATS_TEST_TMPDIR/update.conf" MISSING_KEY)" ]
}

@test "read_config_bool: missing file → empty" {
  [ -z "$(read_config_bool "$BATS_TEST_TMPDIR/does-not-exist.conf" NO_UPGRADE)" ]
}

@test "read_config_bool: last assignment wins" {
  printf 'NO_UPGRADE=false\nNO_UPGRADE=true\n' > "$BATS_TEST_TMPDIR/last.conf"
  [ "$(read_config_bool "$BATS_TEST_TMPDIR/last.conf" NO_UPGRADE)" = "true" ]
}
