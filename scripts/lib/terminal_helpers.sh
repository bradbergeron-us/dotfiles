#!/bin/bash
# terminal_helpers.sh - Helper functions for terminal emulator operations

# Configuration file to store terminal preference
TERMINAL_CONFIG_FILE="$HOME/.dotfiles_terminal_preference"

# Get the user's preferred terminal emulator
# If not set, prompt them to choose and store the preference
# Pass "quiet" as first argument to suppress output after setup
get_terminal_emulator() {
  local quiet_mode="$1"

  if [ -f "$TERMINAL_CONFIG_FILE" ]; then
    cat "$TERMINAL_CONFIG_FILE"
    return 0
  fi

  # No preference stored, prompt user
  echo ""
  echo "========================================"
  echo "⚙️  First-Time Terminal Setup Required"
  echo "========================================"
  echo ""
  echo "This script needs to open new terminal tabs."
  echo "Please select your terminal emulator:"
  echo ""
  echo "  1) Hyper"
  echo "  2) macOS Terminal (Terminal.app)"
  echo "  3) iTerm2"
  echo ""
  echo "Your choice will be saved for future use."
  echo "(Run 'reset_terminal_preference' to change later)"
  echo ""
  read -r -p "Enter choice [1-3] (default: 2): " TERMINAL_CHOICE
  echo ""

  case $TERMINAL_CHOICE in
    1)
      TERMINAL="Hyper"
      ;;
    2|"")
      TERMINAL="Terminal"
      ;;
    3)
      TERMINAL="iTerm"
      ;;
    *)
      echo "⚠️  Invalid choice. Defaulting to macOS Terminal."
      TERMINAL="Terminal"
      ;;
  esac

  # Store the preference
  echo "$TERMINAL" > "$TERMINAL_CONFIG_FILE"
  echo "✓ Terminal preference saved: $TERMINAL"
  echo ""

  # Output terminal name for command substitution (unless in quiet mode)
  if [ "$quiet_mode" != "quiet" ]; then
    cat "$TERMINAL_CONFIG_FILE"
  fi
}

# Ensure terminal preference is set before running scripts
# Call this at the start of scripts that use open_terminal_tab
# This ensures the terminal selection happens upfront, not mid-execution
ensure_terminal_configured() {
  if [ ! -f "$TERMINAL_CONFIG_FILE" ]; then
    # Terminal not configured yet - trigger the setup in quiet mode
    # This displays the menu and confirmation but not the redundant terminal name
    get_terminal_emulator quiet
  fi
}

# Open a new tab and execute a command
# Usage: open_terminal_tab "command to execute"
open_terminal_tab() {
  local COMMAND="$1"
  local TERMINAL
  TERMINAL=$(get_terminal_emulator)

  case $TERMINAL in
    Hyper)
      osascript <<EOF
tell application "Hyper"
    activate
    delay 0.3
    tell application "System Events"
        keystroke "t" using {command down}
        delay 0.5
        keystroke "$COMMAND"
        keystroke return
    end tell
end tell
EOF
      ;;
    Terminal)
      osascript <<EOF
tell application "Terminal"
    activate
    delay 0.3
    tell application "System Events"
        keystroke "t" using {command down}
        delay 0.5
    end tell
    delay 0.3
    do script "$COMMAND" in front window
end tell
EOF
      ;;
    iTerm)
      osascript <<EOF
tell application "iTerm"
    activate
    delay 0.3
    tell current window
        create tab with default profile
        tell current session
            write text "$COMMAND"
        end tell
    end tell
end tell
EOF
      ;;
    *)
      echo "Unknown terminal: $TERMINAL"
      echo "Falling back to macOS Terminal"
      osascript <<EOF
tell application "Terminal"
    activate
    delay 0.3
    tell application "System Events"
        keystroke "t" using {command down}
        delay 0.5
    end tell
    delay 0.3
    do script "$COMMAND" in front window
end tell
EOF
      ;;
  esac
}

# Reset terminal preference (for testing or changing preference)
reset_terminal_preference() {
  if [ -f "$TERMINAL_CONFIG_FILE" ]; then
    rm "$TERMINAL_CONFIG_FILE"
    echo "Terminal preference reset. You'll be prompted on next use."
  else
    echo "No terminal preference was set."
  fi
}
