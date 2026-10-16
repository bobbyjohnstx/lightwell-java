#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$PROJECT_DIR/repo"
POM_FILE="$PROJECT_DIR/$APP/pom.xml"

if [[ -f "$PROJECT_DIR/.env" ]]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

echo "=== Vulnerability Scan ==="
echo ""

if [[ ! -f "$POM_FILE" ]]; then
    echo "ERROR: $POM_FILE not found."
    exit 1
fi

# Try Black Duck first
if [[ -n "${BLACKDUCK_API_TOKEN:-}" ]]; then
    echo "Scanner: Black Duck (Synopsys Detect)"
    echo ""

    BLACKDUCK_URL="${BLACKDUCK_URL:-https://redhathub.blackducksoftware.com}"

    echo "  \$ bash detect.sh --blackduck.url=$BLACKDUCK_URL"
    bash <(curl -s -L https://detect.blackduck.com/detect.sh) \
        --blackduck.url="$BLACKDUCK_URL" \
        --blackduck.api.token="$BLACKDUCK_API_TOKEN" \
        --blackduck.trust.cert=true
    exit 0
fi

# Try grype
if command -v grype &>/dev/null; then
    echo "Scanner: Grype"
    echo "  \$ grype dir:$APP/"
    echo ""
    grype dir:"$PROJECT_DIR/$APP" --only-fixed || true
    exit 0
fi

# Try OWASP dependency-check via Maven plugin (requires NVD API key)
if [[ -n "${NVD_API_KEY:-}" ]]; then
    echo "Scanner: OWASP Dependency-Check (Maven plugin)"
    echo "  \$ mvn dependency-check:check"
    echo ""
    mvn -f "$POM_FILE" org.owasp:dependency-check-maven:check \
        -Dmaven.repo.local="$REPO_DIR" \
        -DnvdApiKey="$NVD_API_KEY" || true
    exit 0
fi

# Fallback: mvn dependency:tree to at least show what's installed
echo "Scanner: Maven dependency:tree (no vulnerability scanner found)"
echo "  \$ mvn dependency:tree"
echo ""
echo "Showing dependency versions — check manually for CVEs:"
echo ""
mvn -f "$POM_FILE" dependency:tree -Dmaven.repo.local="$REPO_DIR" -q
echo ""
echo "Install a scanner for automated CVE detection:"
echo "  1. Grype      — brew install grype"
echo "  2. Black Duck — set BLACKDUCK_API_TOKEN in .env"
echo "  3. OWASP      — set NVD_API_KEY in .env"
