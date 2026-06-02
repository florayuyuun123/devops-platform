# Setup Guide

## Accounts you need
- GitHub: github.com

---

## Step 1 — Enable GitHub Pages

1. Go to your GitHub repository
2. Click Settings → Pages
3. Under Source select: GitHub Actions
4. Click Save

---

## Step 2 — Deploy the platform portal

```bash
git add .
git commit -m "Initial deploy"
git push origin main
```

Go to the Actions tab on GitHub — watch the pipeline run.
In about 3 minutes, your Portal will be live at:
https://YOUR_USERNAME.github.io/devops-platform

---

## Updating the platform

Any future change is one command:
```bash
git add . && git commit -m "describe your change" && git push
```
GitHub Actions redeploys everything automatically.

---

## Offline classroom node

To run the platform on a local machine for offline classrooms:
```bash
curl -s https://raw.githubusercontent.com/YOUR_USERNAME/devops-platform/main/offline-node/install.sh | bash
```
