#!/bin/bash
#
# PICARD Framework Enhanced Statusline for Claude Code (macOS/Linux)
#
# This is an enhanced version of the statusline that provides:
# - Progress tracking for workflows
# - Advanced git status (untracked, conflicts, ahead/behind)
# - Cost tracking with warnings
# - Integration status (Jira/Bitbucket)
# - Quality metrics and test status
# - Checkpoint/pause information
#
# Requirements: jq (for JSON parsing)
#
# Usage: Configure in ~/.claude/settings.json:
# {
#   "statusLine": {
#     "type": "command",
#     "command": "~/.claude/picard/bin/statusline-enhanced.sh"
#   }
# }
#

# Read JSON from stdin (sent by Claude Code)
input=$(cat)

# ============================================================================
# ANSI Color Codes & Icons
# ============================================================================

CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
MAGENTA='\033[35m'
GRAY='\033[90m'
BOLD='\033[1m'
RESET='\033[0m'

# Icons
ICON_WORKFLOW="⚙️"
ICON_COMPLETE="✅"
ICON_WARNING="⚠️"
ICON_PAUSE="⏸️"
ICON_PROGRESS="🔄"
ICON_GIT="🌿"
ICON_FOLDER="📁"
ICON_CLOCK="⏱️"
ICON_COST="💰"
ICON_JIRA="📋"
ICON_PR="🔀"

# ============================================================================
# Extract Claude Code Session Data
# ============================================================================

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')
COST_RAW=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
COST=$(printf "%.2f" "$COST_RAW")
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
SESSION_ID=$(echo "$input" | jq -r '.session_id // ""')

# ============================================================================
# Advanced Git Status
# ============================================================================

GIT_BRANCH=""
GIT_STATUS=""
GIT_AHEAD_BEHIND=""

