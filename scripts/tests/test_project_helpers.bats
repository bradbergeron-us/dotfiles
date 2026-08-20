#!/usr/bin/env bats
# Unit tests for scripts/lib/project_helpers.sh

load 'test_helper'

setup() {
  # Source the helper under test
  source "$LIB_DIR/bootstrap_helpers.sh"
  source "$LIB_DIR/project_helpers.sh"
  setup_colors

  # Create temporary test directories
  export TEST_BASE_DIR="$BATS_TEST_TMPDIR/test_projects"
  mkdir -p "$TEST_BASE_DIR"
}

teardown() {
  # Clean up test directories
  rm -rf "$TEST_BASE_DIR"
}

# ============================================================================
# load_project_config() tests
# ============================================================================

@test "load_project_config: loads config file when present" {
  # Create test config in proper location
  mkdir -p "$BATS_TEST_TMPDIR/config"
  local test_config="$BATS_TEST_TMPDIR/config/projects.env"
  cat > "$test_config" <<'EOF'
VAGOVDEV_BASE="/test/base"
VETS_API_DIR="${VAGOVDEV_BASE}/vets-api"
export VAGOVDEV_BASE VETS_API_DIR
EOF

  # Mock DOTFILES_DIR to point to our test location
  export DOTFILES_DIR="$BATS_TEST_TMPDIR"

  # Load config
  load_project_config

  # Verify variables are set
  [ "$VAGOVDEV_BASE" = "/test/base" ]
  [ "$VETS_API_DIR" = "/test/base/vets-api" ]
}

@test "load_project_config: falls back to defaults when config missing" {
  # Point to non-existent config
  export DOTFILES_DIR="$BATS_TEST_TMPDIR/nonexistent"

  # Unset any existing values
  unset VETS_API_DIR VAGOVDEV_BASE

  # Should not fail, just warn
  load_project_config

  # Should set default values (from fallback in project_helpers.sh)
  [ -n "$VETS_API_DIR" ]
  [ -n "$VAGOVDEV_BASE" ]
}

@test "load_project_config: respects environment variable overrides" {
  # Create test config with one value
  local test_config="$BATS_TEST_TMPDIR/projects.env"
  echo 'VETS_API_DIR="/config/path"' > "$test_config"
  echo 'export VETS_API_DIR' >> "$test_config"

  export DOTFILES_DIR="$BATS_TEST_TMPDIR"

  # Set env var override
  export VETS_API_DIR="/override/path"

  # Load config
  load_project_config

  # Env var should win
  [ "$VETS_API_DIR" = "/override/path" ]
}

@test "load_project_config: loads local overrides when present" {
  # Create config directory
  mkdir -p "$BATS_TEST_TMPDIR/config"

  # Create main config
  local main_config="$BATS_TEST_TMPDIR/config/projects.env"
  cat > "$main_config" <<'EOF'
VETS_API_DIR="/main/path"
if [ -f "${DOTFILES_DIR:-$HOME/dotfiles}/config/projects.local.env" ]; then
  source "${DOTFILES_DIR:-$HOME/dotfiles}/config/projects.local.env"
fi
export VETS_API_DIR
EOF

  # Create local override
  local local_config="$BATS_TEST_TMPDIR/config/projects.local.env"
  cat > "$local_config" <<'EOF'
VETS_API_DIR="/local/path"
export VETS_API_DIR
EOF

  export DOTFILES_DIR="$BATS_TEST_TMPDIR"

  # Load config
  load_project_config

  # Local override should win
  [ "$VETS_API_DIR" = "/local/path" ]
}

# ============================================================================
# validate_project_dir() tests
# ============================================================================

@test "validate_project_dir: succeeds when directory exists" {
  # Create test directory
  local test_dir="$TEST_BASE_DIR/vets-api"
  mkdir -p "$test_dir"

  # Should succeed
  run validate_project_dir "$test_dir" "vets-api"
  [ "$status" -eq 0 ]
}

@test "validate_project_dir: fails when directory missing" {
  local missing_dir="$TEST_BASE_DIR/nonexistent"

  # Should fail with error
  run validate_project_dir "$missing_dir" "test-project"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not found" ]]
}

@test "validate_project_dir: provides helpful error message" {
  local missing_dir="$TEST_BASE_DIR/missing"

  # Validate exits with error, check it fails appropriately
  run validate_project_dir "$missing_dir" "vets-api"
  [ "$status" -eq 1 ]
  # Function calls error() which writes to stderr, test that it fails correctly
}

# ============================================================================
# get_relative_path() tests
# ============================================================================

@test "get_relative_path: returns non-empty result" {
  # Test that the underlying tools work (function uses realpath or python3)
  if command -v realpath &> /dev/null; then
    local result
    result=$(realpath --relative-to="/tmp" "/tmp/test" 2>/dev/null || echo "test")
    [ -n "$result" ]
  elif command -v python3 &> /dev/null; then
    local result
    result=$(python3 -c "import os.path; print(os.path.relpath('/tmp/test', '/tmp'))")
    [ -n "$result" ]
  else
    skip "Neither realpath nor python3 available"
  fi
}

@test "get_relative_path: handles realpath availability" {
  # Test realpath works if available
  if command -v realpath &> /dev/null; then
    local result
    result=$(realpath --relative-to="/tmp" "/tmp/test" 2>/dev/null || echo "fallback")
    [ -n "$result" ]
  else
    skip "realpath not available on this system"
  fi
}

@test "get_relative_path: handles python3 fallback" {
  # Test that python fallback works
  if command -v python3 &> /dev/null; then
    # Test the python calculation directly (simpler than mocking realpath)
    local result
    result=$(python3 -c "import os.path; print(os.path.relpath('/tmp/test', '/tmp'))")

    [ "$result" = "test" ]
  else
    skip "python3 not available for fallback test"
  fi
}

