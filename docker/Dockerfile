FROM alpine:3.22.1

LABEL maintainer="Bernat Delgado <delgadovidalbernat@gmail.com>"
LABEL description="GitLab DevSecOps Tools"

# Install base dependencies
RUN apk add --no-cache \
	curl \
	jq \
	git \
	ca-certificates \
	tar \
	gzip \
	bash \
	chromium \
	nss \
	freetype \
	harfbuzz \
	icu \
	&& rm -rf /var/cache/apk/*

# Install yq for YAML parsing
ARG YQ_VERSION=v4.46.1
RUN curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" -o /usr/local/bin/yq && \
	chmod +x /usr/local/bin/yq && \
	yq --version

# Install GitLeaks
ARG GITLEAKS_VERSION=8.28.0
RUN curl -sL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" | \
	tar -xz -C /usr/local/bin/ && \
	chmod +x /usr/local/bin/gitleaks && \
	gitleaks version

# Install Semgrep
RUN apk add --no-cache python3 py3-pip && \
	python3 -m venv /opt/venv && \
	. /opt/venv/bin/activate && \
	pip install --no-cache-dir semgrep && \
	ln -s /opt/venv/bin/semgrep /usr/local/bin/semgrep && \
	semgrep --version

# Install OWASP ZAP
ARG ZAP_VERSION=2.16.0
RUN apk add --no-cache openjdk17-jre-headless && \
	curl -sL "https://github.com/zaproxy/zaproxy/releases/download/v${ZAP_VERSION}/ZAP_${ZAP_VERSION}_Linux.tar.gz" -o /tmp/zap.tar.gz && \
	tar -xzf /tmp/zap.tar.gz -C /opt/ && \
	rm /tmp/zap.tar.gz && \
	ln -s /opt/ZAP_${ZAP_VERSION}/zap.sh /usr/local/bin/zap

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Download ZAP Python scripts desde Docker oficial
RUN curl -sL "https://raw.githubusercontent.com/zaproxy/zaproxy/main/docker/zap-baseline.py" -o /usr/local/bin/zap-baseline.py && \
	curl -sL "https://raw.githubusercontent.com/zaproxy/zaproxy/main/docker/zap-api-scan.py" -o /usr/local/bin/zap-api-scan.py && \
	curl -sL "https://raw.githubusercontent.com/zaproxy/zaproxy/main/docker/zap-full-scan.py" -o /usr/local/bin/zap-full-scan.py && \
	chmod +x /usr/local/bin/zap-*.py

# Install Python dependencies for ZAP scripts
RUN . /opt/venv/bin/activate && \
	pip install --no-cache-dir python-owasp-zap-v2.4 requests

# Install OSV-Scanner
ARG OSV_SCANNER_VERSION=1.8.5
RUN wget -q https://github.com/google/osv-scanner/releases/download/v${OSV_SCANNER_VERSION}/osv-scanner_linux_amd64 && \
	chmod +x osv-scanner_linux_amd64 && \
	mv osv-scanner_linux_amd64 /usr/local/bin/osv-scanner

RUN mkdir -p /usr/local/share/gitleaks/templates/
COPY templates/gitleaks/html-report.tmpl /usr/local/share/gitleaks/templates/gitlab-html-report.tmpl

RUN addgroup -S devsecops && adduser -S devsecops -G devsecops

RUN git config --global --add safe.directory '*'

WORKDIR /workspace

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
	CMD yq --version && gitleaks version && semgrep --version || exit 1

CMD ["/bin/bash"]
