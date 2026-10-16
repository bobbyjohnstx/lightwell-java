#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$PROJECT_DIR/repo"
POM_FILE="$PROJECT_DIR/$APP/pom.xml"

if [[ ! -f "$POM_FILE" ]]; then
    echo "ERROR: $POM_FILE not found. Choose 'minimal' or 'chatbot'."
    exit 1
fi

echo "=== Lightwell Java Demo Setup ==="
echo "App: $APP"
echo ""

# Generate settings.xml from ~/.netrc credentials
LIGHTWELL_USER=$(grep 'packages.redhat.com' ~/.netrc 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="login") print $(i+1)}')
LIGHTWELL_TOKEN=$(grep 'packages.redhat.com' ~/.netrc 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="password") print $(i+1)}')

if [[ -n "$LIGHTWELL_USER" && -n "$LIGHTWELL_TOKEN" ]]; then
    echo "Generating settings.xml from ~/.netrc credentials..."
    echo "  \$ cat > settings.xml  (with Lightwell server + profile)"
    (umask 077 && cat > "$PROJECT_DIR/settings.xml" << SETTINGS_EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings>
  <servers>
    <server>
      <id>lightwell-remediated</id>
      <username>$LIGHTWELL_USER</username>
      <password>$LIGHTWELL_TOKEN</password>
    </server>
  </servers>
  <profiles>
    <profile>
      <id>lightwell</id>
      <repositories>
        <repository>
          <id>lightwell-remediated</id>
          <url>https://packages.redhat.com/lightwell/java/remediated</url>
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
    echo "  Generated settings.xml with Lightwell credentials (600 permissions)."
else
    echo "WARNING: No Lightwell credentials found in ~/.netrc"
    echo "Remediation will not work until credentials are configured."
fi

echo ""
echo "Resolving dependencies from Maven Central..."
echo "  \$ mvn dependency:resolve -f $APP/pom.xml"
mvn -f "$POM_FILE" dependency:resolve -Dmaven.repo.local="$REPO_DIR" -q

echo ""
echo "Setup complete. Dependencies resolved from Maven Central (unpatched)."
echo "Run 'make scan' to check for vulnerabilities."
