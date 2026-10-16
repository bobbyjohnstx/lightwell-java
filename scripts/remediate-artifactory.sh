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

# JFrog Cloud instance (Maven repos proxy cleanly — no Pulp issue like Python)
JFROG_INSTANCE="${JFROG_INSTANCE:-your-instance}"
JFROG_REPO="${JFROG_REPO:-lightwell-java-remediated}"
JFROG_URL="https://${JFROG_INSTANCE}.jfrog.io/artifactory/${JFROG_REPO}"

if [[ ! -f "$POM_FILE" ]]; then
    echo "ERROR: $POM_FILE not found."
    exit 1
fi

if ! grep -q "${JFROG_INSTANCE}.jfrog.io" ~/.netrc 2>/dev/null; then
    echo "ERROR: No JFrog credentials found in ~/.netrc"
    echo "Add: machine ${JFROG_INSTANCE}.jfrog.io login <email> password <token>"
    exit 1
fi

# Read JFrog credentials from ~/.netrc
JFROG_USER=$(grep "${JFROG_INSTANCE}.jfrog.io" ~/.netrc 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="login") print $(i+1)}')
JFROG_TOKEN=$(grep "${JFROG_INSTANCE}.jfrog.io" ~/.netrc 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="password") print $(i+1)}')

echo "=== Lightwell Remediation (via Artifactory) ==="
echo ""
echo "Artifactory: https://${JFROG_INSTANCE}.jfrog.io"
echo "Repository:  ${JFROG_REPO}"
echo "Proxying:    Red Hat Lightwell Network (Remediated)"
echo ""

# Save original pom.xml
cp "$POM_FILE" "${POM_FILE}.orig"

# Generate settings.xml with JFrog Artifactory as the Lightwell source
(umask 077 && cat > "$PROJECT_DIR/settings.xml" << SETTINGS_EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings>
  <servers>
    <server>
      <id>lightwell-artifactory</id>
      <username>$JFROG_USER</username>
      <password>$JFROG_TOKEN</password>
    </server>
  </servers>
  <profiles>
    <profile>
      <id>lightwell</id>
      <repositories>
        <repository>
          <id>lightwell-artifactory</id>
          <url>$JFROG_URL</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>false</enabled></snapshots>
        </repository>
        <repository>
          <id>central</id>
          <url>https://repo.maven.apache.org/maven2</url>
        </repository>
      </repositories>
    </profile>
  </profiles>
</settings>
SETTINGS_EOF
)

# Use the same remediation logic as direct — query metadata, update pom
"$SCRIPT_DIR/remediate.sh" "$APP"

echo ""
echo "In production, Artifactory caches these JARs locally —"
echo "subsequent builds don't hit the internet."
