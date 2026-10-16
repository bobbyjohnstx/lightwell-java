#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$PROJECT_DIR/repo"
POM_FILE="$PROJECT_DIR/$APP/pom.xml"

echo "=== SBOM Inspection ==="
echo ""

if [[ ! -d "$REPO_DIR" ]]; then
    echo "ERROR: No local repo found. Run 'make setup' first."
    exit 1
fi

FOUND_SBOM=false

# Find .rhlw- JARs in the local repo
while IFS= read -r jar; do
    [[ -z "$jar" ]] && continue

    BASENAME=$(basename "$jar")
    echo "--- $BASENAME ---"

    # Check for embedded SBOM inside the JAR
    SBOM_ENTRY=$(unzip -l "$jar" 2>/dev/null | grep -i "sbom\|spdx\|cyclonedx\|bom.json\|bom.xml" || true)

    if [[ -n "$SBOM_ENTRY" ]]; then
        FOUND_SBOM=true
        echo "  SBOM found inside JAR:"
        echo "$SBOM_ENTRY" | while read -r line; do echo "    $line"; done

        # Extract and display first SBOM file
        SBOM_FILE=$(echo "$SBOM_ENTRY" | awk '{print $NF}' | head -1)
        if [[ -n "$SBOM_FILE" ]]; then
            echo ""
            echo "  \$ unzip -p $BASENAME $SBOM_FILE"
            echo ""
            unzip -p "$jar" "$SBOM_FILE" 2>/dev/null | python3 -m json.tool 2>/dev/null | head -30
            echo "  ..."
        fi
    else
        echo "  No embedded SBOM found in JAR."
        echo "  (Java JARs: SBOMs available via Red Hat support case request)"
    fi
    echo ""
done < <(find "$REPO_DIR" -name "*rhlw*.jar" -not -name "*sources*" -not -name "*javadoc*" 2>/dev/null)

if ! $FOUND_SBOM; then
    echo "No embedded SBOMs found in remediated JARs."
    echo ""
    echo "For Java artifacts, SBOMs are available via:"
    echo "  1. Red Hat support case request"
    echo "  2. Lightwell Lens (console.redhat.com/lightwell/lens)"
    echo "  3. CycloneDX Maven plugin: mvn org.cyclonedx:cyclonedx-maven-plugin:makeBom"
fi
