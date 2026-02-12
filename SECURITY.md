# Security: Keeping secrets out of the repo

This repo is open-sourced; **sensitive config and secrets live in a private repo**. To avoid accidentally committing secrets, we use automated checks that cannot be bypassed on push.

Scans run only on **newly committed changes**: Gitleaks scans the commit range of the push/PR; pre-commit runs only on changed files.

## What we use

| Layer | What | Bypassable? |
|-------|------|-------------|
| **GitHub Actions** | Gitleaks + pre-commit run on every push/PR | **No** – all branches are protected by CI |
| **Branch deletion** | If Gitleaks finds leaks, the pushed/PR branch is deleted remotely | **No** – removes the branch so secrets are not left on the server |
| **Pre-commit (local)** | Same checks run before each commit | Yes (`git commit --no-verify`), but CI will still fail |

So: even if someone skips local hooks, **the push will be blocked** and the branch will be **deleted** when leaks are detected (default branches like `main`/`master` are never deleted).

**Recommendation:** In GitHub, enable branch protection (e.g. on `main`) so that "Require status checks to pass" includes the **Secret scan** workflow. That way PRs cannot be merged until Gitleaks and pre-commit CI pass.

## One-time setup after clone

Install pre-commit hooks so checks run before every commit:

```bash
# Install pre-commit if needed: pip install pre-commit  (or brew install pre-commit)
./scripts/setup-hooks.sh
```

Or manually:

```bash
pre-commit install --install-hooks
```

## Running checks manually

- All hooks: `pre-commit run --all-files`
- Only Gitleaks: `gitleaks protect --verbose --redact --all` (if gitleaks is installed)

## Customising: allowlisting false positives

- **Gitleaks**: Add path patterns or rule IDs to `.gitleaksignore` in the repo root. Do not add real secrets.
- **Pre-commit**: Adjust `.pre-commit-config.yaml` (e.g. exclude paths, relax rules) and commit the change.

## If you find a secret in history

1. Do not add it to allowlists. Treat it as compromised; rotate the secret and remove it from history (e.g. `git filter-repo` or BFG) in the private config repo if it was ever there.
2. For this repo: open an issue privately or contact maintainers so we can rotate and clean.
