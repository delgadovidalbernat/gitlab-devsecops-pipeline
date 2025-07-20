# GitLab DevSecOps Pipeline

**Security-as-a-Service for GitLab CI/CD**

Integrate comprehensive security scanning (SAST, SCA, DAST, Secret Detection) into your GitLab projects with minimal configuration.

## Quick Start

Add this to your `.gitlab-ci.yml`:

```yaml
include:
  - remote: 'https://gitlab.com/bernat/gitlab-devsecops-pipeline/-/raw/main/devsecops.yml'

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

## 📋 Status

- [x] Secret Detection (GitLeaks)
- [ ] SAST (Semgrep)
- [ ] SCA (OWASP Dependency-Check)  
- [ ] DAST (OWASP ZAP)

## 🔧 Configuration

See [docs/configuration.md](docs/configuration.md) for detailed configuration options.

## 📖 Examples

Check out the [examples/](examples/) directory for sample integrations.

---
