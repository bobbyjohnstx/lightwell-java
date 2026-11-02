# Lightwell Java Demo — Known Gaps

Items that would strengthen the demo but are not yet implemented. Organized by audience impact.

## High Impact

### CI/CD Integration Example
Every platform engineer asks "how does this go in my pipeline?" No Jenkins/GitHub Actions/GitLab CI example exists. A `.github/workflows/lightwell-scan.yml` or a Jenkinsfile snippet showing setup → remediate → scan → verify would answer the question before it's asked.

### ROI / Time-Savings Framing
CISOs buy on cost and risk, not technology. The demo shows *what* Lightwell does but not *why it matters financially*. Missing: time-to-patch comparison (manual upgrade vs. Lightwell), developer hours saved per CVE remediation cycle, risk quantification for delayed patching.

### Competitive Positioning in Dashboard
`docs/demo-script.md` has competitive counters (Chainguard, BlackDuck, "we'll do it ourselves") but the dashboard has no visual comparison. A slide or panel showing Lightwell vs. manual upgrade vs. Chainguard would make the differentiation concrete.

## Medium Impact

### Transitive Dependency Story
The demo only remediates direct dependencies. Spring Boot pulls in dozens of transitives. The audience will ask: "Does Lightwell patch transitive deps too?" If yes, show it. If no, explain the roadmap.

### Rollback Story
`make reset` restores the demo, but there's no production rollback narrative. What happens if a `.rhlw` patch causes a regression? Talking points needed: version pinning, Artifactory caching, Maven dependency locking.

### Offline / Air-Gapped Demo Mode
Conference and FSI demos often lack reliable internet. The scan, remediate, and VEX steps all require network access. A `make demo-offline` mode that uses pre-cached data would eliminate this risk. Fonts are now bundled locally (no Google CDN dependency).

### End-to-End Dry Run Validation
No mechanism to validate the full demo path matches dashboard expectations before the audience sees it. A `make demo-check` that runs setup → scan → remediate → scan → vex and compares output to expected values would catch drift.

### "What Changed" Transparency
A skeptical engineer will ask "what bytecode changed in the JAR?" No diff or comparison is offered. Showing a `diff` of the Maven dependency tree before/after, or a JAR contents comparison, would build trust.

## Lower Impact

### Scale Narrative
"32,000+ Libraries" (dashboard Step 8) has no citation or demo proof. No story about how Lightwell works across a 200-microservice organization. The number will go stale as the catalog grows.

### Regression Guarantee Clarification
Dashboard Step 3 says "No regression testing needed." Is this a contractual guarantee or a design goal? A skeptical CISO will press this point. The demo script should have a prepared answer: "API-compatible backports — same method signatures, same behavior. Red Hat tests compatibility. Your integration tests still pass."

### Multi-Language Story
The sibling `lightwell-python` project exists but the dashboard doesn't mention it. Showing Java + Python side-by-side in the architecture step would reinforce "this works across your stack."

---

*Last updated: 2026-10-30. Review before each demo cycle — gaps may have been addressed.*
