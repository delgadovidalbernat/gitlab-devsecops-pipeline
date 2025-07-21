# GitLab DevSecOps Pipeline

**Security-as-a-Service for GitLab CI/CD**

Integrate comprehensive security scanning (SAST, SCA, DAST, Secret Detection) into your GitLab projects with minimal configuration using our custom-built security tools image.

## Quick Start

Add this to your `.gitlab-ci.yml`:

```yaml
include:
  - remote: 'https://gitlab.com/bdelgadov/gitlab-devsecops-pipeline/-/raw/main/devsecops.yml'

variables:
  DEVSECOPS_CONFIG: |
    secrets:
      enabled: true
    sast:
      enabled: true
      severity_threshold: medium
    sca:
      enabled: true
    dast:
      enabled: false
```

That's it! Your pipeline now includes:
- **Secret Detection** with GitLeaks
- **SAST** with Semgrep
- **SCA** with OWASP Dependency-Check
- **DAST** with OWASP ZAP

## Custom Security Tools Image

This project includes a custom Docker image that combines:
- **Alpine Linux 3.18** (lightweight base)
- **GitLeaks v8.21.2** (secret detection)
- **Semgrep** (static analysis)
- **OWASP Dependency Check v9.0.8** (dependency scanning)
- **yq, jq, git** (configuration and parsing tools)

Image: `registry.gitlab.com/bdelgadov/gitlab-devsecops-pipeline/devsecops-tools:latest`

## 📋 Status

- [x] Secret Detection (GitLeaks)
- [x] Custom Docker image with all tools
- [x] Automated image building and testing
- [ ] SAST (Semgrep)
- [ ] SCA (OWASP Dependency-Check)  
- [ ] DAST (OWASP ZAP)

## 🔧 Configuration

See [docs/configuration.md](docs/configuration.md) for detailed configuration options.

## Examples

Check out the [examples/](examples/) directory for sample integrations.

## Building the Image

The security tools image is automatically built and pushed to the GitLab Container Registry when changes are made to the `docker/` directory.

To build locally:
```bash
cd docker
docker build -t devsecops-tools .
```

---
