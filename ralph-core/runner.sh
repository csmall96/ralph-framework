#!/bin/bash
# Ralph Core Runner - Generic loop for any Ralph variant
# Usage: ./runner.sh <variant_dir> [max_iterations]
#
# The variant_dir should contain:
#   - config.yaml: Variant configuration
#   - prompt.md: Agent instructions for this variant

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

VARIANT_DIR="${1:?Usage: runner.sh <variant_dir> [max_iterations]}"
MAX_ITERATIONS=${2:-10}

# Resolve paths
VARIANT_DIR="$(cd "$VARIANT_DIR" && pwd)"
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$VARIANT_DIR/config.yaml"
PROMPT_FILE="$VARIANT_DIR/prompt.md"

# Verify required files exist
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: config.yaml not found in $VARIANT_DIR"
  exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: prompt.md not found in $VARIANT_DIR"
  exit 1
fi

# ============================================================================
# PARSE CONFIG (simple yaml parsing without external deps)
# ============================================================================

# Extract a simple key: value from yaml (handles top-level keys only)
yaml_get() {
  local key="$1"
  local file="$2"
  grep "^${key}:" "$file" 2>/dev/null | head -1 | sed "s/^${key}:[[:space:]]*//" | sed 's/[[:space:]]*$//' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//'
}

# Read config values
VARIANT_NAME=$(yaml_get "name" "$CONFIG_FILE")
DATA_DIR=$(yaml_get "data_dir" "$CONFIG_FILE")
BRANCH_PREFIX=$(yaml_get "branch_prefix" "$CONFIG_FILE")
REQUIRES_GIT=$(yaml_get "requires_git" "$CONFIG_FILE")

# Default values
VARIANT_NAME=${VARIANT_NAME:-"ralph"}
DATA_DIR=${DATA_DIR:-"scripts/ralph"}
BRANCH_PREFIX=${BRANCH_PREFIX:-"ralph/"}
REQUIRES_GIT=${REQUIRES_GIT:-"true"}  # Default to true for backward compatibility

# Find project root (go up from variant dir until we find .git or reach /)
find_project_root() {
  local dir="$VARIANT_DIR"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then
      echo "$dir"
      return
    fi
    dir="$(dirname "$dir")"
  done
  # Fallback: assume 3 levels up from variant (.claude/skills/ralph/)
  echo "$(cd "$VARIANT_DIR/../../.." && pwd)"
}

PROJECT_ROOT=$(find_project_root)

# Resolve data_dir relative to project root
if [[ "$DATA_DIR" != /* ]]; then
  DATA_DIR="$PROJECT_ROOT/$DATA_DIR"
fi

# Runtime file paths
PRD_FILE="$DATA_DIR/prd.json"
PROGRESS_FILE="$DATA_DIR/progress.txt"
ARCHIVE_DIR="$DATA_DIR/archive"
LAST_BRANCH_FILE="$DATA_DIR/.last-branch"

# ============================================================================
# ARCHIVE PREVIOUS RUN (if branch changed) — only for git-based variants
# ============================================================================

if [ "$REQUIRES_GIT" = "true" ]; then
  if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
    CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
    LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

    if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
      DATE=$(date +%Y-%m-%d)
      # Strip branch prefix for folder name
      FOLDER_NAME=$(echo "$LAST_BRANCH" | sed "s|^${BRANCH_PREFIX}||")
      ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

      echo "Archiving previous run: $LAST_BRANCH"
      mkdir -p "$ARCHIVE_FOLDER"
      [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
      [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
      echo "   Archived to: $ARCHIVE_FOLDER"

      # Reset progress file for new run
      echo "# Ralph Progress Log ($VARIANT_NAME)" > "$PROGRESS_FILE"
      echo "Started: $(date)" >> "$PROGRESS_FILE"
      echo "---" >> "$PROGRESS_FILE"
    fi
  fi

  # Track current branch
  if [ -f "$PRD_FILE" ]; then
    CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
    if [ -n "$CURRENT_BRANCH" ]; then
      echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
    fi
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  mkdir -p "$DATA_DIR"
  echo "# Ralph Progress Log ($VARIANT_NAME)" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

cd "$PROJECT_ROOT"
echo "Working directory: $(pwd)"
echo "Variant: $VARIANT_NAME"
echo "Data directory: $DATA_DIR"
echo "Requires git: $REQUIRES_GIT"

# Only check for uncommitted changes if this variant commits code
if [ "$REQUIRES_GIT" = "true" ]; then
  if ! git diff --quiet 2>/dev/null || ! git diff --staged --quiet 2>/dev/null; then
    echo ""
    echo "Warning: You have uncommitted changes."
    echo "   Ralph will commit its changes. Consider stashing yours first."
    read -p "   Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
fi

# ============================================================================
# MAIN LOOP
# ============================================================================

echo ""
echo "Starting Ralph ($VARIANT_NAME) - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "========================================================"
  echo "  $VARIANT_NAME - Iteration $i of $MAX_ITERATIONS"
  echo "========================================================"

  # Run Claude Code with the variant's prompt
  OUTPUT=$(cat "$PROMPT_FILE" | claude -p --dangerously-skip-permissions 2>&1 | tee /dev/stderr) || true

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph ($VARIANT_NAME) completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph ($VARIANT_NAME) reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
