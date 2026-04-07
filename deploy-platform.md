# DevOps Learning Platform — Complete Setup & Operations Guide (v3.0 Stable)

> Free, offline-capable, hands-on DevOps training for everyone.
> No credit card required. Works without internet. Costs $0 to run.
> Written from real deployment experience — every step here was tested and verified.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Curriculum — 10 Phases](#3-curriculum--10-phases)
4. [What You Need](#4-what-you-need)
5. [Step 1 — Create a GitHub Account](#5-step-1--create-a-github-account)
6. [Step 2 — Install Git](#6-step-2--install-git)
7. [Step 3 — Configure Git Identity](#7-step-3--configure-git-identity)
8. [Step 4 — Create the Repository](#8-step-4--create-the-repository)
9. [Step 5 — Run the Setup Script](#9-step-5--run-the-setup-script)
10. [Step 6 — Enable GitHub Pages](#10-step-6--enable-github-pages)
11. [Step 7 — Install Python Dependencies](#11-step-7--install-python-dependencies)
12. [Step 8 — Copy Labs Into the API](#12-step-8--copy-labs-into-the-api)
13. [Step 9 — Write the API File](#13-step-9--write-the-api-file)
14. [Step 10 — Fix Docker Permissions](#14-step-10--fix-docker-permissions)
15. [Step 11 — Build the Sandbox Image](#15-step-11--build-the-sandbox-image)
16. [Step 12 — Start the Platform](#16-step-12--start-the-platform)
17. [Step 13 — Update the Portal URL](#17-step-13--update-the-portal-url)
18. [Step 14 — Verify Everything Works](#18-step-14--verify-everything-works)
19. [Every Time You Start Your Machine](#19-every-time-you-start-your-machine)
20. [Step 15 — Offline Classroom Node](#20-step-15--offline-classroom-node)
21. [Step 16 — Oracle Cloud (Permanent 24/7)](#21-step-16--oracle-cloud-permanent-247)
22. [Step 17 — Permanent Background Services (systemd)](#22-step-17--permanent-background-services-systemd)
23. [Adding New Labs](#23-adding-new-labs)
24. [Managing Students](#24-managing-students)
25. [Master Platform Maintenance (`fix-everything.sh`)](#25-master-platform-maintenance-fix-everything-sh)
26. [Technical Recovery & Troubleshooting](#26-technical-recovery--troubleshooting)
27. [Platform Uptime Reference](#27-platform-uptime-reference)
28. [Glossary](#28-glossary)
29. [Quick Reference](#29-quick-reference)

---

## 1. Project Overview

The DevOps Learning Platform gives students a real Linux terminal in their
browser with guided hands-on labs — no software to install on the student's
device. It runs entirely for free using GitHub and your own machine.

### What students experience

1. Open the portal URL in any browser (phone, tablet, laptop)
2. Log in with any username and password
3. Click a phase and a lab
4. Click **Start sandbox**
5. A real Linux terminal opens at the bottom of the screen
6. Follow the lab guide and practice real DevOps commands

### Cost

| Component | Cost |
|---|---|
| GitHub account + Pages | $0 forever |
| Cloudflare Tunnel | $0 forever, no account needed |
| Your machine (API + sandboxes) | $0 — runs on existing hardware |
| Oracle Cloud upgrade (optional) | $0 forever after one-time verification |
| **Total** | **$0** |

> **Note:** Fly.io, Koyeb, and Render all now require credit cards.
> Do not use them. This platform uses only GitHub and your own machine.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────┐
│              STUDENT BROWSER                    │
│   Phone, tablet, laptop — no installs needed    │
└───────────┬─────────────────────────────────────┘
            │
     ┌──────┴──────┐
     │             │
┌────▼────┐  ┌─────▼──────────────────────────────┐
│ GitHub  │  │     Cloudflare Tunnel               │
│ Pages   │  │     Free public HTTPS URL           │
│ Portal  │  │     Points to your machine          │
│ Always  │  └─────┬──────────────────────────────┘
│ live    │        │ forwards to port 8080
└─────────┘  ┌─────▼──────────────────────────────┐
             │     Your Machine (WSL/Ubuntu)       │
             │     API server — port 8080          │
             │     python3 -m uvicorn main:app     │
             └─────┬──────────────────────────────┘
                   │ docker run
             ┌─────▼──────────────────────────────┐
             │     Student Sandboxes              │
             │     Docker containers              │
             │     ttyd terminal on random port   │
             │     Proxied through API port 8080  │
             └────────────────────────────────────┘
```

### Key design decisions learned from deployment

- **The tunnel only exposes one port (8080)**. All terminal traffic is proxied through the API.
- **Port Determinism**: Sandbox ports are calculated using a SHA1 hash of the container name. This ensures a student's terminal port remains consistent even if the API restarts.
- **Network Host Mode**: Sandboxes run with `--network host`. This allows `localhost` inside the sandbox to correctly reach the host machine, which is critical for learning web servers, curl, and database connections.
- **WebSocket Proxying**: The API dynamically injects a WebSocket fix into the terminal HTML so it connects through the public tunnel URL instead of attempting a local connection.
- **UI Performance**: One-click copy buttons and a resizable terminal split-pane are handled by the portal to minimize student friction.

---

## 3. Curriculum — 10 Phases

| Phase | Topic | Key Tools | Job Relevance |
|---|---|---|---|
| 1 | Linux fundamentals | bash, chmod, grep, find | Required in every DevOps role |
| 2 | Networking & security | SSH, DNS, TCP/IP, ufw, nmap | Tested in every interview |
| 3 | Git & version control | git, GitHub flow, branching | Non-negotiable in all software roles |
| 4 | Docker & containers | docker, Dockerfile, Compose | 90% of DevOps job ads list this |
| 5 | CI/CD pipelines | GitHub Actions, Jenkins | Senior roles require pipeline ownership |
| 6 | Ansible automation | playbooks, roles, inventory | Top tool for sysadmin-to-DevOps roles |
| 7 | Kubernetes | kubectl, deployments, Helm | Highest salary premium in DevOps |
| 8 | Terraform / IaC | providers, state, modules | Required for cloud engineering |
| 9 | Monitoring & observability | Prometheus, Grafana, alerting | SRE roles need this on day one |
| 10 | Capstone project | All tools combined | Portfolio piece for interviews |

---

## 4. What You Need

- A computer running Ubuntu 22.04 or WSL2 on Windows
- At least 4GB RAM (8GB recommended)
- At least 20GB free disk space
- Internet access for initial setup
- A GitHub account (free, no card)
- Docker installed (comes with Ubuntu, or install separately)

> **WSL users:** Open WSL from the Windows Start menu for all commands.
> Do not use Git Bash or PowerShell — WSL is the correct environment.

---

## 5. Step 1 — Create a GitHub Account

1. Go to **https://github.com**
2. Click **Sign up**
3. Enter your email, choose a username, verify your email
4. Your portal URL will be:
   `https://YOUR_USERNAME.github.io/devops-platform`

No credit card needed. GitHub is free forever.

---

## 6. Step 2 — Install Git

```bash
sudo apt-get update && sudo apt-get install -y git
```

Verify:
```bash
git --version
# git version 2.x.x
```

---

## 7. Step 3 — Configure Git Identity

Use the exact email you used to sign up on GitHub.

```bash
git config --global user.email "your-github-email@example.com"
git config --global user.name "Your Name"
```

Store credentials so you are not asked every push:
```bash
git config --global credential.helper store
```

### Get a GitHub Personal Access Token

GitHub does not accept your password for `git push`. You need a token.

1. GitHub → profile photo → **Settings**
2. Left sidebar bottom → **Developer settings**
3. **Personal access tokens** → **Tokens (classic)**
4. **Generate new token (classic)**
5. Note: `devops-platform`, Expiration: **No expiration**, Scope: **repo**
6. Click **Generate token** — copy it immediately (shown once only)

When Git asks for your password during `git push`, paste this token.
After the first push, `credential.helper store` remembers it permanently.

---

## 8. Step 4 — Create the Repository

1. GitHub → **+** → **New repository**
2. Name: `devops-platform`, Visibility: **Public**, nothing else checked
3. Click **Create repository**

Clone it:
```bash
git clone https://github.com/YOUR_USERNAME/devops-platform.git
cd devops-platform
```

---

## 9. Step 5 — Run the Setup Script

Copy `setup-devops-platform.sh` into the `devops-platform` folder, then:

```bash
chmod +x setup-devops-platform.sh
./setup-devops-platform.sh
```

When asked **"Ready to push to GitHub? (y/n)"** — type `y`.

When Git asks for your password — paste your Personal Access Token.

> **Known issue:** The script may show `cp: cannot stat 'labs'` if the
> working directory is wrong at that moment. This is harmless — you will
> copy labs manually in Step 8.

The script creates all folders and files but `api/main.py` may not be
complete. Step 9 writes the correct version.

---

## 10. Step 6 — Enable GitHub Pages

1. Go to your repository on GitHub
2. **Settings** → **Pages**
3. Under Source: select **GitHub Actions**
4. Click **Save**

Your portal URL:
```
https://YOUR_USERNAME.github.io/devops-platform
```

---

## 11. Step 7 — Install Python Dependencies

```bash
# Install pip3
sudo apt install python3-pip -y

# Add pip's bin to PATH permanently
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Install all API dependencies
pip3 install fastapi uvicorn python-multipart \
  passlib[bcrypt] python-jose[cryptography] aiofiles httpx websockets
```

Successful output ends with:
```
Successfully installed fastapi uvicorn httpx websockets ...
```

---

## 12. Step 8 — Copy Labs Into the API

> This step is the most common cause of "Labs coming soon."
> Always run it from the **project root**, never from inside `api/`.

```bash
# Make sure you are in the project root
cd ~/devops-platform

# Remove any old labs folder and copy fresh
rm -rf api/labs
cp -r labs api/labs

# Verify all 10 phases are present
ls api/labs/
```

Expected output:
```
phase-1-linux      phase-2-networking  phase-3-git
phase-4-docker     phase-5-cicd        phase-6-ansible
phase-7-kubernetes phase-8-terraform   phase-9-monitoring
phase-10-capstone
```

If you see 10 folders — correct. If empty — you ran it from inside `api/`.

---

## 13. Step 9 — Write the API File

The setup script may not have written `api/main.py` correctly. Write it
now using this reliable method:

```bash
# Fix permissions first
sudo chown -R $USER:$USER ~/devops-platform/api
```

Then run this Python script to write main.py:

```python
import os, asyncio, subprocess, json, time, secrets, httpx
from fastapi import FastAPI, HTTPException, Request, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel

app = FastAPI(title="DevOps Learning Platform", version="1.0.1")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

SESSIONS, SANDBOX_REGISTRY = {}, {}
LABS_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "labs")

class AuthRequest(BaseModel):
    username: str
    password: str

class SandboxRequest(BaseModel):
    student_id: str
    lab_id: str

def get_port(name):
    import hashlib
    h = int(hashlib.sha1(name.encode()).hexdigest(), 16)
    return 7700 + (h % 200)

@app.post("/auth/login")
@app.post("/auth/register")
def login(req: AuthRequest):
    token = secrets.token_hex(32)
    SESSIONS[token] = {"username": req.username, "created": int(time.time())}
    return {"token": token, "username": req.username}

@app.get("/health")
def health():
    return {"status": "ok", "labs_found": os.path.exists(LABS_PATH)}

@app.post("/sandbox/start")
def start_sandbox(req: SandboxRequest):
    cn = "sb_{}_{}".format(req.student_id, req.lab_id).replace("-","_")
    if subprocess.run(["docker","ps","-q","-f","name={}".format(cn)], capture_output=True, text=True).stdout.strip():
        return {"status":"already_running","port":get_port(cn),"terminal_path":"/terminal/{}".format(cn)}
    
    subprocess.run(["docker","rm","-f",cn], capture_output=True)
    port = get_port(cn)
    lp = os.path.join(LABS_PATH, req.lab_id)
    
    cmd = ["docker","run","-d","--name",cn,"--memory","512m","--cpus","0.5","--network","host","-v","/var/run/docker.sock:/var/run/docker.sock","--label","student={}".format(req.student_id),"--label","lab={}".format(req.lab_id)]
    if os.path.exists(lp): cmd += ["-v","{}:/home/student/lab:ro".format(lp)]
    cmd.append("devops-sandbox:latest")
    cmd.extend(["ttyd", "-p", str(port), "bash", "--login"])
    
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0: raise HTTPException(status_code=500, detail=r.stderr)
    return {"status":"started","port":port,"terminal_path":"/terminal/{}".format(cn)}

@app.get("/terminal/{container_name}")
async def terminal_page(container_name: str):
    port = get_port(container_name)
    if not port: raise HTTPException(status_code=404, detail="not found")
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            resp = await c.get("http://localhost:{}/".format(port))
            body = resp.content
            body = body.replace(b'src="/', 'src="/terminal/{}/'.format(container_name).encode())
            body = body.replace(b'href="/', 'href="/terminal/{}/'.format(container_name).encode())
            import re
            body = re.sub(b'http://localhost:[0-9]+', b'', body)
            ws_fix = b'''<script>(function(){var _W=window.WebSocket;window.WebSocket=function(u,p){if(u.indexOf("localhost")!==-1||u.indexOf("127.0.0.1")!==-1){var l=window.location;var pr=l.protocol==="https:"?"wss:":"ws:";u=pr+"//"+l.host+"/terminal/''' + container_name.encode() + b'''/ws";}return p?new _W(u,p):new _W(u);};window.WebSocket.prototype=_W.prototype;})();</script>'''
            body = body.replace(b'<head>', b'<head>' + ws_fix)
            return Response(content=body, media_type=resp.headers.get("content-type","text/html"))
    except Exception as e: raise HTTPException(status_code=502, detail=str(e))

@app.websocket("/terminal/{container_name}/ws")
async def terminal_ws(websocket: WebSocket, container_name: str):
    port = get_port(container_name)
    subprotocols = websocket.headers.get("sec-websocket-protocol", "")
    proto = subprotocols.split(",")[0].strip() if subprotocols else None
    if proto: await websocket.accept(subprotocol=proto)
    else: await websocket.accept()
    
    try:
        import websockets as wsl
        kw = {"subprotocols":[proto]} if proto else {}
        async with wsl.connect("ws://localhost:{}/ws".format(port), **kw) as backend:
            async def fwd(src, dst, is_ws_src):
                try:
                    while True:
                        if is_ws_src:
                            try: d = await src.receive_bytes()
                            except: d = (await src.receive_text()).encode()
                        else: d = await src.recv()
                        if is_ws_src: await dst.send(d)
                        else:
                            if isinstance(d, bytes): await dst.send_bytes(d)
                            else: await dst.send_text(d)
                except: pass
            await asyncio.gather(fwd(websocket, backend, True), fwd(backend, websocket, False))
    except: pass
    finally: await websocket.close()
```

Verify:
```bash
wc -l ~/devops-platform/api/main.py
head -3 ~/devops-platform/api/main.py
```

---

## 14. Step 10 — Fix Docker Permissions

Docker socket permissions reset on every reboot in WSL.
Run this every time you start:

```bash
sudo chmod 666 /var/run/docker.sock
```

Test Docker works:
```bash
docker run hello-world
```

Expected: `Hello from Docker!`

If Docker daemon is not running:
```bash
sudo service docker start
sudo chmod 666 /var/run/docker.sock
```

---

## 15. Step 11 — Build the Sandbox Image

This builds the Docker image that every student sandbox uses.
Run once — takes 3–5 minutes.

```bash
cd ~/devops-platform/sandbox
docker build -t devops-sandbox:latest .
```

When finished:
```bash
docker images | grep devops-sandbox
# devops-sandbox   latest   xxxxxxxxx   X minutes ago   1.39GB
```

---

## 16. Step 12 — Start the Platform

Use `nohup` so the processes survive terminal idle in WSL:

```bash
# Fix Docker permissions
sudo chmod 666 /var/run/docker.sock

# Copy labs (always from project root)
cd ~/devops-platform
rm -rf api/labs && cp -r labs api/labs

# Kill anything already on port 8080
sudo kill -9 $(sudo lsof -t -i:8080) 2>/dev/null || true
sleep 1

# Start API in background
cd ~/devops-platform/api
nohup python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 \
  > /tmp/api.log 2>&1 &
echo "API PID: $!"

# Wait and verify
sleep 3
curl -s http://localhost:8080/health
```

Expected:
```json
{"status":"ok","platform":"DevOps Learning Platform","version":"1.0.0","labs_found":true}
```

Then start the tunnel:
```bash
nohup cloudflared tunnel --url http://localhost:8080 \
  > /tmp/tunnel.log 2>&1 &
echo "Tunnel PID: $!"

# Wait for the URL
sleep 10
grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/tunnel.log | head -1
```

Copy the URL printed — you need it in the next step.

---

## 17. Step 13 — Update the Portal URL

Every time the tunnel starts it gets a new random URL.
Update the portal with the new URL and push to GitHub.

```bash
cd ~/devops-platform

# Set your new tunnel URL
NEW_URL="https://YOUR-WORDS.trycloudflare.com"

# Get the old URL currently in the portal
OLD_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' portal/index.html | head -1)
echo "Old: $OLD_URL"
echo "New: $NEW_URL"

# Replace it
sed -i "s|$OLD_URL|$NEW_URL|g" portal/index.html

# Verify
grep "trycloudflare" portal/index.html

# Push to GitHub
git add .
git commit -m "Update tunnel URL: $NEW_URL"
git push origin main
```

GitHub Actions deploys the updated portal within 2 minutes.

---

## 18. Step 14 — Verify Everything Works

### Check 1 — API health
```bash
curl -s http://localhost:8080/health
# {"status":"ok","labs_found":true}
```

### Check 2 — Labs loading
```bash
curl -s http://localhost:8080/labs | python3 -m json.tool | head -20
# Should show all 10 labs
```

### Check 3 — API through tunnel (open in browser)
```
https://YOUR-WORDS.trycloudflare.com/health
```

### Check 4 — Start a sandbox
```bash
curl -X POST http://localhost:8080/sandbox/start \
  -H "Content-Type: application/json" \
  -d '{"student_id": "test", "lab_id": "phase-1-linux"}' \
  | python3 -m json.tool
```

Expected:
```json
{
    "status": "started",
    "container": "sb_test_phase_1_linux",
    "port": 7756,
    "terminal_path": "/terminal/sb_test_phase_1_linux"
}
```

### Check 5 — Terminal proxy
```bash
curl -s http://localhost:8080/terminal/sb_test_phase_1_linux | head -3
# Should return HTML
```

### Check 6 — Student portal (open in browser)
```
https://YOUR_USERNAME.github.io/devops-platform
```

Log in → Phase 1 → Linux lab → Start sandbox.
Terminal panel opens at the bottom with a real bash prompt.

### Clean up test container
```bash
docker stop sb_test_phase_1_linux
docker rm sb_test_phase_1_linux
```

---

## 19. Every Time You Start Your Machine

Run the startup script which automates everything:

```bash
~/devops-platform/start.sh
```

This script:
1. Fixes Docker socket permissions
2. Copies labs to the API folder
3. Kills anything on port 8080
4. Starts the API with nohup
5. Verifies the API health
6. Starts the Cloudflare tunnel
7. Waits for the tunnel URL
8. Updates the portal with the new URL
9. Pushes to GitHub automatically
10. Prints the live platform URLs

If the script does not exist, create it:

```bash
#!/bin/bash
set -e
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}Starting DevOps Academy Platform...${NC}"

# Fix Docker permissions
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

cd ~/devops-platform
rm -rf api/labs && cp -r labs api/labs
echo -e "${GREEN}Labs synced${NC}"

# Stop existing services
sudo kill -9 $(sudo lsof -t -i:8080) 2>/dev/null || true
pkill cloudflared 2>/dev/null || true
sleep 1

# Start API
cd api
nohup python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 > /tmp/api.log 2>&1 &
API_PID=$!
echo -e "${GREEN}API Live (PID $API_PID)${NC}"

# Start Tunnel
nohup cloudflared tunnel --url http://localhost:8080 > /tmp/tunnel.log 2>&1 &
TUNNEL_PID=$!

echo "Negotiating secure tunnel..."
for i in $(seq 1 30); do
    TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/tunnel.log 2>/dev/null | head -1)
    if [ -n "$TUNNEL_URL" ]; then break; fi
    sleep 1
done

if [ -z "$TUNNEL_URL" ]; then
    echo "Tunnel failed. Check /tmp/tunnel.log"
    exit 1
fi

echo -e "${GREEN}Public URL: $TUNNEL_URL${NC}"

# Update Portal and Sync to GitHub
cd ~/devops-platform
OLD_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' portal/index.html | head -1)
if [ -n "$OLD_URL" ] && [ "$OLD_URL" != "$TUNNEL_URL" ]; then
    sed -i "s|$OLD_URL|$TUNNEL_URL|g" portal/index.html
    git add portal/index.html
    git commit -m "Auto-sync tunnel: $TUNNEL_URL"
    # Note: If push fails due to divergence, run: git pull --rebase origin main && git push
    git push origin main || (git pull --rebase origin main && git push)
    echo -e "${GREEN}Portal Synced to Live Web${NC}"
fi

echo -e "${CYAN}--- ACADEMY IS LIVE ---${NC}"
echo -e "Portal: https://YOUR_USERNAME.github.io/devops-platform"
```

chmod +x ~/devops-platform/start.sh
echo "Startup script created"
```

---

## 20. Step 15 — Offline Classroom Node

Turns any Ubuntu machine into a standalone server students connect to
over WiFi — no internet needed during sessions.

```bash
curl -s https://raw.githubusercontent.com/YOUR_USERNAME/devops-platform/main/offline-node/install.sh | bash
```

The installer:
1. Installs Docker, Nginx, Git, Python3
2. Clones your platform repository
3. Copies labs into the correct location
4. Starts the API as a system service (survives reboots)
5. Configures Nginx to serve the portal
6. Prints the local IP for students

Set up a WiFi hotspot on the node machine:
- Ubuntu → network icon → Wi-Fi Settings → menu → Turn On Wi-Fi Hotspot
- Share the hotspot name and password with students
- Students open `http://LOCAL_IP` in their browser

---

## 21. Step 16 — Oracle Cloud (Permanent 24/7)

Oracle Cloud Always Free gives you 4 CPUs and 24GB RAM running 24/7
at zero cost. This eliminates the tunnel URL problem permanently.

**Requires:** One-time credit card verification ($1 charged and refunded).

### Get a free virtual card in Africa

**Grey.co** (Nigeria, Ghana, Kenya, Rwanda and more):
1. Download Grey app → sign up with phone and ID
2. Cards → Create virtual card → load $0
3. Copy card number, expiry, CVV

**Chipper Cash** (available across Africa):
1. Download → sign up → request virtual Visa/Mastercard

### Create Oracle Cloud account

1. **https://cloud.oracle.com** → Start for free
2. Choose home region — **cannot change later**:
   - Best for Africa: **UK South (London)** — `lhr`
3. Enter virtual card when asked
4. Complete phone verification

### Create the VM

In Oracle Console:
1. Menu → Compute → Instances → Create instance
2. Name: `devops-platform-server`
3. Image: Canonical Ubuntu 22.04 Minimal
4. Shape: Ampere → VM.Standard.A1.Flex → **4 OCPUs, 24GB RAM**
5. SSH Keys: Generate → download both keys
6. Boot volume: 100 GB
7. Create

### Open firewall ports

Networking → VCN → Security Lists → Default → Add Ingress Rules:

| Source CIDR | Protocol | Port |
|---|---|---|
| 0.0.0.0/0 | TCP | 22 |
| 0.0.0.0/0 | TCP | 80 |
| 0.0.0.0/0 | TCP | 443 |
| 0.0.0.0/0 | TCP | 8080 |

### Connect and deploy

```bash
chmod 400 ~/Downloads/ssh-key-*.key
ssh -i ~/Downloads/ssh-key-*.key ubuntu@YOUR_ORACLE_IP

# On the Oracle server:
curl -s https://raw.githubusercontent.com/YOUR_USERNAME/devops-platform/main/offline-node/install.sh | bash
```

### Update portal to use Oracle IP (permanent)

```bash
cd ~/devops-platform

sed -i "s|https://.*trycloudflare\.com|http://YOUR_ORACLE_IP:8080|g" \
  portal/index.html

git add . && git commit -m "Switch to Oracle permanent IP" && git push
```

No more tunnel URL changes. The platform is live 24/7.

---

## 22. Step 17 — Permanent Background Services (systemd)

By default, `start.sh` runs in your current terminal. If you close your laptop, the terminal may disconnect and stop the platform. To make the platform run permanently in the background (even after a reboot), use **systemd**.

### 1. Install the service files
Copy the provided `.service` files from your project folder to the system directory:

```bash
# From project root:
sudo cp ~/devops-platform/*.service /etc/systemd/system/
```

### 2. Enable and start the services
This tells Linux to start the API and Tunnel automatically on boot.

```bash
# Reload systemd to detect new files
sudo systemctl daemon-reload

# Start and enable the API
sudo systemctl enable --now devops-api

# Start and enable the Tunnel (it depends on the API)
sudo systemctl enable --now devops-tunnel
```

### 3. Verify status
```bash
sudo systemctl status devops-api
sudo systemctl status devops-tunnel
```

> [!TIP]
> When running as a service, the tunnel uses `tunnel-with-update.sh` to automatically update your [index.html](portal/index.html) and push it to GitHub whenever the URL changes. You don't have to do anything!

---

## 22. Adding New Labs

```bash
cd ~/devops-platform

# Create lab folder and metadata
mkdir -p labs/phase-1-linux-lab2

cat > labs/phase-1-linux-lab2/meta.json << 'EOF'
{
  "id": "phase-1-linux-lab2",
  "title": "Users, processes and system information",
  "phase": 1,
  "phase_name": "Linux fundamentals",
  "difficulty": "beginner",
  "duration_minutes": 45,
  "description": "Manage users, monitor processes and read system information."
}
EOF

# Write the lab content
nano labs/phase-1-linux-lab2/LAB.md

# Copy labs and restart API
rm -rf api/labs && cp -r labs api/labs

# Push to GitHub
git add .
git commit -m "Add new lab: users and processes"
git push origin main

# Restart API to load the new lab
sudo kill -9 $(sudo lsof -t -i:8080)
cd ~/devops-platform/api
nohup python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 \
  > /tmp/api.log 2>&1 &
```

---

## 23. Managing Students

```bash
# View all active sandboxes
docker ps --filter "label=student"

# Count active sandboxes
docker ps --filter "label=student" | wc -l

# Stop a student's sandbox
docker stop CONTAINER_NAME && docker rm CONTAINER_NAME

# Stop ALL sandboxes
docker stop $(docker ps -q --filter "label=student") 2>/dev/null
docker rm $(docker ps -aq --filter "label=student") 2>/dev/null

# Check server resources
free -h    # memory
df -h      # disk
```

### Sandbox limits per student

| Resource | Limit | Change in |
|---|---|---|
| RAM | 512MB | `api/main.py` — `"--memory","512m"` |
| CPU | 0.5 cores | `api/main.py` — `"--cpus","0.5"` |

---

## 24. Updating the Platform

Any change — new lab, UI fix, API update:

```bash
cd ~/devops-platform

# Make your change
nano portal/index.html        # portal changes
nano api/main.py              # API changes
nano labs/phase-X/LAB.md     # lab content changes

# If you changed labs, copy them
rm -rf api/labs && cp -r labs api/labs

# Push — GitHub Actions redeploys portal automatically
git add .
git commit -m "describe your change"
git push origin main

# If you changed the API, restart it
sudo kill -9 $(sudo lsof -t -i:8080) 2>/dev/null
cd api && nohup python3 -m uvicorn main:app \
  --host 0.0.0.0 --port 8080 > /tmp/api.log 2>&1 &
```

---

## 25. Troubleshooting

### "Labs coming soon" on the portal

```bash
# Wrong directory — always run from project root
cd ~/devops-platform
rm -rf api/labs
cp -r labs api/labs
ls api/labs/   # must show 10 phase folders

# Restart API
sudo kill -9 $(sudo lsof -t -i:8080)
cd api && nohup python3 -m uvicorn main:app \
  --host 0.0.0.0 --port 8080 > /tmp/api.log 2>&1 &
```

---

### Portal cannot reach API — ERR_NAME_NOT_RESOLVED

The tunnel URL changed. Update it:

```bash
# Restart the tunnel and get new URL
pkill cloudflared
nohup cloudflared tunnel --url http://localhost:8080 > /tmp/tunnel.log 2>&1 &
sleep 10
NEW_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/tunnel.log | head -1)
echo "New URL: $NEW_URL"

cd ~/devops-platform
OLD_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' portal/index.html | head -1)
sed -i "s|$OLD_URL|$NEW_URL|g" portal/index.html
git add . && git commit -m "Update tunnel URL" && git push
```

---

### ERR_CONNECTION_TIMED_OUT on tunnel

The tunnel process died. Restart it:

```bash
pkill cloudflared 2>/dev/null || true
nohup cloudflared tunnel --url http://localhost:8080 > /tmp/tunnel.log 2>&1 &
sleep 10
grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/tunnel.log | head -1
# Then update portal URL as above
```

---

### Docker permission denied

```bash
sudo chmod 666 /var/run/docker.sock
docker run hello-world   # test
```

---

### Git "Divergent Branches" (Push Rejected)

If `start.sh` or a manual push fails with an error about "rejected" or "divergent branches," run:

```bash
cd ~/devops-platform
git fetch origin
git reset --hard origin/main
```

> [!CAUTION]
> This will overwrite your local changes with the latest version from GitHub. It is the fastest way to get the platform running again if out of sync.

---

## 25. Master Platform Maintenance (`fix-everything.sh`)

Administering a complex full-stack platform can be exhausting. To make maintenance effortless, use the **Master Restoration Script**. This one-click tool handles state-sync, visual rebuilding, and service restarts in a single command.

### When to use it
- After a machine reboot or power outage.
- If the "Stop sandbox" button is missing despite containers running.
- If the terminal prompt colors are white instead of green/blue.
- If the UI and Backend feel "Desynchronized."

### How to use it
```bash
# 1. Pull the absolute latest stable logic
cd ~/devops-platform
git fetch origin main && git reset --hard origin/main

# 2. Run the Master Fix
chmod +x fix-everything.sh
./fix-everything.sh
```

---

## 26. Technical Recovery & Troubleshooting

### Terminal is White (Missing Technicolor)
The sandbox image (`devops-sandbox:latest`) needs to be rebuilt to apply the `/etc/profile.d/99-colors.sh` enforcement logic.
```bash
cd ~/devops-platform/sandbox
sudo docker build --no-cache -t devops-sandbox:latest .
sudo systemctl restart devops-api
```

### Timer keeps resetting to 45:00
Fixed in v3.0. This was caused by UI refreshes during in-memory sync. Ensure your `portal/index.html` is up to date and your API is running the persistent `sandboxes.json` logic.

### 404 Error: /terminal/CONTAINER_NAME
This happens if the API lost track of a running container. Use Step 25 to "Nuke & Sync."

```bash
# Check debug endpoint
curl -s http://localhost:8080/debug/terminal/CONTAINER_NAME | python3 -m json.tool
```

- `port: null` — container not running, start sandbox first
- `ttyd: "FAIL..."` — ttyd not ready, wait 3 seconds and retry

---

### Sandbox fails — image not found

```bash
cd ~/devops-platform/sandbox
docker build -t devops-sandbox:latest .
```

---

### Port 8080 already in use

```bash
sudo lsof -i :8080
sudo kill -9 $(sudo lsof -t -i:8080)
```

---

### WebSocket closed with code 1006

The subprotocol header was not forwarded. Make sure `api/main.py` has:

```python
subprotocols = websocket.headers.get("sec-websocket-protocol","")
proto = subprotocols.split(",")[0].strip() if subprotocols else None
if proto: await websocket.accept(subprotocol=proto)
```

If `main.py` is missing or broken, rewrite it using Step 9.

---

### Git push asks for password every time

```bash
git config --global credential.helper store
# Push once, enter token — remembered forever after
```

---

### GitHub Actions red X

1. Repo → Actions → failed run → failed job → read logs

| Error | Fix |
|---|---|
| Pages deployment failed | Settings → Pages → Source: GitHub Actions |
| Permission denied to github-actions | Settings → Actions → Workflow permissions → Read and write |

---

## 26. Platform Uptime Reference

| Scenario | Portal | Labs (read) | Login | Terminals |
|---|---|---|---|---|
| Machine on, tunnel running | Live | Live | Live | Available |
| Machine off | Live | Live | Dead | Dead |
| Tunnel restarted (URL not updated) | Live | Live | Dead | Dead |
| Internet down, classroom node | Cached | Cached | Live on LAN | Available on LAN |
| Oracle Cloud server | Live | Live | Live 24/7 | Available 24/7 |

---

## 27. Glossary

| Term | Meaning |
|---|---|
| **API** | Backend server — handles login, labs, sandboxes (port 8080) |
| **Cloudflare Tunnel** | Free tool giving your machine a public HTTPS URL |
| **cloudflared** | The software running the Cloudflare Tunnel |
| **Docker** | Runs isolated containers — used for student sandboxes |
| **devops-sandbox** | The Docker image all student terminals run inside |
| **get_port()** | API function that finds a container's ttyd port via docker port |
| **GitHub Actions** | Runs deploy pipeline on every git push — free |
| **GitHub Pages** | Free static hosting for the student portal |
| **nohup** | Runs a process that survives WSL terminal idle/close |
| **Oracle Always Free** | Oracle Cloud free tier — 4 CPUs, 24GB RAM, 24/7 |
| **Personal Access Token** | GitHub token used instead of password for git push |
| **SANDBOX_REGISTRY** | Persistent file-based store (`sandboxes.json`) — survives API restarts |
| **ttyd** | Tool serving a Linux terminal as a webpage on a random port |
| **trycloudflare.com** | Domain Cloudflare assigns to free quick tunnels |
| **WebSocket** | Protocol for real-time terminal communication |
| **WSL** | Windows Subsystem for Linux — runs Linux inside Windows |

---

## 28. Quick Reference

```bash
# ── Master Restoration (One-Click Fix) ──────────────────
./fix-everything.sh

# ── Service Management (Professional) ──────────────────────
sudo systemctl status devops-api devops-tunnel
sudo systemctl restart devops-api devops-tunnel
journalctl -u devops-api -f  # Watch API logs
journalctl -u devops-tunnel -f # Watch Tunnel logs

# ── Manual start ─────────────────────────────────────────────
sudo chmod 666 /var/run/docker.sock
cd ~/devops-platform && rm -rf api/labs && cp -r labs api/labs
sudo kill -9 $(sudo lsof -t -i:8080) 2>/dev/null || true
cd api && nohup python3 -m uvicorn main:app \
  --host 0.0.0.0 --port 8080 > /tmp/api.log 2>&1 &
nohup cloudflared tunnel --url http://localhost:8080 > /tmp/tunnel.log 2>&1 &
sleep 10 && grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/tunnel.log | head -1

# ── Update tunnel URL ─────────────────────────────────────────
NEW="https://NEW-WORDS.trycloudflare.com"
OLD=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' \
  ~/devops-platform/portal/index.html | head -1)
sed -i "s|$OLD|$NEW|g" ~/devops-platform/portal/index.html
cd ~/devops-platform && git add . && git commit -m "Update tunnel" && git push

# ── Test API ──────────────────────────────────────────────────
curl -s http://localhost:8080/health
curl -s http://localhost:8080/labs | python3 -m json.tool

# ── Start a sandbox (test) ────────────────────────────────────
curl -X POST http://localhost:8080/sandbox/start \
  -H "Content-Type: application/json" \
  -d '{"student_id":"test","lab_id":"phase-1-linux"}' \
  | python3 -m json.tool

# ── Debug terminal ────────────────────────────────────────────
curl -s http://localhost:8080/debug/terminal/CONTAINER_NAME \
  | python3 -m json.tool

# ── Watch logs ───────────────────────────────────────────────
tail -f /tmp/api.log
tail -f /tmp/tunnel.log

# ── View sandboxes ───────────────────────────────────────────
docker ps --filter "label=student"

# ── Stop all sandboxes ───────────────────────────────────────
docker stop $(docker ps -q --filter "label=student") 2>/dev/null
docker rm $(docker ps -aq --filter "label=student") 2>/dev/null

# ── Push any change ───────────────────────────────────────────
cd ~/devops-platform && git add . && git commit -m "change" && git push

# ── Force portal redeploy ─────────────────────────────────────
cd ~/devops-platform && git commit --allow-empty -m "redeploy" && git push

# ── SSH into Oracle server ────────────────────────────────────
ssh -i ~/ssh-key.key ubuntu@YOUR_ORACLE_IP
```

---

> **Oracle Cloud reminder:** Get a free virtual Mastercard from Grey.co
> or Chipper Cash (free, available across Africa). Oracle charges $1 to
> verify and refunds immediately. You get 4 CPUs and 24GB RAM 24/7 for free
> — no more tunnel URL changes ever.

---

*DevOps Learning Platform — built to make quality DevOps education
free and accessible for everyone.*
