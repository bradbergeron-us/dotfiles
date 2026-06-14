#!/usr/bin/env bash
# test_validate_templates.sh — unit tests for validate_templates.sh
# Usage: bash scripts/test_validate_templates.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATOR="$SCRIPT_DIR/validate_templates.sh"

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

# run_validator FILE → echoes exit code (never aborts the harness)
run_validator() {
  local rc=0
  "$VALIDATOR" "$1" >/dev/null 2>&1 || rc=$?
  printf '%s' "$rc"
}

# write_template NAME CONTENT → path to a fresh template file
write_template() {
  local path="$TMPDIR_BASE/$1"
  printf '%s\n' "$2" > "$path"
  printf '%s' "$path"
}

echo ""
echo "=== validate_templates: placeholders pass ==="

# Case 1: documented placeholders → exit 0
t=$(write_template "ok.template" "email = YOUR_WORK_EMAIL
url = https://nexus.example.com/repo/maven-public
account = 123456789012
password = {encrypted-password-here}
model = us-gov.anthropic.claude-sonnet-4-5-20250929-v1:0")
rc=$(run_validator "$t")
if [[ "$rc" -eq 0 ]]; then
  pass "placeholder-only template → exit 0"
else
  fail "placeholder-only template" "expected exit 0, got $rc"
fi

# Case 2: ARN + role placeholder lines → exit 0 (mirrors aws/config.template)
t=$(write_template "arn.template" "role_arn = arn:aws:iam::123456789012:role/AdminRole
mfa_serial = arn:aws:iam::123456789012:mfa/your-username")
rc=$(run_validator "$t")
if [[ "$rc" -eq 0 ]]; then
  pass "AWS ARN example lines → exit 0"
else
  fail "AWS ARN example lines" "expected exit 0, got $rc"
fi

echo ""
echo "=== validate_templates: real secrets fail ==="

# Case 3: AWS access key id → exit 1
# Fixtures below embed secret-shaped strings on purpose; gitleaks:allow keeps
# the repo's own gitleaks hook from flagging these test inputs.
t=$(write_template "aws.template" "aws_access_key_id = AKIAIOSFODNN7EXAMPLE") # gitleaks:allow
rc=$(run_validator "$t")
if [[ "$rc" -eq 1 ]]; then
  pass "AWS access key id → exit 1"
else
  fail "AWS access key id" "expected exit 1, got $rc"
fi

# Case 4: GitHub PAT → exit 1
t=$(write_template "gh.template" "token = ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") # gitleaks:allow
rc=$(run_validator "$t")
if [[ "$rc" -eq 1 ]]; then
  pass "GitHub personal access token → exit 1"
else
  fail "GitHub personal access token" "expected exit 1, got $rc"
fi

# Case 5: long hex blob → exit 1
t=$(write_template "hex.template" "secret = 0123456789abcdef0123456789abcdef0123") # gitleaks:allow
rc=$(run_validator "$t")
if [[ "$rc" -eq 1 ]]; then
  pass "long hex blob → exit 1"
else
  fail "long hex blob" "expected exit 1, got $rc"
fi

# Case 6: credential-bearing URL → exit 1
t=$(write_template "url.template" "db = postgres://admin:supersecretpw@db.internal/app") # gitleaks:allow
rc=$(run_validator "$t")
if [[ "$rc" -eq 1 ]]; then
  pass "credential-bearing URL → exit 1"
else
  fail "credential-bearing URL" "expected exit 1, got $rc"
fi

# Case 7: high-confidence signature fires even on an 'example' line
t=$(write_template "comment.template" "# example token: ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") # gitleaks:allow
rc=$(run_validator "$t")
if [[ "$rc" -eq 1 ]]; then
  pass "high-confidence signature flagged despite 'example' marker → exit 1"
else
  fail "high-confidence signature on example line" "expected exit 1, got $rc"
fi

echo ""
echo "=== validate_templates: repository templates ==="

# Case 8: the repo's own tracked templates must be placeholder-only
rc=0
"$VALIDATOR" >/dev/null 2>&1 || rc=$?
if [[ "$rc" -eq 0 ]]; then
  pass "repository templates ($REPO_ROOT) → exit 0"
else
  fail "repository templates" "expected exit 0, got $rc"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────"
printf "  %d run · %d passed · %d failed\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
echo "─────────────────────────────────────────────"

[[ "$TESTS_FAILED" -eq 0 ]] || exit 1
