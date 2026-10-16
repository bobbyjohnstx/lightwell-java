#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0
WARN=0
FAIL=0

pass() { echo "  ✓  $1"; PASS=$((PASS + 1)); }
warn() { echo "  ⚠  $1"; WARN=$((WARN + 1)); }
fail() { echo "  ✗  $1"; FAIL=$((FAIL + 1)); }

echo "=== Lightwell Java Demo — Environment Check ==="
echo ""

# --- Runtime ---
echo "Runtime:"

# Try Maven first (most reliable — works even when macOS java stub intercepts)
if command -v mvn &>/dev/null; then
    JAVA_VERSION=$(mvn --version 2>&1 | grep "Java version" | sed 's/.*Java version: //' | cut -d',' -f1)
    JAVA_MAJOR=$(echo "$JAVA_VERSION" | cut -d. -f1)
    if [[ -n "$JAVA_MAJOR" && "$JAVA_MAJOR" -ge 17 ]]; then
        pass "Java $JAVA_VERSION (17+ required)"
    elif [[ -n "$JAVA_MAJOR" ]]; then
        fail "Java $JAVA_VERSION — need 17+"
    else
        fail "Java not found (Maven could not detect JDK)"
    fi
else
    fail "Java and Maven not found"
fi

if command -v mvn &>/dev/null; then
    MVN_VERSION=$(mvn --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    pass "Maven $MVN_VERSION"
else
    fail "Maven not found — brew install maven"
fi

# --- Credentials ---
echo ""
echo "Credentials:"

if [[ -f ~/.netrc ]]; then
    NETRC_PERMS=$(stat -f "%Lp" ~/.netrc 2>/dev/null || stat -c "%a" ~/.netrc 2>/dev/null)
    if [[ "$NETRC_PERMS" == "600" ]]; then
        pass "~/.netrc exists (permissions 600)"
    else
        warn "~/.netrc exists but permissions are $NETRC_PERMS (should be 600)"
    fi
else
    fail "~/.netrc not found — Lightwell auth will not work"
fi

if grep -q "packages.redhat.com" ~/.netrc 2>/dev/null; then
    pass "Lightwell credentials found in ~/.netrc"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --netrc --connect-timeout 5 \
        "https://packages.redhat.com/lightwell/java/remediated/" 2>/dev/null)
    if [[ "$HTTP_CODE" == "200" ]]; then
        pass "Lightwell auth verified (HTTP 200)"
    elif [[ "$HTTP_CODE" == "301" ]]; then
        pass "Lightwell auth verified (HTTP 301 redirect — expected)"
    elif [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" ]]; then
        fail "Lightwell auth failed (HTTP $HTTP_CODE) — token may be expired or revoked"
    elif [[ "$HTTP_CODE" == "000" ]]; then
        warn "Lightwell server unreachable — check network"
    else
        warn "Lightwell returned HTTP $HTTP_CODE — unexpected"
    fi
else
    fail "No packages.redhat.com entry in ~/.netrc"
fi

JFROG_INSTANCE="${JFROG_INSTANCE:-your-instance}"
if grep -q "${JFROG_INSTANCE}.jfrog.io\|jfrog.io" ~/.netrc 2>/dev/null; then
    JFROG_HOST=$(grep "jfrog.io" ~/.netrc 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="machine") print $(i+1)}' | head -1)
    pass "JFrog credentials found in ~/.netrc ($JFROG_HOST)"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --netrc --connect-timeout 5 \
        "https://$JFROG_HOST/artifactory/api/system/ping" 2>/dev/null)
    if [[ "$HTTP_CODE" == "200" ]]; then
        pass "JFrog auth verified (HTTP 200)"
    elif [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" ]]; then
        fail "JFrog auth failed (HTTP $HTTP_CODE) — token may be expired"
    elif [[ "$HTTP_CODE" == "000" ]]; then
        warn "JFrog server unreachable"
    else
        warn "JFrog returned HTTP $HTTP_CODE"
    fi
else
    warn "No JFrog credentials in ~/.netrc (make remediate-jfrog will not work)"
fi

if [[ -f "$PROJECT_DIR/.env" ]]; then
    if grep -q "BLACKDUCK_API_TOKEN=.\+" "$PROJECT_DIR/.env" 2>/dev/null; then
        pass "Black Duck token found in .env"
    else
        warn "Black Duck token not set in .env (Black Duck scanning unavailable)"
    fi
else
    warn "No .env file (Black Duck scanning unavailable — see .env.example)"
fi

# --- Maven settings ---
echo ""
echo "Maven:"

if [[ -f "$PROJECT_DIR/settings.xml" ]]; then
    SETTINGS_PERMS=$(stat -f "%Lp" "$PROJECT_DIR/settings.xml" 2>/dev/null || stat -c "%a" "$PROJECT_DIR/settings.xml" 2>/dev/null)
    if [[ "$SETTINGS_PERMS" == "600" ]]; then
        pass "settings.xml exists (permissions 600)"
    else
        warn "settings.xml exists but permissions are $SETTINGS_PERMS (should be 600)"
    fi
else
    warn "settings.xml not generated yet — run: make setup"
fi

# --- Scanners ---
echo ""
echo "Scanners:"

if command -v grype &>/dev/null; then
    pass "Grype installed ($(grype --version 2>&1 | head -1))"
else
    warn "Grype not installed — run: brew install grype"
fi

if [[ -n "${NVD_API_KEY:-}" ]] || (grep -q "NVD_API_KEY=.\+" "$PROJECT_DIR/.env" 2>/dev/null); then
    pass "NVD API key available (OWASP dependency-check will work)"
else
    warn "No NVD API key (OWASP dependency-check unavailable — Grype recommended instead)"
fi

# --- Project state ---
echo ""
echo "Project:"

if [[ -d "$PROJECT_DIR/repo" ]]; then
    pass "Local Maven repository exists"
else
    warn "No local repo — run: make setup"
fi

for pom in minimal/pom.xml chatbot/pom.xml; do
    if [[ -f "$PROJECT_DIR/$pom" ]]; then
        pass "$pom exists"
    else
        fail "$pom missing"
    fi
done

if [[ -f "$PROJECT_DIR/settings.xml.example" ]]; then
    pass "settings.xml.example exists"
else
    fail "settings.xml.example missing"
fi

# --- Lightwell catalog ---
echo ""
echo "Lightwell catalog:"

METADATA=$(curl -sL --netrc --connect-timeout 5 \
    "https://packages.redhat.com/lightwell/java/remediated/com/fasterxml/jackson/core/jackson-databind/maven-metadata.xml" 2>/dev/null)
if echo "$METADATA" | grep -q "rhlw"; then
    VERSIONS=$(echo "$METADATA" | grep -oE 'rhlw-[0-9]+' | wc -l | tr -d ' ')
    pass "Java Remediated catalog accessible (jackson-databind: $VERSIONS remediated versions)"
else
    warn "Could not fetch Java Remediated catalog"
fi

OSV_COUNT=$(curl -sL --netrc --connect-timeout 5 \
    "https://packages.redhat.com/lightwell/osv/java/remediated/" 2>/dev/null \
    | grep -c "\.json" || echo "0")
if [[ "$OSV_COUNT" -gt 0 ]]; then
    pass "Java OSV/VEX data accessible ($OSV_COUNT CVE records)"
else
    warn "Could not fetch Java OSV data"
fi

# --- Summary ---
echo ""
echo "=============================="
if [[ $FAIL -eq 0 && $WARN -eq 0 ]]; then
    echo "All checks passed. Ready to demo."
elif [[ $FAIL -eq 0 ]]; then
    echo "$PASS passed, $WARN warnings, $FAIL failures"
    echo "Demo will work but some optional features are unavailable."
else
    echo "$PASS passed, $WARN warnings, $FAIL failures"
    echo "Fix the failures above before running the demo."
fi
