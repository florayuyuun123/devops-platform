# Setup Guide — No credit card required anywhere

## Option A — Koyeb (cloud hosting, free forever)

### Step 1 — Accounts needed
- GitHub account: github.com (free, no card)
- Koyeb account: koyeb.com (free, no card, no expiry)

### Step 2 — Deploy API on Koyeb
1. Go to app.koyeb.com and sign up with your GitHub account
2. Click "Create Service" → "GitHub"
3. Select your devops-platform repository
4. Set these values:
   - Build type: Dockerfile
   - Dockerfile path: api/Dockerfile
   - Port: 8080
   - Instance: Free
5. Click Deploy — Koyeb gives you a URL like:
   https://devops-platform-api-YOURNAME.koyeb.app
6. Copy that URL

### Step 3 — Get your Koyeb API token
1. Koyeb dashboard → Settings → API → Create token
2. Copy the token

### Step 4 — Add GitHub Secrets
In your repo: Settings → Secrets → Actions → New secret
- Name: KOYEB_TOKEN   Value: (token from step 3)

### Step 5 — Update the API URL in the portal
Edit portal/index.html — find this line near the top of the script:
  const API = localStorage.getItem('api_url') || 'http://localhost:8080';
Students can also set their API URL by opening the browser console and running:
  localStorage.setItem('api_url', 'https://YOUR-APP.koyeb.app')

### Step 6 — Enable GitHub Pages
Settings → Pages → Source: GitHub Actions

### Step 7 — Push and deploy
```bash
git add .
git commit -m "Initial deploy"
git push origin main
```
Watch the Actions tab — portal deploys to GitHub Pages automatically.

---

## Option B — Self-hosted with Cloudflare Tunnel (best for Africa)
No card. No cloud account. Runs on any laptop or PC you own.
Cloudflare gives your machine a permanent public URL for free.

### Step 1 — On your host machine (Ubuntu/Linux)
```bash
# Install the platform
curl -s https://raw.githubusercontent.com/YOUR_USERNAME/devops-platform/main/offline-node/install.sh | bash

# Install cloudflared (Cloudflare Tunnel client)
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
  -o cloudflared.deb
sudo dpkg -i cloudflared.deb

# Start a free tunnel — no account needed for a temporary URL
cloudflared tunnel --url http://localhost:8080
# Cloudflare prints a URL like: https://random-words.trycloudflare.com
# Share that URL with your students
```

### Step 2 — Permanent URL (free, needs Cloudflare account — no card)
```bash
cloudflared tunnel login          # opens browser, login with email
cloudflared tunnel create devops-platform
cloudflared tunnel route dns devops-platform devops-platform.yourdomain.com
cloudflared tunnel run devops-platform
```

### Step 3 — Run as a background service
```bash
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
# Tunnel now starts automatically on reboot
```

---

## Updating (both options)
Any future change — new lab, bug fix, anything:
```bash
git add . && git commit -m "your change" && git push
```
GitHub Actions redeploys the portal automatically.
For self-hosted, run: git -C /opt/devops-platform pull && sudo systemctl restart devops-api