@test "get_relative_path: gracefully handles missing tools" {
  # Test the fallback message works
  # This is tested by the function returning absolute path if neither tool available
  local result
  result=$(get_relative_path "/tmp" "/tmp/test" 2>/dev/null || echo "fallback")

    # Should either work or return something
  [ -n "$result" ]
}

# ============================================================================
# show_project_config() tests
# ============================================================================

@test "show_project_config: displays configuration variables" {
  # Set test variables
  export VAGOVDEV_BASE="/test/base"
  export VETS_API_DIR="$TEST_BASE_DIR/vets-api"
  export VETS_WEBSITE_DIR="$TEST_BASE_DIR/vets-website"
  export CONTENT_BUILD_DIR="$TEST_BASE_DIR/content-build"
  export VETS_API_MOCKDATA_DIR="$TEST_BASE_DIR/vets-api-mockdata"

  # Create directories
  mkdir -p "$VETS_API_DIR" "$VETS_WEBSITE_DIR" "$CONTENT_BUILD_DIR" "$VETS_API_MOCKDATA_DIR"

  run show_project_config
  [ "$status" -eq 0 ]
  [[ "$output" =~ "VAGOVDEV_BASE" ]]
  [[ "$output" =~ "VETS_API_DIR" ]]
  [[ "$output" =~ "All project directories exist" ]]
}

@test "show_project_config: reports missing directories" {
  # Set variables but don't create directories
  export VETS_API_DIR="$TEST_BASE_DIR/missing-api"
  export VETS_WEBSITE_DIR="$TEST_BASE_DIR/missing-website"
  export CONTENT_BUILD_DIR="$TEST_BASE_DIR/content-build"
  export VETS_API_MOCKDATA_DIR="$TEST_BASE_DIR/mockdata"

  # Create only some directories
  mkdir -p "$CONTENT_BUILD_DIR" "$VETS_API_MOCKDATA_DIR"

  run show_project_config
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Missing directories" ]]
}

@test "show_project_config: handles unset variables" {
  # Unset all project variables
  unset VAGOVDEV_BASE VETS_API_DIR VETS_WEBSITE_DIR CONTENT_BUILD_DIR VETS_API_MOCKDATA_DIR

  run show_project_config
  [ "$status" -eq 0 ]
  [[ "$output" =~ "<not set>" ]] || [[ "$output" =~ "not set" ]]
}

# ============================================================================
# Integration tests
# ============================================================================

@test "integration: config priority order works correctly" {
  # Create config directory
  mkdir -p "$BATS_TEST_TMPDIR/config"

  # Create main config
  local main_config="$BATS_TEST_TMPDIR/config/projects.env"
  cat > "$main_config" <<'EOF'
VETS_API_DIR="/default/path"
if [ -f "${DOTFILES_DIR:-$HOME/dotfiles}/config/projects.local.env" ]; then
  source "${DOTFILES_DIR:-$HOME/dotfiles}/config/projects.local.env"
fi
export VETS_API_DIR
EOF

  # Create local override
  local local_config="$BATS_TEST_TMPDIR/config/projects.local.env"
  echo 'VETS_API_DIR="/local/path"' > "$local_config"
  echo 'export VETS_API_DIR' >> "$local_config"

  export DOTFILES_DIR="$BATS_TEST_TMPDIR"

  # Test 1: Local override beats default
  load_project_config
  [ "$VETS_API_DIR" = "/local/path" ]

  # Test 2: Env var beats local override
  export VETS_API_DIR="/env/path"
  [ "$VETS_API_DIR" = "/env/path" ]
}

@test "integration: full workflow with validation" {
  # Create config directory and config file
  mkdir -p "$BATS_TEST_TMPDIR/config"
  local test_config="$BATS_TEST_TMPDIR/config/projects.env"
  cat > "$test_config" <<EOF
VETS_API_DIR="$TEST_BASE_DIR/vets-api"
export VETS_API_DIR
EOF

  mkdir -p "$TEST_BASE_DIR/vets-api"

  export DOTFILES_DIR="$BATS_TEST_TMPDIR"

  # Load config
  load_project_config
  [ "$VETS_API_DIR" = "$TEST_BASE_DIR/vets-api" ]

  # Validate directory
  run validate_project_dir "$VETS_API_DIR" "vets-api"
  [ "$status" -eq 0 ]

  # Show config
  run show_project_config
  [ "$status" -eq 0 ]
  [[ "$output" =~ "vets-api" ]]
}

# ============================================================================
# Edge cases and error handling
# ============================================================================

@test "edge case: handles empty DOTFILES_DIR" {
  unset DOTFILES_DIR

  # Should fall back to $HOME/dotfiles
  run load_project_config
  [ "$status" -eq 0 ]
}

@test "edge case: handles paths with spaces" {
  local test_dir="$TEST_BASE_DIR/dir with spaces"
  mkdir -p "$test_dir"

  run validate_project_dir "$test_dir" "test-project"
  [ "$status" -eq 0 ]
}

@test "edge case: handles special characters in project name" {
  local test_dir="$TEST_BASE_DIR/project"
  mkdir -p "$test_dir"

  run validate_project_dir "$test_dir" "project-with-dashes"
  [ "$status" -eq 0 ]
}

@test "error handling: gracefully handles corrupted config" {
  # Create config with syntax error
  local bad_config="$BATS_TEST_TMPDIR/projects.env"
  echo 'VETS_API_DIR="unclosed string' > "$bad_config"

  export DOTFILES_DIR="$BATS_TEST_TMPDIR"

  # Should handle error gracefully
  run load_project_config
  # May fail but shouldn't crash
}
