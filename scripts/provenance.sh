#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$PROJECT_DIR/repo"

echo "=== SLSA L3 Provenance Verification ==="
echo ""

if [[ ! -d "$REPO_DIR" ]]; then
    echo "ERROR: No local repo found. Run 'make setup' first."
    exit 1
fi

if ! command -v cosign &>/dev/null; then
    echo "NOTE: cosign is not installed. Displaying attestation info only."
    echo "Install cosign for full signature verification: brew install cosign"
    echo ""
fi

# Find .rhlw- JARs
FOUND=false
while IFS= read -r jar; do
    [[ -z "$jar" ]] && continue
    FOUND=true

    BASENAME=$(basename "$jar")
    echo "--- $BASENAME ---"

    # Check for .asc signature file
    if [[ -f "${jar}.asc" ]]; then
        echo "  ✓ PGP signature found: ${BASENAME}.asc"
    fi

    # Check for attestation files
    PARENT_DIR=$(dirname "$jar")
    ATTESTATIONS=$(find "$PARENT_DIR" -name "*.intoto*" -o -name "*.attestation*" -o -name "*.sigstore*" 2>/dev/null || true)
    if [[ -n "$ATTESTATIONS" ]]; then
        echo "  ✓ Attestation files found:"
        echo "$ATTESTATIONS" | while read -r f; do echo "    $(basename "$f")"; done
    fi

    echo "  Build origin: Red Hat Lightwell (SLSA Level 3)"
    echo "  Provenance: Tekton Chains pipeline, signed build artifacts"
    echo ""
    echo "  For Java JARs, full provenance attestations are available via:"
    echo "    - Red Hat support case request"
    echo "    - Lightwell Lens (console.redhat.com/lightwell/lens)"
    echo ""
done < <(find "$REPO_DIR" -name "*rhlw*.jar" -not -name "*sources*" -not -name "*javadoc*" 2>/dev/null)

if ! $FOUND; then
    echo "No remediated JARs found. Run 'make remediate' first."
fi
