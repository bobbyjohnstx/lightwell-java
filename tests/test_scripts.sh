#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PASS=0
FAIL=0

pass() { echo "  PASS  $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL + 1)); }

echo "=== Script Smoke Tests ==="
echo ""

for script in "$PROJECT_DIR"/scripts/*.sh; do
    name=$(basename "$script")
    [[ -x "$script" ]] && pass "$name is executable" || fail "$name is executable"
    head -1 "$script" | grep -q "^#!" && pass "$name has shebang" || fail "$name has shebang"
    grep -q "set -euo pipefail" "$script" && pass "$name uses strict mode" || fail "$name uses strict mode"
done

grep -q "\.env" "$PROJECT_DIR/.gitignore" && pass ".gitignore covers .env" || fail ".gitignore covers .env"
grep -q "\.netrc" "$PROJECT_DIR/.gitignore" && pass ".gitignore covers .netrc" || fail ".gitignore covers .netrc"
grep -q "settings.xml" "$PROJECT_DIR/.gitignore" && pass ".gitignore covers settings.xml" || fail ".gitignore covers settings.xml"
grep -q "repo/" "$PROJECT_DIR/.gitignore" && pass ".gitignore covers repo/" || fail ".gitignore covers repo/"
! grep -q "eyJ" "$PROJECT_DIR/settings.xml.example" && pass "settings.xml.example has no real tokens" || fail "settings.xml.example has no real tokens"
[[ -f "$PROJECT_DIR/minimal/pom.xml" ]] && pass "minimal/pom.xml exists" || fail "minimal/pom.xml exists"
[[ -f "$PROJECT_DIR/chatbot/pom.xml" ]] && pass "chatbot/pom.xml exists" || fail "chatbot/pom.xml exists"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
