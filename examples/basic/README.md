# Basic Example

This example demonstrates the simplest possible integration of the GitLab DevSecOps Pipeline.

## What it does

- ✅ Integrates secret detection
- ✅ Shows how to configure security thresholds
- ✅ Demonstrates integration with existing CI/CD jobs
- ✅ Includes an intentional secret for testing

## Quick test

1. Copy `.gitlab-ci.yml` to your project
2. Push to GitLab
3. Check the pipeline - you should see a security stage with secret detection
4. The pipeline will detect the API key in `app.js` and report it

## Configuration explained

```yaml
DEVSECOPS_CONFIG: |
  secrets:
    enabled: true              # Enable secret detection
    fail_on_detection: false   # Don't fail pipeline on secrets (for demo)
  sast:
    enabled: true              # Enable SAST (when implemented)
    severity_threshold: medium # Only report medium+ severity issues
  sca:
    enabled: true              # Enable dependency scanning
  dast:
    enabled: false             # Disable DAST (requires deployed app)
```

## Expected output

The secret detection job should find:
- API key in `app.js`: `sk-test-123456789`

Since `fail_on_detection: false`, the pipeline will continue but show the warning.
