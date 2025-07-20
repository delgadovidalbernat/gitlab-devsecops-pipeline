# Variables
IMAGE_NAME := devsecops-tools
IMAGE_TAG := latest
DOCKERHUB_IMAGE := $(DOCKERHUB_USER)/$(IMAGE_NAME)
FULL_IMAGE_NAME := $(DOCKERHUB_IMAGE):$(IMAGE_TAG)

# Docker build arguments
YQ_VERSION := v4.40.5
GITLEAKS_VERSION := 8.21.2
DEPENDENCY_CHECK_VERSION := 9.0.8

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
		--build-arg YQ_VERSION=$(YQ_VERSION) \
		--build-arg GITLEAKS_VERSION=$(GITLEAKS_VERSION) \
		--build-arg DEPENDENCY_CHECK_VERSION=$(DEPENDENCY_CHECK_VERSION) \
		--tag $(IMAGE_NAME):$(IMAGE_TAG) \
		--tag $(IMAGE_NAME):dev \
		docker/
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
