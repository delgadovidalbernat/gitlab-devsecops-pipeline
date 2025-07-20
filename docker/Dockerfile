FROM alpine:3.18

LABEL maintainer="Bernat Delgado <bdelgadov@gmail.com>"
LABEL description="GitLab DevSecOps Tools - Alpine-based security scanning tools"
LABEL version="2.1.0"

# Install base dependencies
RUN apk add --no-cache \
	curl \
	jq \
	git \
	ca-certificates \
	tar \
	gzip \
	bash \
	&& rm -rf /var/cache/apk/*

# Install yq for YAML parsing
ARG YQ_VERSION=v4.40.5
RUN curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" -o /usr/local/bin/yq && \
	chmod +x /usr/local/bin/yq && \
	yq --version

# Install GitLeaks
ARG GITLEAKS_VERSION=8.28.0
RUN curl -sL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" | \
	tar -xz -C /usr/local/bin/ && \
	chmod +x /usr/local/bin/gitleaks && \
	gitleaks version

# Install Semgrep (for future SAST)
RUN apk add --no-cache python3 py3-pip && \
	pip3 install --no-cache-dir semgrep && \
	semgrep --version

# Install OWASP Dependency Check (for future SCA)
ARG DEPENDENCY_CHECK_VERSION=9.0.8
RUN apk add --no-cache openjdk11-jre-headless && \
	curl -sL "https://github.com/jeremylong/DependencyCheck/releases/download/v${DEPENDENCY_CHECK_VERSION}/dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip" -o /tmp/dependency-check.zip && \
	unzip -q /tmp/dependency-check.zip -d /opt/ && \
	ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check && \
	rm /tmp/dependency-check.zip

RUN mkdir -p /usr/local/share/gitleaks/templates/
COPY templates/gitlab-html-report.tmpl /usr/local/share/gitleaks/templates/gitlab-html-report.tmpl

# Create non-root user for security but keep root for flexibility (for now)
RUN addgroup -S devsecops && adduser -S devsecops -G devsecops

RUN git config --global --add safe.directory '*'

WORKDIR /workspace

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
	CMD yq --version && gitleaks version && semgrep --version || exit 1

CMD ["/bin/bash"]
