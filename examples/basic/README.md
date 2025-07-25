# Basic Example

This example demonstrates the simplest possible integration of the GitLab DevSecOps Pipeline.

## What it does

- ✅ Integrates secret detection with GitLeaks
- ✅ Shows how to configure security thresholds
- ✅ Demonstrates integration with existing CI/CD jobs
- ✅ Generates GitLab Security Dashboard reports
- ✅ Creates both JSON and HTML reports

## Quick test

1. Copy `.gitlab-ci.yml` to your project
2. Push to GitLab
3. Check the pipeline - you should see a security stage with secret detection
4. The pipeline will detect any secrets in the repository and report them
5. Check the **Security & Compliance > Security Dashboard** for detailed findings

## Configuration explained

```yaml
DEVSECOPS_CONFIG: |
  secrets:
    enabled: true              # Enable secret detection
    fail_on_detection: false   # Don't fail pipeline on secrets (for demo)
    redact: true               # Hide actual secret values in logs
    exclude_paths:             # Paths to exclude from scanning
      - .git                   # Exclude git directory
  sast:
    enabled: true
    severity_threshold: "medium" # Minimum severity for SAST findings
    languages: "auto"            # Specific rulesets to use (recommended: "auto")
    fail_on_detection: false
    exclude_paths: []
  sca:
    enabled: true              # Enable dependency scanning (when implemented)
  dast:
    enabled: false             # Disable DAST (requires deployed app)
```

## Pipeline Flow

1. **Build Stage**: Your application build process
2. **Test Stage**: Your existing tests
3. **Security Stage**: 
   - Configuration extraction (`.pre` stage)
   - Secret detection with GitLeaks
   - SAST with Semgrep
4. **Deploy Stage**: Your deployment process

## Expected output

The secret detection job will:
- Scan your entire repository for secrets
- Generate a GitLab-compatible security report
- Create an HTML report for easy viewing
- Show findings in the pipeline logs (redacted if `redact: true`)

### Example findings format:
```
Warning: 2 secret(s) detected. Check the Security tab for details.

----------------------------------------------------
Summary of Detected Secrets:
- API Key Detected: app.js:15 (Commit: a1b2c3d by developer)
- Database Password: config/database.yml:8 (Commit: e4f5g6h by admin)
----------------------------------------------------

Check the Security tab in GitLab for detailed analysis.
Pipeline continues despite secrets (fail_on_detection configured to false)
```


The SAST job will:
- Analyze your codebase for security issues
- Generate a report in the GitLab Security Dashboard
- Show findings in the pipeline logs
- Create an HTML report for easy viewing

```
Warning: 2 SAST finding(s) detected.
----------------------------------------------------
Summary of SAST Findings:
- Medium: Detected the use of eval() in app.js:7
- High: Found data from an Express or Next web request flowing to `eval` in app.js:7
----------------------------------------------------
```


## Artifacts Generated

After the security stage completes, you'll find:

- `gl-secret-detection-report.json` - GitLab Security Dashboard format
- `gl-sast-report.json` - GitLab SAST format
- `gitleaks-report.html` - Human-readable HTML report
- `gitleaks-raw-report.json` - Raw GitLeaks output
- `.gitleaks.toml` - Generated GitLeaks configuration
- `.semgrepignore` - Generated Semgrep ignore file
- `semgrep-report.html` - Human-readable HTML report for SAST findings


## Testing Secret Detection

To test the secret detection, you can add a test secret to any file:

```javascript
// app.js
const apiKey = "sk-test-123456789abcdef"; // This will be detected
```

# Testing SAST
To test SAST, you can add a known issue in your code:

```javascript
const express = require('express');
const app = express();

app.get('/eval', (req, res) => {
	eval(req.query.code); // Direct user input evaluation
	res.send('done');
});
```

## Troubleshooting

**No security stage visible?**
- Ensure the remote include is correct
- Check that `DEVSECOPS_CONFIG` is properly formatted YAML

**No findings shown?**
- Add a test secret to verify detection works
- Check exclude paths aren't too broad

**No git commit history analysis?**
- Check exclude paths do not include `.git`
- Ensure gitlab is not limiting access to commit history in the pipeline (default behavior allows 20 commits)
