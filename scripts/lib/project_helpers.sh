#!/usr/bin/env bash
#
# Project Helpers
#
# Helper functions for loading and validating project configurations.
# Used by VA.gov development scripts to locate project directories.
#
# Usage:
#   source "$DOTFILES_DIR/scripts/lib/project_helpers.sh"
#   load_project_config
#   validate_project_dir "$VETS_API_DIR" "vets-api"

# Load project configuration from config/projects.env
#
# Reads project directory paths from configuration file.
# Falls back to legacy hardcoded paths with a warning if config not found.
#
# Sets: VETS_API_DIR, VETS_WEBSITE_DIR, CONTENT_BUILD_DIR, VETS_API_MOCKDATA_DIR
load_project_config() {
  local config_file="${DOTFILES_DIR:-$HOME/dotfiles}/config/projects.env"

  if [[ -f "$config_file" ]]; then
    # shellcheck source=../../config/projects.env
    source "$config_file"
  else
    # Fallback to legacy hardcoded paths with warning
    warn "Project configuration not found: $config_file"
    warn "Using legacy hardcoded paths. Consider creating config/projects.env"
    info "Copy from: ${DOTFILES_DIR:-$HOME/dotfiles}/config/projects.env.example"

    # Legacy defaults
    export VAGOVDEV_BASE="${VAGOVDEV_BASE:-${HOME}/Code/va.gov}"
    export VETS_API_DIR="${VETS_API_DIR:-${VAGOVDEV_BASE}/vets-api}"
    export VETS_WEBSITE_DIR="${VETS_WEBSITE_DIR:-${VAGOVDEV_BASE}/vets-website}"
    export CONTENT_BUILD_DIR="${CONTENT_BUILD_DIR:-${VAGOVDEV_BASE}/content-build}"
    export VETS_API_MOCKDATA_DIR="${VETS_API_MOCKDATA_DIR:-${VAGOVDEV_BASE}/vets-api-mockdata}"
  fi
}

# Validate that a project directory exists
#
# Usage:
#   validate_project_dir "$VETS_API_DIR" "vets-api"
#
# Arguments:
#   $1 - Directory path to validate
#   $2 - Project name (for error messages)
#
# Returns:
#   0 if directory exists
#   1 if directory does not exist (also exits script)
validate_project_dir() {
  local dir_path="$1"
  local project_name="$2"

  if [[ ! -d "$dir_path" ]]; then
    # Convert project name to env var format (e.g., "vets-api" -> "VETS_API")
    local env_var_name="${project_name^^}"
    env_var_name="${env_var_name//-/_}"

    error "${project_name} directory not found at: $dir_path"
    info "Update project paths in: ${DOTFILES_DIR:-$HOME/dotfiles}/config/projects.env"
    info "Or set ${env_var_name}_DIR environment variable"
    exit 1
  fi

  return 0
}

# Get the relative path from one directory to another
#
# Usage:
#   rel_path=$(get_relative_path "/from/dir" "/to/dir")
#
# Arguments:
#   $1 - Source directory
#   $2 - Target directory
#
# Returns:
#   Relative path from source to target
get_relative_path() {
  local source="$1"
  local target="$2"

  # Use realpath if available, otherwise use python
  if command -v realpath &> /dev/null; then
    realpath --relative-to="$source" "$target" 2>/dev/null
  elif command -v python3 &> /dev/null; then
    python3 -c "import os.path; print(os.path.relpath('$target', '$source'))"
  else
    warn "Neither realpath nor python3 available for path calculation"
    echo "$target"  # Return absolute path as fallback
  fi
}

# Display current project configuration
#
# Useful for debugging and verifying configuration
show_project_config() {
  info "Current project configuration:"
  echo "  VAGOVDEV_BASE:         ${VAGOVDEV_BASE:-<not set>}"
  echo "  VETS_API_DIR:          ${VETS_API_DIR:-<not set>}"
  echo "  VETS_WEBSITE_DIR:      ${VETS_WEBSITE_DIR:-<not set>}"
  echo "  CONTENT_BUILD_DIR:     ${CONTENT_BUILD_DIR:-<not set>}"
  echo "  VETS_API_MOCKDATA_DIR: ${VETS_API_MOCKDATA_DIR:-<not set>}"
  echo ""

  # Check which directories actually exist
  local missing=()
  [[ ! -d "$VETS_API_DIR" ]] && missing+=("vets-api")
  [[ ! -d "$VETS_WEBSITE_DIR" ]] && missing+=("vets-website")
  [[ ! -d "$CONTENT_BUILD_DIR" ]] && missing+=("content-build")
  [[ ! -d "$VETS_API_MOCKDATA_DIR" ]] && missing+=("vets-api-mockdata")

  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Missing directories: ${missing[*]}"
    info "Update paths in: ${DOTFILES_DIR:-$HOME/dotfiles}/config/projects.env"
  else
    success "All project directories exist"
  fi
}
