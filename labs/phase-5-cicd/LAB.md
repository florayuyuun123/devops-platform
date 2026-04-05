# CI/CD Pipelines with GitHub Actions

CI/CD is the heart of DevOps. It is how professional teams "ship" software safely and quickly. If you can build and maintain a pipeline, you are essentially a full-fledged DevOps Engineer.

---

## Task 1 — The Pipeline Concept (The "Factory Line")

### The Concept (What)
A **Pipeline** is a series of automated steps that run whenever code is pushed. If the steps pass, the code is "shipped." If they fail, the pipeline stops to protect the app.

### Real-world Context (Why)
At a company, you might have 100 developers. You cannot manually check every single line of code! A pipeline acts as a 24/7 security guard that tests everything automatically.

### Execution (How)
1. **Build** — Packaging the code (like creating a Docker image).
2. **Test** — Running automated scripts to find bugs.
3. **Deploy** — Sending the finished app to the server.

---

## Task 2 — Your First Workflow (YAML)

### The Concept (What)
A **Workflow** is the YAML file that tells GitHub Actions *exactly* what to do.

### Real-world Context (Why)
Writing this file is your primary job. You are defining the "Rules of Engagement" for how software gets built at your company.

### Execution (How)
Create this file in your GitHub repo at `.github/workflows/ci.yml`.

```yaml
name: CI Pipeline

on:
  push:
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
        run: echo "No tests yet — but if I had them, I would run them here!"
```

---

## Task 3 — Automated Docker Builds

### The Concept (What)
We add a step to our pipeline to build a Docker image every time we push code.

### Real-world Context (Why)
You want to know *immediately* if a developer's change "broke the build." If the Docker build fails in the pipeline, it won't break the actual website for customers.

### Execution (How)
Add this step to your `ci.yml` file under the others.

```yaml
      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .
```
*Note: `${{ github.sha }}` is a unique ID for every commit. This ensures every version of your app has its own unique name.*

---

## Task 4 — Deployment (CD)

### The Concept (What)
**Continuous Deployment (CD)** is the final step where the successfully tested code is pushed to a live server.

### Real-world Context (Why)
"Time to Market" is critical. If a developer fixes a bug at 9:00 AM, the pipeline can have it live for customers by 9:05 AM without any human manager needing to click "Go."

### Execution (How)
An example of how a deployment block looks in GitHub Actions.

```yaml
  deploy-staging:
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to staging
        run: |
          echo "Deploying to staging server..."
          echo "Commit: ${{ github.sha }}"
```

---

## Task 5 — Secrets (Security First)

### The Concept (What)
**GitHub Secrets** allow you to hide your passwords and API keys from the public, while still letting the pipeline use them.

### Real-world Context (Why)
If you hardcode a password in a public GitHub repo, a bot will find it and hack you in less than 60 seconds. **NEVER** put secrets in your code. Put them in the GitHub Settings > Secrets tab instead.

---

## Challenge
Find out how to add a "Status Badge" (a small green icon) to your README.md file that shows if your pipeline is passing or failing. This is a "badge of honor" for any professional repository!
