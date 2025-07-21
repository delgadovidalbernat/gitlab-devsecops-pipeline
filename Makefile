# Variables
IMAGE_NAME := devsecops-tools
IMAGE_TAG := latest
DOCKERHUB_IMAGE := $(DOCKERHUB_USER)/$(IMAGE_NAME)
FULL_IMAGE_NAME := $(DOCKERHUB_IMAGE):$(IMAGE_TAG)

# Docker build arguments
YQ_VERSION := v4.40.5
GITLEAKS_VERSION := 8.28.0
DEPENDENCY_CHECK_VERSION := 9.0.8

CI_COMMIT_SHA ?= local-build
CI_COMMIT_TAG ?= no-tag
CI_REGISTRY_IMAGE ?= $(DOCKERHUB_USER)/$(IMAGE_NAME_BASE)

FINAL_IMAGE_SHA_TAG := $(CI_REGISTRY_IMAGE):$(CI_COMMIT_SHA)
FINAL_IMAGE_LATEST_TAG := $(CI_REGISTRY_IMAGE):$(IMAGE_TAG_DEFAULT)

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

.PHONY: help build test run shell clean push pull info

# Default target
help:
	@echo "GitLab DevSecOps Tools - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make build          # Build the image"
	@echo "  make test           # Test all tools work"
	@echo "  make run            # Run interactive container"
	@echo "  make gitleaks       # Test GitLeaks on current directory"

build:
	@echo "$(GREEN)Building DevSecOps tools image...$(NC)"
	docker build \
		-f docker/Dockerfile \
		--build-arg YQ_VERSION=$(YQ_VERSION) \
		--build-arg GITLEAKS_VERSION=$(GITLEAKS_VERSION) \
		--build-arg DEPENDENCY_CHECK_VERSION=$(DEPENDENCY_CHECK_VERSION) \
		--tag $(FINAL_IMAGE_SHA_TAG) \
		--tag $(FINAL_IMAGE_LATEST_TAG) \
		.
	@echo "$(GREEN)Build completed: $(IMAGE_NAME):$(IMAGE_TAG)$(NC)"

build-no-cache:
	@echo "$(GREEN)Building DevSecOps tools image (no cache)...$(NC)"
	docker build --no-cache \
		--build-arg YQ_VERSION=$(YQ_VERSION) \
		--build-arg GITLEAKS_VERSION=$(GITLEAKS_VERSION) \
		--build-arg DEPENDENCY_CHECK_VERSION=$(DEPENDENCY_CHECK_VERSION) \
		--tag $(IMAGE_NAME):$(IMAGE_TAG) \
		--tag $(IMAGE_NAME):dev \
		docker/
	@echo "$(GREEN)Build completed: $(IMAGE_NAME):$(IMAGE_TAG)$(NC)"

test:
	@echo "$(GREEN)Testing installed tools...$(NC)"
	@docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) /bin/bash -c " \
		echo 'Testing yq...' && yq --version && \
		echo 'Testing jq...' && echo '{\"test\": true}' | jq . && \
		echo 'Testing GitLeaks...' && gitleaks version && \
		echo 'Testing Semgrep...' && semgrep --version && \
		echo 'Testing Dependency Check...' && dependency-check --version && \
		echo '$(GREEN)All tools working correctly!$(NC)'"

run:
	@echo "$(GREEN)Starting interactive container...$(NC)"
	docker run --rm -it \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		/bin/bash

shell: run

gitleaks:
	@echo "$(GREEN)Running GitLeaks on current directory...$(NC)"
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		gitleaks detect --source . --verbose

gitleaks-report:
	@echo "$(GREEN)Running GitLeaks with GitLab format report...$(NC)"
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		gitleaks detect --source . --report-format json --report-path gl-secret-detection-report.json --verbose || true
	@if [ -f gl-secret-detection-report.json ]; then \
		echo "$(GREEN)Report generated: gl-secret-detection-report.json$(NC)"; \
		cat gl-secret-detection-report.json | jq .; \
	fi

semgrep:
	@echo "$(GREEN)Running Semgrep on current directory...$(NC)"
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		semgrep --config=auto .

yq-test:
	@echo "$(GREEN)Testing yq YAML parsing...$(NC)"
	@echo "test:\n  enabled: true\n  value: 42" > test-config.yml
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		/bin/bash -c "yq e '.test.enabled' test-config.yml && yq e '.test.value' test-config.yml"
	@rm -f test-config.yml

clean:
	@echo "$(YELLOW)Cleaning up Docker images and containers...$(NC)"
	-docker rmi $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):dev
	-docker system prune -f
	@echo "$(GREEN)Cleanup completed$(NC)"

push:
	@echo "$(GREEN)Pushing image to dockerhub...$(NC)"
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(FULL_IMAGE_NAME)
	docker push $(FULL_IMAGE_NAME)
	@echo "$(GREEN)Image pushed: $(FULL_IMAGE_NAME)$(NC)"
	@echo "$(YELLOW)Available at: https://hub.docker.com/r/$(DOCKERHUB_USER)/$(IMAGE_NAME)$(NC)"