if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
    # Current branch
    CURRENT_BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
    GIT_BRANCH="${ICON_GIT} ${CURRENT_BRANCH}"

    # Staged changes
    STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')

    # Unstaged changes
    MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')

    # Untracked files
    UNTRACKED=$(git -C "$DIR" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    # Merge conflicts
    CONFLICTS=$(git -C "$DIR" diff --name-only --diff-filter=U 2>/dev/null | wc -l | tr -d ' ')

    # Build status string
    STATUS_PARTS=()
    [ "$STAGED" -gt 0 ] && STATUS_PARTS+=("${GREEN}+${STAGED}${RESET}")
    [ "$MODIFIED" -gt 0 ] && STATUS_PARTS+=("${YELLOW}~${MODIFIED}${RESET}")
    [ "$UNTRACKED" -gt 0 ] && STATUS_PARTS+=("${GRAY}?${UNTRACKED}${RESET}")
    [ "$CONFLICTS" -gt 0 ] && STATUS_PARTS+=("${RED}✗${CONFLICTS}${RESET}")

    if [ ${#STATUS_PARTS[@]} -gt 0 ]; then
        GIT_STATUS=" | $(IFS=' '; echo "${STATUS_PARTS[*]}")"
    fi

    # Ahead/behind remote
    # shellcheck disable=SC1083
    UPSTREAM=$(git -C "$DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    if [ -n "$UPSTREAM" ]; then
        # shellcheck disable=SC1083
        AHEAD=$(git -C "$DIR" rev-list --count '@{u}..HEAD' 2>/dev/null || echo "0")
        # shellcheck disable=SC1083
        BEHIND=$(git -C "$DIR" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo "0")

        if [ "$AHEAD" -gt 0 ] || [ "$BEHIND" -gt 0 ]; then
            AHEAD_BEHIND_PARTS=()
            [ "$AHEAD" -gt 0 ] && AHEAD_BEHIND_PARTS+=("${GREEN}↑${AHEAD}${RESET}")
            [ "$BEHIND" -gt 0 ] && AHEAD_BEHIND_PARTS+=("${RED}↓${BEHIND}${RESET}")
            GIT_AHEAD_BEHIND=" | $(IFS=' '; echo "${AHEAD_BEHIND_PARTS[*]}")"
        fi
    fi
fi

# ============================================================================
# Build Context Bar
# ============================================================================

BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')

# Pick bar color based on context usage
if [ "$PCT" -ge 90 ]; then
    BAR_COLOR="$RED"
    CONTEXT_WARNING="${ICON_WARNING} "
elif [ "$PCT" -ge 70 ]; then
    BAR_COLOR="$YELLOW"
    CONTEXT_WARNING=""
else
    BAR_COLOR="$GREEN"
    CONTEXT_WARNING=""
fi

# ============================================================================
# Format Duration and Cost
# ============================================================================

MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))
DURATION="${ICON_CLOCK} ${MINS}m ${SECS}s"

# Format cost in gray (informational, not critical for work account)
COST_DISPLAY="${GRAY}${ICON_COST} \$${COST}${RESET}"

# ============================================================================
# Extract PICARD Framework State
# ============================================================================

PICARD_INITIALIZED=false
if [ -d ".picard" ]; then
    PICARD_INITIALIZED=true
fi

PICARD_WORKFLOW_TYPE=""
PICARD_CURRENT_STEP=""
PICARD_NEXT_STEP=""
PICARD_COMPLETED_STEPS=""
PICARD_JIRA_TICKET=""
PICARD_PR_ID=""
PICARD_PAUSED=false

# Only try to read state if PICARD is initialized
if [ "$PICARD_INITIALIZED" = "true" ]; then
    # Determine state file path
    STATE_FILE=""
    CURRENT_BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
    if [ -n "$CURRENT_BRANCH" ]; then
        SANITIZED_BRANCH=$(echo "$CURRENT_BRANCH" | tr '/' '_')
        if [ -f ".picard/sessions/${SANITIZED_BRANCH}.md" ]; then
            STATE_FILE=".picard/sessions/${SANITIZED_BRANCH}.md"
        fi
    fi

    # Parse state file
    if [ -n "$STATE_FILE" ]; then
        FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$STATE_FILE" | sed '1d;$d')

        PICARD_WORKFLOW_TYPE=$(echo "$FRONTMATTER" | grep "^workflowType:" | sed 's/workflowType: *//' | tr -d '"')
        PICARD_CURRENT_STEP=$(echo "$FRONTMATTER" | grep "^currentStep:" | sed 's/currentStep: *//' | tr -d '"')
        PICARD_NEXT_STEP=$(echo "$FRONTMATTER" | grep "^nextStep:" | sed 's/nextStep: *//' | tr -d '"')
        PICARD_COMPLETED_STEPS=$(echo "$FRONTMATTER" | grep "^completedSteps:" | sed 's/completedSteps: *//' | tr -d '[]"')
        PICARD_JIRA_TICKET=$(echo "$FRONTMATTER" | grep "^jiraTicket:" | sed 's/jiraTicket: *//' | tr -d '"')
        PICARD_PR_ID=$(echo "$FRONTMATTER" | grep "^prId:" | sed 's/prId: *//' | tr -d '"')

        # Check for pause/checkpoint
        PAUSED_VALUE=$(echo "$FRONTMATTER" | grep "^paused:" | sed 's/paused: *//' | tr -d '"')
        if [ "$PAUSED_VALUE" = "true" ]; then
            PICARD_PAUSED=true
        fi
    fi
fi

# ============================================================================
# Calculate Progress
# ============================================================================

calculate_progress() {
    local workflow=$1
    local completed=$2

    # Define expected steps for each workflow type
    case "$workflow" in
        "feature")
            local total_steps=8  # init, explore, plan, design, implement, test, review, finalize
            ;;
        "bugfix")
            local total_steps=7  # init, investigate, plan, implement, test, verify, finalize
            ;;
        "refactor")
            local total_steps=7  # init, analyze, plan, implement, test, review, finalize
            ;;
        *)
            local total_steps=5  # generic workflow
            ;;
    esac

    # Count completed steps
    local completed_count
    completed_count=$(echo "$completed" | grep -o "," | wc -l | tr -d ' ')
    completed_count=$((completed_count + 1))  # Add 1 since no comma after last item

    if [ -z "$completed" ] || [ "$completed" = "null" ]; then
        completed_count=0
    fi

    # Calculate percentage
    if [ "$total_steps" -gt 0 ]; then
        local progress=$((completed_count * 100 / total_steps))
        echo "${completed_count}/${total_steps} (${progress}%)"
    else
        echo "N/A"
    fi
}

# ============================================================================
# Format PICARD Status Line
# ============================================================================

