#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$PROJECT_DIR/repo"
POM_FILE="$PROJECT_DIR/$APP/pom.xml"
SETTINGS_FILE="$PROJECT_DIR/settings.xml"
LIGHTWELL_BASE="https://packages.redhat.com/lightwell/java/remediated"

if [[ ! -f "$POM_FILE" ]]; then
    echo "ERROR: $POM_FILE not found."
    exit 1
fi

if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "ERROR: settings.xml not found. Run 'make setup' first."
    exit 1
fi

echo "=== Lightwell Remediation ==="
echo ""
echo "Checking Lightwell catalog for patched versions..."
echo "Repository: $LIGHTWELL_BASE"
echo ""

# Save original pom.xml for reset
cp "$POM_FILE" "${POM_FILE}.orig"

# Extract dependencies and check for .rhlw- versions
echo "  \$ mvn dependency:list -f $APP/pom.xml"
DEPS=$(mvn -f "$POM_FILE" dependency:list -Dmaven.repo.local="$REPO_DIR" 2>/dev/null \
    | grep -E '\[INFO\].*:jar:.*:compile' | sed 's/.*\[INFO\]//' | sed 's/^ *//' | sed 's/ -- .*//' || true)

echo ""
while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue

    GROUP=$(echo "$dep" | cut -d: -f1)
    ARTIFACT=$(echo "$dep" | cut -d: -f2)
    VERSION=$(echo "$dep" | cut -d: -f4)
    GROUP_PATH=$(echo "$GROUP" | tr '.' '/')

    # Check Lightwell repo for .rhlw- versions of this artifact
    METADATA_URL="$LIGHTWELL_BASE/$GROUP_PATH/$ARTIFACT/maven-metadata.xml"
    echo "  \$ curl $LIGHTWELL_BASE/.../$ARTIFACT/maven-metadata.xml"
    METADATA=$(curl -sL --netrc "$METADATA_URL" 2>/dev/null || true)

    if [[ -z "$METADATA" ]] || echo "$METADATA" | grep -q "Not Found"; then
        echo "  - $GROUP:$ARTIFACT:$VERSION — not in Lightwell catalog"
        echo ""
        continue
    fi

    # Find the highest .rhlw- version matching the base version
    RHLW_VERSION=$(echo "$METADATA" | grep -oE "${VERSION}[^<]*rhlw-[0-9]+" | sort -V | tail -1 || true)

    if [[ -z "$RHLW_VERSION" ]]; then
        # Try without exact match — maybe the version format differs slightly
        RHLW_VERSION=$(echo "$METADATA" | grep -oE "<version>[^<]*rhlw[^<]*</version>" | sed 's/<[^>]*>//g' | grep "^${VERSION%%.*}" | sort -V | tail -1 || true)
    fi

    if [[ -n "$RHLW_VERSION" ]]; then
        echo "  ✓ $GROUP:$ARTIFACT:$VERSION → $RHLW_VERSION  [remediated]"
        python3 - "$POM_FILE" "$ARTIFACT" "$VERSION" "$RHLW_VERSION" << 'PYEOF'
import re, sys

pom_file, artifact, version, rhlw_version = sys.argv[1:5]
with open(pom_file, 'r') as f:
    content = f.read()
pattern = rf'(<artifactId>{re.escape(artifact)}</artifactId>\s*<version>){re.escape(version)}(</version>)'
content = re.sub(pattern, rf'\g<1>{rhlw_version}\2', content)
with open(pom_file, 'w') as f:
    f.write(content)
PYEOF
    else
        echo "  - $GROUP:$ARTIFACT:$VERSION — version not matched in Lightwell catalog"
    fi
    echo ""
done <<< "$DEPS"

echo "Re-resolving dependencies with updated versions..."
echo "  \$ mvn dependency:resolve -Plightwell -U -s settings.xml"
mvn -f "$POM_FILE" dependency:resolve -U \
    -s "$SETTINGS_FILE" \
    -Dmaven.repo.local="$REPO_DIR" \
    -Plightwell -q

echo ""
echo "Remediation complete."
echo "Run 'make verify' to confirm patched versions."
