#!/usr/bin/env bats
# test_status_helpers.bats — unit tests for scripts/lib/status_helpers.sh
# Run: bats scripts/tests/test_status_helpers.bats

load 'test_helper'

setup() {
  # shellcheck source=/dev/null
  source "$LIB_DIR/status_helpers.sh"
}

# Init an isolated repo with no hooks and no signing.
_mkrepo() {
  local r="$1"
  mkdir -p "$r"
  git -C "$r" init -q
  git -C "$r" config user.email t@t
  git -C "$r" config user.name t
  git -C "$r" config commit.gpgsign false
  git -C "$r" config core.hooksPath /dev/null
}

# ── read_kv_value ─────────────────────────────────────────────────────────────
write_status_fixture() {
  cat > "$BATS_TEST_TMPDIR/update.status" <<'EOF'
# last run summary
last_run=2026-06-16T03:00:00Z
status=failure
failed_steps=Homebrew, Rust
duration_seconds=42
EOF
}

@test "read_kv_value: last_run" {
  write_status_fixture
  [ "$(read_kv_value "$BATS_TEST_TMPDIR/update.status" last_run)" = "2026-06-16T03:00:00Z" ]
}

@test "read_kv_value: status" {
  write_status_fixture
  [ "$(read_kv_value "$BATS_TEST_TMPDIR/update.status" status)" = "failure" ]
}

@test "read_kv_value: value with spaces/commas preserved" {
  write_status_fixture
  [ "$(read_kv_value "$BATS_TEST_TMPDIR/update.status" failed_steps)" = "Homebrew, Rust" ]
}

@test "read_kv_value: absent key → empty" {
  write_status_fixture
  [ -z "$(read_kv_value "$BATS_TEST_TMPDIR/update.status" missing_key)" ]
}

@test "read_kv_value: missing file → empty" {
  [ -z "$(read_kv_value "$BATS_TEST_TMPDIR/does-not-exist" status)" ]
}

@test "read_kv_value: last assignment wins" {
  printf 'status=success\nstatus=failure\n' > "$BATS_TEST_TMPDIR/last.status"
  [ "$(read_kv_value "$BATS_TEST_TMPDIR/last.status" status)" = "failure" ]
}

@test "read_kv_value: full-line comment skipped; '#' kept in value" {
  printf '# a full-line comment\nnote=a#b\n' > "$BATS_TEST_TMPDIR/hash.status"
  [ "$(read_kv_value "$BATS_TEST_TMPDIR/hash.status" note)" = "a#b" ]
}

# ── git_state ─────────────────────────────────────────────────────────────────
@test "git_state: non-git dir → defaults" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  d="$BATS_TEST_TMPDIR/nogit"; mkdir -p "$d"
  git_state "$d"
  [ -z "$GIT_STATE_BRANCH" ]
  [ "$GIT_STATE_DIRTY" = false ]
  [ "$GIT_STATE_UNTRACKED" = "0" ]
  [ "$GIT_STATE_UPSTREAM" = false ]
}

@test "git_state: clean repo → branch set, not dirty" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  r="$BATS_TEST_TMPDIR/clean"; _mkrepo "$r"
  echo hi > "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m init --no-verify
  git_state "$r"
  [ -n "$GIT_STATE_BRANCH" ]
  [ "$GIT_STATE_DIRTY" = false ]
  [ "$GIT_STATE_UNTRACKED" = "0" ]
  [ "$GIT_STATE_UPSTREAM" = false ]
}

@test "git_state: dirty repo → dirty=true" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  r="$BATS_TEST_TMPDIR/dirty"; _mkrepo "$r"
  echo hi > "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m init --no-verify
  echo more >> "$r/f"
  git_state "$r"
  [ "$GIT_STATE_DIRTY" = true ]
}

@test "git_state: ahead of upstream → ahead=1, behind=0" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  rem="$BATS_TEST_TMPDIR/rem.git"; git init -q --bare "$rem"
  r="$BATS_TEST_TMPDIR/clone"; git clone -q "$rem" "$r"
  git -C "$r" config user.email t@t
  git -C "$r" config user.name t
  git -C "$r" config commit.gpgsign false
  git -C "$r" config core.hooksPath /dev/null
  echo a > "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m c1 --no-verify
  git -C "$r" push -qu origin HEAD
  echo b >> "$r/f"; git -C "$r" commit -q -am c2 --no-verify
  git_state "$r"
  [ "$GIT_STATE_UPSTREAM" = true ]
  [ "$GIT_STATE_AHEAD" = "1" ]
  [ "$GIT_STATE_BEHIND" = "0" ]
}

@test "git_state: untracked-only → dirty=false, untracked=1" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  r="$BATS_TEST_TMPDIR/untracked"; _mkrepo "$r"
  echo hi > "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m init --no-verify
  echo new > "$r/extra.txt"
  git_state "$r"
  [ "$GIT_STATE_DIRTY" = false ]
  [ "$GIT_STATE_UNTRACKED" = "1" ]
}

@test "git_state: detached HEAD → detached@<sha>" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  r="$BATS_TEST_TMPDIR/detached"; _mkrepo "$r"
  echo a > "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m c1 --no-verify
  echo b >> "$r/f"; git -C "$r" add f; git -C "$r" commit -q -m c2 --no-verify
  git -C "$r" checkout -q HEAD~1
  git_state "$r"
  [[ "$GIT_STATE_BRANCH" == detached@* ]]
  [ "$GIT_STATE_UPSTREAM" = false ]
}

@test "git_state: behind upstream → ahead=0, behind=1" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  rem="$BATS_TEST_TMPDIR/brem.git"; git init -q --bare "$rem"
  a="$BATS_TEST_TMPDIR/ba"; git clone -q "$rem" "$a"
  git -C "$a" config user.email t@t; git -C "$a" config user.name t
  git -C "$a" config commit.gpgsign false; git -C "$a" config core.hooksPath /dev/null
  echo a > "$a/f"; git -C "$a" add f; git -C "$a" commit -q -m c1 --no-verify
  git -C "$a" push -qu origin HEAD
  b="$BATS_TEST_TMPDIR/bb"; git clone -q "$rem" "$b"
  git -C "$b" config user.email t@t; git -C "$b" config user.name t
  git -C "$b" config commit.gpgsign false; git -C "$b" config core.hooksPath /dev/null
  echo b >> "$b/f"; git -C "$b" add f; git -C "$b" commit -q -m c2 --no-verify
  git -C "$b" push -q origin HEAD
  git -C "$a" fetch -q
  git_state "$a"
  [ "$GIT_STATE_UPSTREAM" = true ]
  [ "$GIT_STATE_AHEAD" = "0" ]
  [ "$GIT_STATE_BEHIND" = "1" ]
}