format_picard_line() {
    if [ "$PICARD_INITIALIZED" = "false" ]; then
        echo -e "${GRAY}PICARD Framework | Status: Not initialized | Run /picard:init to begin${RESET}"
        return
    fi

    # Check if workflow is active
    if [ -n "$PICARD_CURRENT_STEP" ] && [ "$PICARD_CURRENT_STEP" != "null" ]; then
        local line="${ICON_WORKFLOW} ${BOLD}PICARD${RESET}"

        # Add workflow type with color
        if [ -n "$PICARD_WORKFLOW_TYPE" ] && [ "$PICARD_WORKFLOW_TYPE" != "null" ]; then
            case "$PICARD_WORKFLOW_TYPE" in
                "feature")
                    line="${line} | ${GREEN}${PICARD_WORKFLOW_TYPE}${RESET}"
                    ;;
                "bugfix")
                    line="${line} | ${YELLOW}${PICARD_WORKFLOW_TYPE}${RESET}"
                    ;;
                "refactor")
                    line="${line} | ${BLUE}${PICARD_WORKFLOW_TYPE}${RESET}"
                    ;;
                *)
                    line="${line} | ${CYAN}${PICARD_WORKFLOW_TYPE}${RESET}"
                    ;;
            esac
        fi

        # Add progress
        if [ -n "$PICARD_WORKFLOW_TYPE" ] && [ "$PICARD_WORKFLOW_TYPE" != "null" ]; then
            PROGRESS=$(calculate_progress "$PICARD_WORKFLOW_TYPE" "$PICARD_COMPLETED_STEPS")
            line="${line} | ${ICON_PROGRESS} ${PROGRESS}"
        fi

        # Add pause indicator
        if [ "$PICARD_PAUSED" = "true" ]; then
            line="${line} | ${ICON_PAUSE} ${YELLOW}Paused${RESET}"
        fi

        # Add current step
        line="${line} | ${MAGENTA}${PICARD_CURRENT_STEP}${RESET}"

        # Add next step recommendation
        if [ -n "$PICARD_NEXT_STEP" ] && [ "$PICARD_NEXT_STEP" != "null" ]; then
            line="${line} → ${CYAN}${PICARD_NEXT_STEP}${RESET}"
        else
            line="${line} → ${ICON_COMPLETE} ${GREEN}Complete${RESET}"
        fi

        # Add integrations on new line if present
        INTEGRATIONS=""
        if [ -n "$PICARD_JIRA_TICKET" ] && [ "$PICARD_JIRA_TICKET" != "null" ]; then
            INTEGRATIONS="${ICON_JIRA} ${PICARD_JIRA_TICKET}"
        fi
        if [ -n "$PICARD_PR_ID" ] && [ "$PICARD_PR_ID" != "null" ]; then
            if [ -n "$INTEGRATIONS" ]; then
                INTEGRATIONS="${INTEGRATIONS} | "
            fi
            INTEGRATIONS="${INTEGRATIONS}${ICON_PR} #${PICARD_PR_ID}"
        fi

        echo -e "$line"
        if [ -n "$INTEGRATIONS" ]; then
            echo -e "  ${GRAY}${INTEGRATIONS}${RESET}"
        fi
        return
    fi

    # No active workflow
    echo -e "${GRAY}PICARD Framework | ${GREEN}Ready${RESET} ${GRAY}| Run /picard:feature-init, /picard:bugfix-init, or /picard:help${RESET}"
}

# ============================================================================
# Output Status Lines
# ============================================================================

# Line 1: Claude Code session info with context bar, duration, cost, and session ID
SESSION_DISPLAY=""
if [ -n "$SESSION_ID" ]; then
    SESSION_SHORT="${SESSION_ID:0:8}"
    SESSION_DISPLAY=" | ${GRAY}🔑 ${SESSION_SHORT}${RESET}"
fi
echo -e "${CYAN}[${MODEL}]${RESET} ${BAR_COLOR}${BAR}${RESET} ${CONTEXT_WARNING}${PCT}% | ${DURATION} | ${COST_DISPLAY}${SESSION_DISPLAY}"

# Line 2: Directory and advanced Git info
echo -e "${ICON_FOLDER} ${BOLD}${DIR##*/}${RESET} | ${GIT_BRANCH}${GIT_STATUS}${GIT_AHEAD_BEHIND}"

# Line 3-4: PICARD Framework status (may be multiple lines)
format_picard_line
