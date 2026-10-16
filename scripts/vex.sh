#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$PROJECT_DIR/repo"
POM_FILE="$PROJECT_DIR/$APP/pom.xml"
OSV_BASE_URL="https://packages.redhat.com/lightwell/osv/java/remediated"

echo "=== Lightwell VEX / OSV Vulnerability Data ==="
echo ""
echo "Source: $OSV_BASE_URL"
echo ""

# Get direct dependency artifact IDs from pom.xml
ARTIFACTS=$(grep -A1 '<artifactId>' "$POM_FILE" | grep -oE '>([^<]+)<' | sed 's/[><]//g' | grep -v 'spring-boot\|exec-maven\|lightwell' || true)

# Fetch the OSV index
INDEX=$(curl -sL --netrc "$OSV_BASE_URL/" 2>/dev/null)

if [[ -z "$INDEX" ]]; then
    echo "ERROR: Could not fetch OSV index."
    exit 1
fi

JSON_FILES=$(echo "$INDEX" | grep -oE 'x_RHLW-CVE-[^"]+\.json' | sort -u)
TOTAL=$(echo "$JSON_FILES" | wc -l | tr -d ' ')

echo "Found $TOTAL total CVE records in Java remediated catalog."
echo ""
echo "Showing records relevant to this project's dependencies:"
echo ""

SHOWN=0
for json_file in $JSON_FILES; do
    DATA=$(curl -sL --netrc "$OSV_BASE_URL/$json_file" 2>/dev/null)

    pkg=$(echo "$DATA" | python3 -c "import sys,json; a=json.load(sys.stdin).get('affected',[]); print(a[0]['package']['name'] if a else '')" 2>/dev/null || true)

    # Filter to only show CVEs for our project's dependencies
    MATCH=false
    for art in $ARTIFACTS; do
        if [[ "$pkg" == *"$art"* ]]; then
            MATCH=true
            break
        fi
    done
    $MATCH || continue

    id=$(echo "$DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
    summary=$(echo "$DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('summary',''))" 2>/dev/null)
    severity=$(echo "$DATA" | python3 -c "import sys,json; s=json.load(sys.stdin).get('severity',[]); print(s[0].get('score','N/A') if s else 'N/A')" 2>/dev/null)
    fixed=$(echo "$DATA" | python3 -c "import sys,json; a=json.load(sys.stdin).get('affected',[]); r=a[0].get('ranges',[{}]) if a else [{}]; e=r[0].get('events',[]) if r else []; print(next((x['fixed'] for x in e if 'fixed' in x),'N/A'))" 2>/dev/null)
    aliases=$(echo "$DATA" | python3 -c "import sys,json; print(', '.join(json.load(sys.stdin).get('aliases',[])))" 2>/dev/null)

    echo "  $id"
    echo "    Package: $pkg"
    echo "    Fixed in: $fixed"
    echo "    Severity: $severity"
    echo "    Aliases: $aliases"
    echo "    Summary: $summary"
    echo ""
    SHOWN=$((SHOWN + 1))
done

echo "---"
echo "Showed $SHOWN CVE records relevant to this project (of $TOTAL total)."
echo ""
echo "This VEX data proves Lightwell has remediated these CVEs."
echo "During the 14-day embargo period, scanners may still flag these"
echo "vulnerabilities — this data is the authoritative record."
