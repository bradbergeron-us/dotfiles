#!/usr/bin/env bats
# test_validate_templates.bats — unit tests for scripts/validate_templates.sh
# Run: bats scripts/tests/test_validate_templates.bats

load 'test_helper'

setup() {
  VALIDATOR="$SCRIPTS_DIR/validate_templates.sh"
}

# write_template NAME CONTENT → path to a fresh template file
write_template() {
  local path="$BATS_TEST_TMPDIR/$1"
  printf '%s\n' "$2" > "$path"
  printf '%s' "$path"
}

# ── placeholders pass ─────────────────────────────────────────────────────────

@test "placeholder-only template → exit 0" {
  t=$(write_template "ok.template" "email = YOUR_WORK_EMAIL
url = https://nexus.example.com/repo/maven-public
account = 123456789012
password = {encrypted-password-here}
model = us-gov.anthropic.claude-sonnet-4-5-20250929-v1:0")
  run "$VALIDATOR" "$t"
  [ "$status" -eq 0 ]
}

@test "AWS ARN example lines → exit 0" {
  # Mirrors aws/config.template: ARN + role placeholder lines.
  t=$(write_template "arn.template" "role_arn = arn:aws:iam::123456789012:role/AdminRole
mfa_serial = arn:aws:iam::123456789012:mfa/your-username")
  run "$VALIDATOR" "$t"
  [ "$status" -eq 0 ]
}

# ── real secrets fail ─────────────────────────────────────────────────────────
# Fixtures below embed secret-shaped strings on purpose; gitleaks:allow keeps
# the repo's own gitleaks hook from flagging these test inputs.

@test "AWS access key id → exit 1" {
  t=$(write_template "aws.template" "aws_access_key_id = AKIAIOSFODNN7EXAMPLE") # gitleaks:allow
  run "$VALIDATOR" "$t"
  [ "$status" -eq 1 ]
}

@test "GitHub personal access token → exit 1" {
  t=$(write_template "gh.template" "token = ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") # gitleaks:allow
  run "$VALIDATOR" "$t"
  [ "$status" -eq 1 ]
}

@test "long hex blob → exit 1" {
  t=$(write_template "hex.template" "secret = 0123456789abcdef0123456789abcdef0123") # gitleaks:allow
  run "$VALIDATOR" "$t"
  [ "$status" -eq 1 ]
}

@test "credential-bearing URL → exit 1" {
  t=$(write_template "url.template" "db = postgres://admin:supersecretpw@db.internal/app") # gitleaks:allow
  run "$VALIDATOR" "$t"
  [ "$status" -eq 1 ]
}

@test "high-confidence signature flagged despite 'example' marker → exit 1" {
  t=$(write_template "comment.template" "# example token: ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") # gitleaks:allow
  run "$VALIDATOR" "$t"
  [ "$status" -eq 1 ]
}

# ── repository templates ──────────────────────────────────────────────────────

@test "repository templates (no args) → exit 0" {
  # The repo's own tracked templates must be placeholder-only.
  run "$VALIDATOR"
  [ "$status" -eq 0 ]
}
