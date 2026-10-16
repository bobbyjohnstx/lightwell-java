.PHONY: doctor setup scan remediate remediate-jfrog verify reset run run-minimal provenance sbom vex lens test test-integration help

APP ?= chatbot

doctor: ## Check environment, credentials, and connectivity
	@bash scripts/doctor.sh

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Resolve vulnerable deps from Maven Central
	@bash scripts/setup.sh $(APP)

scan: ## Run vulnerability scanner (Black Duck / OWASP / Grype)
	@bash scripts/scan.sh $(APP)

remediate: ## Activate Lightwell profile and re-resolve deps
	@bash scripts/remediate.sh $(APP)

remediate-jfrog: ## Remediate via JFrog Artifactory (proxies Lightwell)
	@bash scripts/remediate-artifactory.sh $(APP)

verify: ## Show dependency tree and confirm .rhlw-0000X patched suffixes
	@bash scripts/verify.sh $(APP)

reset: ## Reset demo to unpatched state (clean local repo, re-resolve)
	@bash scripts/reset.sh $(APP)

provenance: ## Verify SLSA L3 build provenance for remediated packages
	@bash scripts/provenance.sh $(APP)

sbom: ## Extract and display SBOM from remediated packages
	@bash scripts/sbom.sh $(APP)

vex: ## Show VEX/OSV vulnerability data for remediated packages
	@bash scripts/vex.sh $(APP)

lens: ## Open Lightwell Lens in browser
	@echo "Opening Lightwell Lens..."
	@open "https://console.redhat.com/lightwell/lens" 2>/dev/null || \
		xdg-open "https://console.redhat.com/lightwell/lens" 2>/dev/null || \
		echo "Visit: https://console.redhat.com/lightwell/lens"

test: ## Run unit tests
	@mvn -f chatbot/pom.xml test -Dmaven.repo.local=./repo -q
	@bash tests/test_scripts.sh

test-integration: ## Run full demo cycle against live Lightwell API
	@bash tests/test_integration.sh

run: ## Run the Spring Boot chatbot app
	@mvn -f chatbot/pom.xml spring-boot:run -Dmaven.repo.local=./repo -q

run-minimal: ## Run the minimal Jackson/SnakeYAML app
	@mvn -f minimal/pom.xml compile exec:java -Dmaven.repo.local=./repo -q
