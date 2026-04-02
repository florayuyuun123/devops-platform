# CI/CD pipelines with GitHub Actions

## Why this matters
CI/CD is how professional teams ship software safely and quickly.
Senior DevOps roles require you to own and design pipelines.

---

## Task 1 — Understand the pipeline concept
A CI/CD pipeline runs automatically when you push code:
1. **Build** — compile or package the code
2. **Test** — run automated tests
3. **Deploy** — push to staging or production

## Task 2 — Write your first GitHub Actions workflow
In your GitHub repository, create this file at `.github/workflows/ci.yml`:

```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install pytest

      - name: Run tests
        run: pytest tests/ -v

      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Report success
        run: echo "Build ${{ github.sha }} passed all checks"
```

## Task 3 — Add a deploy stage
```yaml
  deploy-staging:
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to staging
        run: |
          echo "Deploying to staging server..."
          echo "Commit: ${{ github.sha }}"
          echo "Branch: ${{ github.ref_name }}"
          # Real deployment command goes here
```

## Task 4 — Environment variables and secrets
```yaml
      - name: Deploy with secrets
        env:
          SERVER_HOST: ${{ secrets.STAGING_HOST }}
          DEPLOY_KEY:  ${{ secrets.DEPLOY_SSH_KEY }}
        run: |
          echo "Deploying to $SERVER_HOST"
          # ssh -i $DEPLOY_KEY ubuntu@$SERVER_HOST 'cd app && git pull'
```
Never hardcode secrets in your pipeline files. Always use GitHub Secrets.

## Task 5 — Pipeline badges
Add this to your README.md to show pipeline status:
```markdown
![CI](https://github.com/USERNAME/REPO/actions/workflows/ci.yml/badge.svg)
```

## Challenge
Create a full pipeline that: checks out code → runs a linter →
builds a Docker image → prints the image size. Push it and watch it run.
Screenshot the green checkmark — this goes in your portfolio.
