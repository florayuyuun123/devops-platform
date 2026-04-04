# Setup Guide

## Accounts you need (both free, no card for first 7 days)
- GitHub: github.com
- Fly.io: fly.io — sign up with email only

> IMPORTANT: Fly.io gives a 7-day free trial.
> Before day 7 add a virtual card to stay free permanently.
> Get a free virtual Mastercard from Grey.co or Chipper Cash (Africa).
> Oracle charges $1 to verify then refunds it immediately.

---

## Step 1 — Install the Fly CLI

On WSL / Ubuntu / Linux:
```bash
curl -L https://fly.io/install.sh | sh
echo 'export FLYCTL_INSTALL="/home/$USER/.fly"' >> ~/.bashrc
echo 'export PATH="$FLYCTL_INSTALL/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

On Windows (PowerShell):
```powershell
pwsh -Command "iwr https://fly.io/install.ps1 -useb | iex"
```

Verify:
```bash
fly version
```

---

## Step 2 — Log in to Fly.io

```bash
fly auth login
# Opens browser — log in and authorise
```

---

## Step 3 — Create the Fly.io app (one time only)

```bash
cd api
fly launch --name devops-platform-api --region lhr --no-deploy
# When asked "overwrite fly.toml?" → YES
# When asked "create a PostgreSQL database?" → NO
# When asked "create an Upstash Redis database?" → NO
cd ..
```

This registers your app on Fly.io and links it to the fly.toml config.

---

## Step 4 — Get your Fly.io deploy token

```bash
fly tokens create deploy -x 999999h
# Copy the token printed — it starts with: FlyV1 ...
```

---

## Step 5 — Add token to GitHub Secrets

1. Go to your GitHub repository
2. Click Settings → Secrets and variables → Actions
3. Click New repository secret
4. Name:  FLY_API_TOKEN
5. Value: paste the token from Step 4
6. Click Add secret

---

## Step 6 — Enable GitHub Pages

1. Go to your GitHub repository
2. Click Settings → Pages
3. Under Source select: GitHub Actions
4. Click Save

---

## Step 7 — Deploy everything

```bash
git add .
git commit -m "Initial deploy"
git push origin main
```

Go to the Actions tab on GitHub — watch the pipeline run.
In about 3 minutes:
- Portal live at: https://YOUR_USERNAME.github.io/devops-platform
- API live at:    https://devops-platform-api.fly.dev

---

## Step 8 — Get a virtual card before day 7 (keep Fly.io free forever)

1. Download Grey.co app (Nigeria, Ghana, Kenya and more)
   OR Chipper Cash (available across Africa)
2. Sign up with your phone number and ID
3. Create a virtual Mastercard — $0 balance is fine
4. Go to fly.io → Account Settings → Billing
5. Add the virtual card
6. Your account stays on the free tier permanently — no charges

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
