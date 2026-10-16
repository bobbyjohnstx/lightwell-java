#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$PROJECT_DIR/repo"
POM_FILE="$PROJECT_DIR/$APP/pom.xml"
SETTINGS_FILE="$PROJECT_DIR/settings.xml"

echo "=== Version Verification ==="
echo ""

if [[ ! -f "$POM_FILE" ]]; then
    echo "ERROR: $POM_FILE not found."
    exit 1
fi

SETTINGS_ARG=""
PROFILE_ARG=""
if [[ -f "$SETTINGS_FILE" ]]; then
    SETTINGS_ARG="-s $SETTINGS_FILE"
    PROFILE_ARG="-Plightwell"
fi

echo "  \$ mvn dependency:tree -f $APP/pom.xml"
echo ""

TREE=$(mvn -f "$POM_FILE" dependency:tree -Dmaven.repo.local="$REPO_DIR" $SETTINGS_ARG $PROFILE_ARG 2>/dev/null | grep -E '^\[INFO\] [|+\\]' || true)

FOUND_RHLW=false

while IFS= read -r line; do
    # Extract artifact coordinates from dependency:tree output
    artifact=$(echo "$line" | grep -oE '[a-z].*:.*:.*:.*' || true)
    [[ -z "$artifact" ]] && continue

    if [[ "$artifact" == *".rhlw-"* ]]; then
        echo "  ✓ $artifact  [PATCHED by Lightwell]"
        FOUND_RHLW=true
    else
        echo "  ✗ $artifact  [unpatched]"
    fi
done <<< "$TREE"

echo ""
if $FOUND_RHLW; then
    echo "Lightwell remediation confirmed — patched versions detected."
else
    echo "WARNING: No .rhlw-0000X versions found."
    echo "Check that 'make remediate' was run and settings.xml is configured."
fi
