# Lightwell Java Demo

Customer-facing demo showing how Red Hat Lightwell Network patches vulnerable Java/Maven dependencies with zero application code changes. Build from Maven Central, scan for CVEs, switch to Lightwell, rescan clean.

## Prerequisites

- Java 17+ (tested with OpenJDK 26)
- Maven 3.9+
- `~/.netrc` with Lightwell service account credentials:
  ```
  machine packages.redhat.com login <service-account-username> password <service-account-token>
  ```
  Create a service account at [Red Hat Registry Service Account Management](https://access.redhat.com/terms-based-registry/).
- A vulnerability scanner (at least one):
  - `grype` — `brew install grype` (free, recommended for demos)
  - Black Duck — set `BLACKDUCK_API_TOKEN` in `.env` (see `.env.example`)
  - OWASP dependency-check — requires `NVD_API_KEY` in `.env`

## Quick Start

```bash
make setup                 # Resolve vulnerable deps from Maven Central
make scan                  # Find CVEs (15 vulnerabilities)
make remediate             # Patch via Lightwell (zero code changes)
make scan                  # Rescan — CVEs reduced
make verify                # Confirm .rhlw-0000X version suffixes
make reset                 # Snap back to vulnerable state for next demo
```

## Pre-Demo Check

Run `make doctor` before any demo to verify your environment:

```
=== Lightwell Java Demo — Environment Check ===

Runtime:
  ✓  Java 26.0.2.1 (17+ required)
  ✓  Maven 3.9.16

Credentials:
  ✓  ~/.netrc exists (permissions 600)
  ✓  Lightwell credentials found in ~/.netrc
  ✓  Lightwell auth verified (HTTP 200)
  ✓  JFrog credentials found in ~/.netrc
  ✓  JFrog auth verified (HTTP 200)

Maven:
  ✓  settings.xml exists (permissions 600)

Scanners:
  ✓  Grype installed

Project:
  ✓  Local Maven repository exists
  ✓  minimal/pom.xml exists
  ✓  chatbot/pom.xml exists
  ✓  settings.xml.example exists

Lightwell catalog:
  ✓  Java Remediated catalog accessible (jackson-databind: 14 remediated versions)
  ✓  Java OSV/VEX data accessible (272 CVE records)
```

Checks performed:
- **Runtime** — Java 17+ (detected via Maven to handle macOS stub) and Maven 3.9+
- **Credentials** — `~/.netrc` exists with correct permissions (600), contains entries for `packages.redhat.com` and JFrog. Tests actual authentication against both APIs — catches expired or revoked tokens before you're in front of a customer.
- **Maven** — `settings.xml` generated with owner-only permissions (600), not world-readable
- **Scanners** — Grype available, NVD API key for OWASP dependency-check (optional), Black Duck `.env` token (optional)
- **Project** — local Maven repo, pom.xml files, and settings.xml.example all present
- **Catalog** — live connectivity to the Lightwell Java Remediated repository (counts jackson-databind versions) and OSV/VEX endpoint (counts CVE records)

Items are flagged as pass (✓), warning (⚠ optional feature unavailable), or failure (✗ demo will not work).

## Demo Apps

**Minimal** (`minimal/`) — single Java class using Jackson (JSON) and SnakeYAML. For quick testing.

**Chatbot** (`chatbot/`) — Spring Boot web app with a mocked customer service chatbot UI. Professional look for customer demos. Runs on port 8080. Note: `make run` requires `make remediate` first (jackson-databind 2.11.3 is too old for Spring Boot 3.x auto-configuration).

**Demo Dashboard** (`demo.html`) — Red Hat branded interactive walkthrough. 8 narrated steps covering the full supply chain security story: 17 CVEs across 4 libraries, remediation, SBOM, provenance, VEX, and architecture. Designed for half-screen use alongside a live terminal.

```bash
make setup APP=minimal     # Use minimal app
make setup APP=chatbot     # Use chatbot app (default)
make demo                  # Launch demo dashboard at http://localhost:8001/demo.html
make remediate             # Required before make run (fixes Spring Boot compatibility)
make run                   # Launch chatbot at http://localhost:8080
```

### Presenting the Demo

Run `make demo` to serve the dashboard, then open:
- `http://localhost:8001/demo.html` — the narrated dashboard (left half of screen)

In the terminal (right half of screen), run the `make` commands as you click through each dashboard step. The dashboard provides the narrative context; the terminal shows the live proof.

Navigate the dashboard with the numbered step dots, arrow keys, or the Next/Back buttons.

## All Targets

```bash
make help                  # Show all available targets
make setup                 # Resolve vulnerable deps from Maven Central
make scan                  # Vulnerability scan (Grype / Black Duck / OWASP)
make remediate             # Patch via Lightwell direct
make remediate-jfrog       # Patch via JFrog Artifactory proxy
make verify                # Show dependency tree, confirm .rhlw suffixes
make reset                 # Reset to unpatched state
make demo                  # Serve demo dashboard at http://localhost:8001/demo.html
make run                   # Start Spring Boot chatbot (port 8080, requires make remediate first)
make run-minimal           # Run minimal Jackson/SnakeYAML app
make sbom                  # Extract SBOM from remediated JARs
make provenance            # Show SLSA L3 build provenance info
make vex                   # Show VEX/OSV vulnerability remediation data
make lens                  # Open Lightwell Lens dashboard in browser
make test                  # Run unit tests
make test-integration      # Run full demo cycle against live Lightwell API
```

## How It Works

1. **Setup** resolves pinned vulnerable versions from Maven Central into a project-local repository (`./repo/`). Also generates `settings.xml` with Lightwell credentials from `~/.netrc`.
2. **Scan** finds known CVEs using whichever scanner is available.
3. **Remediate** queries the Lightwell catalog for each dependency, finds patched `.rhlw-` versions, updates the `pom.xml`, and re-resolves from Lightwell. Versions show a `.rhlw-0000X` suffix (e.g., `2.11.3.rhlw-00004` means 4 cumulative security patches on version 2.11.3).
4. **Rescan** shows CVEs resolved for remediated packages.
5. **Verify** shows the dependency tree with `.rhlw-` suffixes confirming patched versions.
6. **Reset** restores the original `pom.xml`, deletes the local repo, and re-resolves from Maven Central.

No application code changes at any step. The remediation updates dependency versions in `pom.xml` — the same change a developer would make, automated by Lightwell.

## Target Libraries

| Library | Vulnerable Version | Remediated | CVE |
|---|---|---|---|
| jackson-databind | 2.11.3 | 2.11.3.rhlw-00004 | CVE-2020-36518 — deeply nested JSON DoS |
| snakeyaml | 1.33 | 1.33.0.rhlw-00001 | CVE-2022-1471 — arbitrary code execution |
| httpclient | 4.5.6 | 4.5.6.rhlw-00001 | CVE-2020-13956 — malformed URI handling |
| gson | 2.8.6 | 2.8.6.rhlw-00002 | CVE-2022-25647 — unsafe deserialization |

## VEX / OSV Data

The Lightwell Java Remediated catalog has 522 CVE records. `make vex` fetches the full OSV dataset and filters to show only CVEs relevant to this project's dependencies. This data proves which specific CVEs are fixed in each `.rhlw-` version — important during the 14-day embargo period when scanners may not yet recognize Lightwell-patched versions.

## JFrog Artifactory Integration

`make remediate-jfrog` patches through a JFrog Artifactory instance. Maven repos proxy cleanly through Artifactory (unlike Python/Pulp which has URL rewriting issues).

Requires JFrog credentials in `~/.netrc`:
```
machine <instance>.jfrog.io login <email> password <identity-token>
```

## Credentials

All credentials live outside the repository:

| Credential | Location | Purpose |
|---|---|---|
| Lightwell service account | `~/.netrc` | Authenticate to `packages.redhat.com` |
| JFrog identity token | `~/.netrc` | Authenticate to JFrog Artifactory (optional) |
| Black Duck API token | `.env` (gitignored) | Authenticate to Black Duck scanner (optional) |
| NVD API key | `.env` (gitignored) | OWASP dependency-check NVD access (optional) |

`setup.sh` reads `~/.netrc` and generates `settings.xml` (gitignored, 600 permissions) with Maven server credentials. Copy `.env.example` to `.env` for scanner tokens. Never commit `.env`, `~/.netrc`, or `settings.xml`.

## Project-Local Maven Repository

All Maven dependencies resolve into `./repo/` (not `~/.m2/repository`) to keep demo state isolated. The `repo/` directory is gitignored and recreated on each `make reset`.

## Companion Project

[lightwell-python](https://github.com/bobbyjohnstx/lightwell-python) — same demo flow for Python/pip. The Python Remediated catalog is smaller but growing. Both projects share the same chatbot UI, Makefile structure, and Lightwell service account.
