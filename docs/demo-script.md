# Lightwell Java Demo — Talking Points & Script

**Format:** 5-minute live demo with talking points
**Audience:** CISO, AppSec leads, Artifactory admins
**Narrative:** "BlackDuck is the detector. Lightwell is the prevention. Together, the scan comes back cleaner and the audit trail is complete."
**Sibling demo:** ../lightwell-python/ — same flow for Python/pip. Show side-by-side for maximum impact.

---

## Three Perceptions (frame every interaction)

1. **Functional in Under 24 Hours** — repository redirect, not platform migration
2. **Self-Sufficient** — no additional scanners or policy engines needed
3. **100% Process Compatible** — backported patches preserve API compatibility; plugs into existing CI/CD

---

## Demo Flow

### Setup (before the audience sees anything)

```bash
make setup APP=chatbot    # or APP=minimal for a quick run
```

### Step 1: Show the App (30 seconds)

```bash
make run
```

> "Here's a typical enterprise Java web application — a customer service chatbot built on Spring Boot. Jackson for JSON, SnakeYAML for config, Apache HttpClient for backend calls. Standard stuff your teams are already running."

Open `http://localhost:8080`, type a message, show it works. Stop with Ctrl+C.

### Step 2: Scan — Find the Problem (60 seconds)

```bash
make scan
```

> "We run a vulnerability scan. Your team probably uses BlackDuck — 4 of our 8 FSI design partners do. Same story regardless of scanner."

**What to point out:**
- jackson-databind 2.11.3: CVE-2020-36518 — deeply nested JSON causes DoS
- snakeyaml 1.33: CVE-2022-1471 — arbitrary code execution via YAML deserialization
- httpclient 4.5.6: CVE-2020-13956 — malformed URI misinterpretation
- gson 2.8.6: CVE-2022-25647 — deserialization of untrusted data
- Plus transitive dependency CVEs from 39 total dependencies

### Step 3: Remediate — Fix Without Code Changes (60 seconds)

```bash
make remediate APP=chatbot
```

> "Watch what happens. The script checks each dependency against the Lightwell catalog — 32,000+ libraries, 150 unique CVEs remediated. It finds patched versions and updates the pom.xml. Same base versions, same API compatibility — just with security patches backported by Red Hat engineers."

**What to point out:**
- jackson-databind → 2.11.3.rhlw-00004 (4 cumulative patches)
- snakeyaml → 1.33.0.rhlw-00001
- httpclient → 4.5.6.rhlw-00001
- gson → 2.8.6.rhlw-00002
- "The .rhlw suffix means Red Hat applied security fixes to YOUR exact version. No upgrade. No breaking changes."

### Step 4: Verify (30 seconds)

```bash
make verify APP=chatbot
```

> "Let's confirm. Every dependency with .rhlw is now running a Lightwell-patched version."

### Step 5: Rescan (60 seconds)

```bash
make scan
```

> "Same scanner, same project, same code. The only thing that changed is WHERE the packages came from."

### Step 6: Show the Proof Chain (90 seconds)

```bash
make vex APP=chatbot
```

> "522 CVE records in the Java catalog alone. Here's the VEX data for our project's specific dependencies — which CVEs were fixed, in which versions, with CVSS scores."

```bash
make sbom APP=chatbot
```

> "And the SBOM — every Lightwell package has an auditable software bill of materials."

### Step 7: Lightwell Lens

```bash
make lens
```

> "For the visual dashboard, Lightwell Lens shows which packages are remediated, which CVEs are resolved, the full provenance chain."

### Reset

```bash
make reset APP=chatbot
```

---

## Alternate Flow: Artifactory Integration

### Step 3 (alt): Remediate via Artifactory

```bash
make remediate-jfrog APP=chatbot
```

> "Same remediation, but now flowing through your Artifactory instance. In production, Artifactory caches these JARs locally — air-gap friendly, faster builds."

**What to point out:**
- Artifactory has `lightwell-java-remediated` as a remote Maven repo
- Maven repos proxy cleanly through Artifactory (unlike Python/Pulp)
- "This is the same pattern your team already uses for Maven Central through Artifactory. Just add Lightwell as another remote source."

---

## Java vs Python — Side-by-Side Demo

If showing both:

| | Python | Java |
|---|---|---|
| Build tool | pip | Maven |
| Catalog size | 2 remediated packages | 261 artifact-version pairs |
| OSV entries | 6 | 522 |
| Version suffix | +rhlw.N | .rhlw-0000X |
| Remediation | pip install from Lightwell | pom.xml version update |
| Artifactory | Pulp proxy issue (workaround needed) | Proxies cleanly |

> "Java is where the catalog depth is today. Python is growing fast — went from zero to 2,000 validated packages. The architecture is identical."

---

## Key Numbers

- **32,000+ libraries** remediated across Java and Python
- **522 Java CVE records** in the OSV database
- **150 unique CVEs** patched in the Java Remediated catalog
- **$5B commitment** from Red Hat + IBM + Palo Alto Networks
- **$925K** Network pricing — flat, all-you-can-eat (going up January 2027)
- **< 24 hours** to get functional (repository redirect)

## Competitive Counters

- **"We use Chainguard"** — "Chainguard says 'move to latest.' We say 'stay where you are, we'll fix it in place.' Their remediated Java library count is ~135. Ours is 32,000+."
- **"BlackDuck already finds everything"** — "Keep using it. We make its scan cleaner."
- **"We'll do this ourselves"** — "Do you have crypto experts on staff? We do. 20,000 Red Hat engineers vs Chainguard's 700."

## If Asked About Spring Framework Versions

> "The remediated catalog has Spring Framework patches for older versions that FSI shops are actually running. We don't ask you to upgrade to Spring 6 — we patch Spring 5.3 in place. That's the whole point."
