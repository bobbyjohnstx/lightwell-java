#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$PROJECT_DIR/repo"
POM_FILE="$PROJECT_DIR/$APP/pom.xml"

echo "=== Demo Reset ==="
echo ""

# Restore original pom.xml if backup exists
if [[ -f "${POM_FILE}.orig" ]]; then
    echo "Restoring original pom.xml..."
    mv "${POM_FILE}.orig" "$POM_FILE"
fi

if [[ -d "$REPO_DIR" ]]; then
    echo "Removing project-local Maven repository..."
    rm -rf "$REPO_DIR"
fi

echo "Recreating environment with unpatched dependencies..."
"$SCRIPT_DIR/setup.sh" "$APP"

echo ""
echo "Reset complete. Ready for next demo run."
