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

ARTIFACTS=$(grep -A1 '<artifactId>' "$POM_FILE" | grep -oE '>([^<]+)<' | sed 's/[><]//g' | grep -v 'spring-boot\|exec-maven\|lightwell' || true)

echo "Fetching OSV index..."
INDEX=$(curl -sL --netrc "$OSV_BASE_URL/" 2>/dev/null)

if [[ -z "$INDEX" ]]; then
    echo "ERROR: Could not fetch OSV index."
    exit 1
fi

JSON_FILES=$(echo "$INDEX" | grep -oE 'x_RHLW-CVE-[^"]+\.json' | sort -u)
TOTAL=$(echo "$JSON_FILES" | wc -l | tr -d ' ')

echo "Found $TOTAL total CVE records in Java remediated catalog."
echo ""

# Bulk-fetch all JSON files in parallel to a temp directory
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading CVE records (parallel)..."
echo "$JSON_FILES" | xargs -P 20 -I{} \
    curl -sL --netrc -o "$TMPDIR/{}" "$OSV_BASE_URL/{}" 2>/dev/null

echo "Filtering to this project's dependencies..."
echo ""

# Process all downloaded files locally with a single python3 invocation
python3 - "$TMPDIR" $ARTIFACTS << 'PYEOF'
import json, os, sys, glob

tmpdir = sys.argv[1]
artifacts = sys.argv[2:]
shown = 0

for f in sorted(glob.glob(os.path.join(tmpdir, "*.json"))):
    try:
        with open(f) as fh:
            data = json.load(fh)
    except (json.JSONDecodeError, IOError):
        continue

    affected = data.get("affected", [])
    if not affected:
        continue

    pkg = affected[0].get("package", {}).get("name", "")
    if not any(a in pkg for a in artifacts):
        continue

    vid = data.get("id", "")
    summary = data.get("summary", "")
    severity = data.get("severity", [])
    score = severity[0].get("score", "N/A") if severity else "N/A"

    ranges = affected[0].get("ranges", [{}])
    events = ranges[0].get("events", []) if ranges else []
    fixed = next((x["fixed"] for x in events if "fixed" in x), "N/A")

    aliases = ", ".join(data.get("aliases", []))

    print(f"  {vid}")
    print(f"    Package: {pkg}")
    print(f"    Fixed in: {fixed}")
    print(f"    Severity: {score}")
    print(f"    Aliases: {aliases}")
    print(f"    Summary: {summary}")
    print()
    shown += 1

print("---")
print(f"Showed {shown} CVE records relevant to this project (of {len(glob.glob(os.path.join(tmpdir, '*.json')))} total).")
PYEOF

echo ""
echo "This VEX data proves Lightwell has remediated these CVEs."
echo "During the 14-day embargo period, scanners may still flag these"
echo "vulnerabilities — this data is the authoritative record."