pull:
	@echo "$(GREEN)Pulling image from dockerhub...$(NC)"
	docker pull $(FULL_IMAGE_NAME)
	docker tag $(FULL_IMAGE_NAME) $(IMAGE_NAME):$(IMAGE_TAG)
	@echo "$(GREEN)Image pulled: $(FULL_IMAGE_NAME)$(NC)"

info:
	@echo "$(GREEN)Image Information:$(NC)"
	@echo "  Name: $(IMAGE_NAME):$(IMAGE_TAG)"
	@echo "  Dockerhub: $(FULL_IMAGE_NAME)"
	@echo "  Build args:"
	@echo "    YQ_VERSION: $(YQ_VERSION)"
	@echo "    GITLEAKS_VERSION: $(GITLEAKS_VERSION)"
	@echo "    DEPENDENCY_CHECK_VERSION: $(DEPENDENCY_CHECK_VERSION)"
	@echo ""
	@if docker images $(IMAGE_NAME):$(IMAGE_TAG) --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep -v REPOSITORY; then \
		echo "$(GREEN)Local image found$(NC)"; \
	else \
		echo "$(RED)Local image not found - run 'make build' first$(NC)"; \
	fi

# CI/CD helpers
ci-build:
	docker build \
		--build-arg YQ_VERSION=$(YQ_VERSION) \
		--build-arg GITLEAKS_VERSION=$(GITLEAKS_VERSION) \
		--build-arg DEPENDENCY_CHECK_VERSION=$(DEPENDENCY_CHECK_VERSION) \
		--tag $(FULL_IMAGE_NAME) \
		--tag $(DOCKERHUB_USER)/$(IMAGE_NAME):$(shell git rev-parse --short HEAD) \
		docker/

dev-setup: build test
	@echo "$(GREEN)Development environment ready!$(NC)"
	@echo "Use 'make run' to start development container"

simulate-pipeline:
	@echo "$(GREEN)Simulating GitLab DevSecOps pipeline...$(NC)"
	@echo "Creating test files..."
	@echo "secrets:\n  enabled: true\n  fail_on_detection: false" > devsecops-config.yml
	@echo ""
	@echo "$(YELLOW)Step 1: Variable extraction$(NC)"
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		/bin/bash -c "FAIL_VALUE=\$$(cat devsecops-config.yml | yq e '.secrets.fail_on_detection // false'); echo \"FAIL_ON_SECRET_DETECTION=\$$FAIL_VALUE\""
	@echo ""
	@echo "$(YELLOW)Step 2: Secret detection$(NC)"
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		gitleaks detect --source . --report-format json --report-path gl-secret-detection-report.json --verbose || true
	@echo ""
	@echo "$(YELLOW)Results:$(NC)"
	@if [ -f gl-secret-detection-report.json ]; then \
		cat gl-secret-detection-report.json | jq .; \
	fi
	@echo ""
	@echo "$(GREEN)Pipeline simulation completed$(NC)"
	@rm -f app.js devsecops-config.yml gl-secret-detection-report.json

