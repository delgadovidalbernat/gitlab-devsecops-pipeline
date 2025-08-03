# GitLab DevSecOps Pipeline

**Security-as-a-Service for GitLab CI/CD**

Integrate comprehensive security scanning (SAST, SCA, DAST, Secret Detection) into your GitLab projects with minimal configuration using our custom-built security tools image.

## Quick Start

Add this to your `.gitlab-ci.yml`:

```yaml
include:
  - remote: 'https://gitlab.com/devsecops-hub/gitlab-devsecops-pipeline/-/raw/main/devsecops.yml'

variables:
  DEVSECOPS_CONFIG: |
    secrets:
      enabled: true
      fail_on_detection: false
      redact: true
      exclude_paths:
        - .git
    sast:
      enabled: true
      severity_threshold: medium
    sca:
      enabled: true
    dast:
      enabled: false
```

That's it! Your pipeline now includes:
- **Secret Detection** with GitLeaks ✅
- **SAST** with Semgrep (coming soon)
- **SCA** with OWASP Dependency-Check (coming soon)
- **DAST** with OWASP ZAP (coming soon)

## Custom Security Tools Image

This project includes a custom Docker image that combines:
- **Alpine Linux 3.18** (lightweight base)
- **GitLeaks v8.21.2** (secret detection)
- **Semgrep** (static analysis)
- **OSV-Scanner v1.8.5** (dependency scanning)

Image: `registry.gitlab.com/devsecops-hub/gitlab-devsecops-pipeline:latest`

## 📋 Status

- [x] Secret Detection (GitLeaks)
- [x] Custom Docker image with all tools
- [x] Automated image building and testing
- [x] Configuration via YAML
- [x] GitLab Security Dashboard integration
- [x] HTML and JSON reports
- [x] SAST (Semgrep)
- [x] SCA (OSV-Scanner)
- [x] DAST (OWASP ZAP)

## 🔧 Configuration

### Secret Detection Configuration

```yaml
secrets:
  enabled: true                    # Enable/disable secret detection
  fail_on_detection: false         # Fail pipeline when secrets found
  redact: true                     # Redact secrets in output
  exclude_paths:                   # Paths to exclude from scanning
    - .git
```

### SAST Configuration

```yaml
sast:
  enabled: true
  severity_threshold: medium       # low, medium, high
  languages: "auto"
  fail_on_detection: false
  exclude_paths: []

```

### SCA Configuration (planned)

```yaml
sca:
    enabled: true
    severity_threshold: "medium" # low, medium, high, critical
    fail_on_detection: false
    ecosystems: "auto" # auto, o rutas específicas
    recursive: true
    exclude_paths: []
```

### DAST Configuration (planned)

```yaml
dast:
    enabled: true
    target_url: "http://some-app.example.com"
    login_page: "/login"
    username: "admin"
    password: "admin123"
    openapi_spec: "auto"
    max_scan_duration: "30000"
    fail_on_detection: false
    exclude_paths:
    - "/swagger/*"
    - "/docs/*"
```

## Features

- **Zero Configuration**: Works out of the box with minimal setup
- **GitLab Integration**: Native integration with GitLab Security Dashboard
- **Flexible Configuration**: YAML-based configuration for all tools
- **Comprehensive Reports**: Both JSON (for GitLab) and HTML (for humans) reports
- **Exclude Paths**: Fine-grained control over what gets scanned
- **Fail Control**: Choose whether to fail pipeline on findings

## Examples

Check out the [examples/](examples/) directory for sample integrations:
- [Basic Example](examples/basic/) - Simple integration
- [Advanced Example](examples/advanced/) - Custom configuration (coming soon)

## Building the Image

The security tools image is automatically built and pushed to the GitLab Container Registry when changes are made.

To build locally:
```bash
make build
```

## Pipeline Stages

The security pipeline adds a `security` stage that runs after your existing stages:

1. **Pre-stage**: Configuration extraction
2. **Security stage**: 
   - Secret detection (GitLeaks)
   - SAST (Semgrep)
   - SCA (planned)
   - DAST (planned)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Third-Party Tools

This project uses the following external tools in its DevSecOps pipeline:

- **Semgrep**: [https://semgrep.dev](https://semgrep.dev)
  License: [LGPL-2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html)
  Included as a binary in the Docker image.

  The rules are not included in this repository or its Docker image. By using Semgrep rules, users agree to the terms at https://semgrep.dev/legal/rules-license. This project does not redistribute or bundle these rules.

- **Gitleaks**: [https://github.com/gitleaks/gitleaks](https://github.com/gitleaks/gitleaks)
  License: MIT
  Included as a binary in the Docker image.

- **OSV-Scanner**: [https://google.github.io/osv-scanner/](https://google.github.io/osv-scanner/)
  License: Apache-2.0
  Included as a binary in the Docker image.

- **OWASP ZAP**: [https://www.zaproxy.org/](https://www.zaproxy.org/)
  License: Apache-2.0
  Included as a binary in the Docker image.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## Support

- 🐛 [Issue Tracker](../../issues)

---