gitlab-secret-transform:
	@echo "$(GREEN)Simulating GitLab Secret Detection Report and HTML Generation...$(NC)"
	@mkdir -p docker/templates

	@echo '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Gitleaks Security Report</title><style>body{font-family:Arial,sans-serif;line-height:1.6;margin:20px;background-color:#f4f4f4;color:#333;}.container{max-width:1000px;margin:auto;background:#fff;padding:30px;border-radius:8px;box-shadow:0 0 10px rgba(0,0,0,0.1); }h1{color:#2c3e50;text-align:center;margin-bottom:30px;}.summary{background-color:#e9ecef;padding:15px;border-radius:5px;margin-bottom:30px;display:flex;justify-content:space-around;text-align:center;}.summary-item{flex:1;padding:10px;}.summary-item h2{margin:0;color:#555;font-size:1.2em;}.summary-item p{margin:5px 0 0;font-size:1.8em;font-weight:bold;}.finding{background-color:#fff;border:1px solid #ddd;border-left:5px solid #e74c3c;margin-bottom:20px;padding:15px;border-radius:5px;}.finding-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;}.finding-header h3{margin:0;color:#e74c3c;font-size:1.1em;}.finding-header span{font-size:0.9em;color:#777;}.finding p{margin:5px 0;font-size:0.9em;}.finding strong{color:#555;}.code-snippet{background-color:#eee;padding:10px;border-radius:3px;font-family:"Courier New",monospace;white-space:pre-wrap;word-break:break-all;font-size:0.85em;margin-top:10px;overflow-x:auto;}.metadata{font-size:0.8em;color:#888;margin-top:10px;border-top:1px dashed #eee;padding-top:10px;}.metadata span{margin-right:15px;display:inline-block;}.no-findings{text-align:center;padding:50px;color:#555;font-size:1.2em;}.footer{text-align:center;margin-top:40px;font-size:0.8em;color:#aaa;}</style></head><body><div class="container"><h1>Gitleaks Security Report</h1><div class="summary"><div class="summary-item"><h2>Total Findings</h2><p>{{ len . }}</p></div><div class="summary-item"><h2>Report Date</h2><p>{{ now.Format "2006-01-02 15:04:05" }}</p></div></div>{{ if (gt (len .) 0) }}{{ range $i, $finding := . }}<div class="finding"><div class="finding-header"><h3>{{ $finding.Description }}</h3><span>Rule ID: <strong>{{ $finding.RuleID }}</strong></span></div><p><strong>File:</strong> {{ $finding.File }}:{{ $finding.StartLine }}</p><p><strong>Secret:</strong> <span style="color: #e74c3c;">{{ if .Redacted }}REDACTED{{ else }}{{ $finding.Secret }}{{ end }}</span></p>{{- if $finding.Line }}<div class="code-snippet"><strong>Context:</strong><br>{{ $finding.Line }}</div>{{- end }}<div class="metadata"><span><strong>Commit:</strong> {{ $finding.Commit | printf "%.7s" }}</span><span><strong>Author:</strong> {{ $finding.Author }} &lt;{{ $finding.Email }}&gt;</span><span><strong>Date:</strong> {{ $finding.Date | date "2006-01-02 15:04" }}</span><span><strong>Fingerprint:</strong> {{ $finding.Fingerprint }}</span></div></div>{{ end }}{{ else }}<div class="no-findings"><p>🎉 No secrets detected! 🎉</p></div>{{ end }}<div class="footer">Generated by Gitleaks on {{ now.Format "2006-01-02 15:04:05 MST" }}</div></div></body></html>' > docker/templates/gitlab-html-report.tmpl

	@echo "$(YELLOW)Step 1: Create a dummy raw gitleaks report...$(NC)"
	@echo "[{\"Description\": \"Detected a Generic API Key, potentially exposing access to various services and sensitive operations.\", \"StartLine\": 1, \"EndLine\": 1, \"File\": \"app.js\", \"Commit\": \"b11c08eaf4346039b64885e86bbc77f37718c2e1\", \"Author\": \"Bernat\", \"Message\": \"feat: create test file with a key\", \"RuleID\": \"generic-api-key\", \"Fingerprint\": \"b11c08eaf4346039b64885e86bbc77f37718c2e1:app.js:generic-api-key:1\"},{\"Description\": \"Detected AWS Access Key, potentially exposing access to cloud resources.\", \"StartLine\": 10, \"EndLine\": 10, \"File\": \"config.py\", \"Commit\": \"a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1\", \"Author\": \"Alice\", \"Message\": \"fix: update AWS creds\", \"RuleID\": \"aws-access-key\", \"Fingerprint\": \"a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1:config.py:aws-access-key:10\"}]" > gitleaks-raw-report.json

	@echo "$(YELLOW)Step 2: Transform raw report to GitLab Secret Detection format using JQ...$(NC)"
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		/bin/bash -c "jq -c '{ \"vulnerabilities\": ( map({ id: .Fingerprint, category: \"secret_detection\", name: .Description, description: \"Secret detected by Gitleaks.\\nRule: `\\\\(.RuleID)`.\\nFile: `\\\\(.File)`.\\nLine: `\\\\(.StartLine)`.\\nCommit: `\\\\(.Commit[0:7])` by `\\\\(.Author)`.\\nCommit Message: \\\"\\\\(.Message)\\\".\", severity: \"High\", confidence: \"High\", scanner: { id: \"gitleaks\", name: \"Gitleaks\" }, location: { file: .File, start_line: .StartLine, end_line: .EndLine, commit: { sha: .Commit } }, identifiers: [ { type: \"gitleaks_rule_id\", name: \"Gitleaks Rule ID: \\\\(.RuleID)\", value: .RuleID } ] } ) ) }' gitleaks-raw-report.json > gl-secret-detection-report.json"

	@echo "$(YELLOW)Step 3: Generate HTML Report using custom template (via Gitleaks)...$(NC)"
	docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		gitleaks git --report-format template --report-template /usr/local/share/gitleaks/templates/gitlab-html-report.tmpl --report-path gitleaks-report.html --verbose || true

	@echo "$(YELLOW)Step 4: Display generated GitLab Secret Detection Report JSON...$(NC)"
	@if [ -f gl-secret-detection-report.json ]; then \
		cat gl-secret-detection-report.json | jq .; \
		echo "$(GREEN)Findings count: $$(jq '.vulnerabilities | length' gl-secret-detection-report.json)$(NC)"; \
	else \
		echo "$(RED)Error: gl-secret-detection-report.json was not created.$(NC)"; \
	fi

	@echo "$(YELLOW)Step 5: HTML Report generated: gitleaks-report.html. Open it in your browser to view the details.$(NC)"
	@if [ -f gitleaks-report.html ]; then \
		echo "$(GREEN)HTML report is available at: $(PWD)/gitleaks-report.html$(NC)"; \
	else \
		echo "$(RED)Error: gitleaks-report.html was not created.$(NC)"; \
	fi

	@echo ""
	@echo "$(GREEN)Transformation test completed. Cleaning up...$(NC)"
	@rm -f gitleaks-raw-report.json gl-secret-detection-report.json
	@rmdir docker/templates 2>/dev/null || true # Remove directory only if empty
