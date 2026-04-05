# COMPLETE DEVOPS PLATFORM GUIDE

---
<!-- File: README.md -->
# DevOps Learning Platform

Free, offline-capable, hands-on DevOps training.
Built for students with limited internet access and no expensive cloud accounts.

## Live platform
- Portal: https://florayuyuun123.github.io/devops-platform

## Curriculum — 10 phases
1. Linux fundamentals
2. Networking & security
3. Git & version control
4. Docker & containers
5. CI/CD pipelines
6. Ansible automation
7. Kubernetes
8. Terraform / IaC
9. Monitoring & observability
10. Capstone project

## Deploy your own copy
```bash
git clone https://github.com/florayuyuun123/devops-platform
cd devops-platform
# Follow SETUP.md
```

## Offline classroom node
```bash
curl -s https://raw.githubusercontent.com/florayuyuun123/devops-platform/main/offline-node/install.sh | bash
```

## Cost: $0
GitHub Pages (portal) + Local API over Tunnel + optional offline node.


---
<!-- File: SETUP.md -->
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


---
<!-- File: DEVOPS-PLATFORM-DOCUMENTATION.md -->
# DevOps Learning Platform — Complete Setup & Operations Guide

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
22. [Adding New Labs](#22-adding-new-labs)
23. [Managing Students](#23-managing-students)
24. [Updating the Platform](#24-updating-the-platform)
25. [Troubleshooting](#25-troubleshooting)
26. [Platform Uptime Reference](#26-platform-uptime-reference)
27. [Glossary](#27-glossary)
28. [Quick Reference](#28-quick-reference)

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

- The tunnel only exposes **one port (8080)**. All terminal traffic is
  proxied through the API — never directly on the container port.
- The API rewrites WebSocket URLs in the terminal HTML so the browser
  connects to the tunnel, not to localhost.
- The `SANDBOX_REGISTRY` dict loses data when the API restarts.
  The `get_port()` function always calls `docker port` directly as the
  primary method — never relies on the registry alone.
- Docker socket permissions reset on reboot in WSL.
  Always run `sudo chmod 666 /var/run/docker.sock` on startup.

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

```bash
python3 - << 'END'
import os
path = os.path.expanduser('~/devops-platform/api/main.py')
lines = []
lines.append('import os, asyncio, subprocess, json, time, secrets, httpx')
lines.append('from fastapi import FastAPI, HTTPException, Request, WebSocket')
lines.append('from fastapi.middleware.cors import CORSMiddleware')
lines.append('from fastapi.responses import Response')
lines.append('from pydantic import BaseModel')
lines.append('')
lines.append('app = FastAPI(title="DevOps Learning Platform", version="1.0.0")')
lines.append('app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])')
lines.append('')
lines.append('SESSIONS, SANDBOX_REGISTRY = {}, {}')
lines.append('LABS_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "labs")')
lines.append('')
lines.append('class AuthRequest(BaseModel):')
lines.append('    username: str')
lines.append('    password: str')
lines.append('')
lines.append('class SandboxRequest(BaseModel):')
lines.append('    student_id: str')
lines.append('    lab_id: str')
lines.append('')
lines.append('class ProgressUpdate(BaseModel):')
lines.append('    student_id: str')
lines.append('    lab_id: str')
lines.append('    task_id: str')
lines.append('    completed: bool')
lines.append('')
lines.append('def get_port(name):')
lines.append('    r = subprocess.run(["docker","port",name,"7681"], capture_output=True, text=True)')
lines.append('    if r.returncode == 0 and r.stdout.strip():')
lines.append('        try: return int(r.stdout.strip().split("\\n")[0].split(":")[-1])')
lines.append('        except: pass')
lines.append('    return (SANDBOX_REGISTRY.get(name) or {}).get("port")')
lines.append('')
lines.append('@app.post("/auth/login")')
lines.append('@app.post("/auth/register")')
lines.append('def login(req: AuthRequest):')
lines.append('    token = secrets.token_hex(32)')
lines.append('    SESSIONS[token] = {"username": req.username, "created": int(time.time())}')
lines.append('    return {"token": token, "username": req.username}')
lines.append('')
lines.append('@app.get("/health")')
lines.append('def health():')
lines.append('    return {"status":"ok","platform":"DevOps Learning Platform","version":"1.0.0","labs_found":os.path.exists(LABS_PATH)}')
lines.append('')
lines.append('@app.get("/labs")')
lines.append('def get_labs():')
lines.append('    labs = []')
lines.append('    if os.path.exists(LABS_PATH):')
lines.append('        for d in sorted(os.listdir(LABS_PATH), key=lambda x: int(x.split("-")[1]) if len(x.split("-"))>1 and x.split("-")[1].isdigit() else 99):')
lines.append('            mf = os.path.join(LABS_PATH, d, "meta.json")')
lines.append('            if os.path.exists(mf):')
lines.append('                labs.append(json.load(open(mf)))')
lines.append('    return {"labs": labs, "total": len(labs)}')
lines.append('')
lines.append('@app.get("/labs/{lab_id}")')
lines.append('def get_lab(lab_id: str):')
lines.append('    if os.path.exists(LABS_PATH):')
lines.append('        for d in sorted(os.listdir(LABS_PATH)):')
lines.append('            mf = os.path.join(LABS_PATH, d, "meta.json")')
lines.append('            if os.path.exists(mf):')
lines.append('                meta = json.load(open(mf))')
lines.append('                if meta.get("id") == lab_id:')
lines.append('                    lf = os.path.join(LABS_PATH, d, "LAB.md")')
lines.append('                    return {**meta, "content": open(lf).read() if os.path.exists(lf) else ""}')
lines.append('    raise HTTPException(status_code=404, detail="Lab not found")')
lines.append('')
lines.append('@app.post("/sandbox/start")')
lines.append('def start_sandbox(req: SandboxRequest):')
lines.append('    cn = "sb_{}_{}".format(req.student_id, req.lab_id).replace("-","_")')
lines.append('    if subprocess.run(["docker","ps","-q","-f","name={}".format(cn)], capture_output=True, text=True).stdout.strip():')
lines.append('        return {"status":"already_running","container":cn,"port":get_port(cn),"terminal_path":"/terminal/{}".format(cn)}')
lines.append('    port = 7700 + (abs(hash(cn)) % 200)')
lines.append('    lp = os.path.join(LABS_PATH, req.lab_id)')
lines.append('    cmd = ["docker","run","-d","--name",cn,"--memory","512m","--cpus","0.5","-p","{}:7681".format(port),"--label","student={}".format(req.student_id),"--label","lab={}".format(req.lab_id)]')
lines.append('    if os.path.exists(lp): cmd += ["-v","{}:/home/student/lab:ro".format(lp)]')
lines.append('    cmd.append("devops-sandbox:latest")')
lines.append('    r = subprocess.run(cmd, capture_output=True, text=True)')
lines.append('    if r.returncode != 0: raise HTTPException(status_code=500, detail=r.stderr)')
lines.append('    SANDBOX_REGISTRY[cn] = {"student_id":req.student_id,"lab_id":req.lab_id,"port":port,"started":int(time.time())}')
lines.append('    return {"status":"started","container":cn,"port":port,"terminal_path":"/terminal/{}".format(cn)}')
lines.append('')
lines.append('@app.delete("/sandbox/{container_name}")')
lines.append('def stop_sandbox(container_name: str):')
lines.append('    subprocess.run(["docker","stop",container_name], capture_output=True)')
lines.append('    subprocess.run(["docker","rm",container_name], capture_output=True)')
lines.append('    SANDBOX_REGISTRY.pop(container_name, None)')
lines.append('    return {"status":"stopped"}')
lines.append('')
lines.append('@app.get("/sandbox/active")')
lines.append('def list_active():')
lines.append('    r = subprocess.run(["docker","ps","--format","{{.Names}}","--filter","label=student"], capture_output=True, text=True)')
lines.append('    names = [n for n in r.stdout.strip().split("\\n") if n]')
lines.append('    return {"sandboxes":[{"name":n} for n in names],"count":len(names)}')
lines.append('')
lines.append('@app.post("/progress")')
lines.append('def update_progress(u: ProgressUpdate):')
lines.append('    k = "{}_{}".format(u.student_id, u.lab_id)')
lines.append('    SESSIONS.setdefault(k, {})[u.task_id] = u.completed')
lines.append('    return {"status":"saved"}')
lines.append('')
lines.append('@app.get("/progress/{student_id}")')
lines.append('def get_progress(student_id: str):')
lines.append('    return {"student_id":student_id,"progress":{k:v for k,v in SESSIONS.items() if k.startswith(student_id)}}')
lines.append('')
lines.append('@app.get("/debug/terminal/{container_name}")')
lines.append('async def debug_terminal(container_name: str):')
lines.append('    port = get_port(container_name)')
lines.append('    test = None')
lines.append('    if port:')
lines.append('        try:')
lines.append('            async with httpx.AsyncClient(timeout=5) as c:')
lines.append('                r = await c.get("http://localhost:{}/".format(port))')
lines.append('                test = "OK {}".format(r.status_code)')
lines.append('        except Exception as e: test = "FAIL {}".format(e)')
lines.append('    return {"container":container_name,"port":port,"ttyd":test}')
lines.append('')
lines.append('@app.get("/terminal/{container_name}")')
lines.append('async def terminal_page(container_name: str):')
lines.append('    port = get_port(container_name)')
lines.append('    if not port: raise HTTPException(status_code=404, detail="Container not found")')
lines.append('    try:')
lines.append('        async with httpx.AsyncClient(timeout=10) as c:')
lines.append('            resp = await c.get("http://localhost:{}/".format(port))')
lines.append('            body = resp.content')
lines.append('            body = body.replace(b\'src="/\', \'src="/terminal/{}/\'.format(container_name).encode())')
lines.append('            body = body.replace(b\'href="/\', \'href="/terminal/{}/\'.format(container_name).encode())')
lines.append('            import re')
lines.append('            body = re.sub(b\'http://localhost:[0-9]+\', b\'\', body)')
lines.append('            ws_fix = b\'<script>(function(){var _W=window.WebSocket;window.WebSocket=function(u,p){if(u.indexOf("localhost")!==-1||u.indexOf("127.0.0.1")!==-1){var l=window.location;var pr=l.protocol==="https:"?"wss:":"ws:";u=pr+"//"+l.host+"/terminal/\' + container_name.encode() + b\'/ws";}return p?new _W(u,p):new _W(u);};window.WebSocket.prototype=_W.prototype;window.WebSocket.CONNECTING=_W.CONNECTING;window.WebSocket.OPEN=_W.OPEN;window.WebSocket.CLOSING=_W.CLOSING;window.WebSocket.CLOSED=_W.CLOSED;})();</script>\'')
lines.append('            body = body.replace(b\'<head>\', b\'<head>\' + ws_fix)')
lines.append('            return Response(content=body, media_type=resp.headers.get("content-type","text/html"))')
lines.append('    except Exception as e: raise HTTPException(status_code=502, detail="Port {}: {}".format(port, str(e)))')
lines.append('')
lines.append('@app.get("/terminal/{container_name}/{path:path}")')
lines.append('async def terminal_asset(container_name: str, path: str, request: Request):')
lines.append('    port = get_port(container_name)')
lines.append('    if not port: raise HTTPException(status_code=404, detail="Container not found")')
lines.append('    q = request.url.query')
lines.append('    url = "http://localhost:{}/{}{}".format(port, path, "?"+q if q else "")')
lines.append('    try:')
lines.append('        async with httpx.AsyncClient(timeout=10) as c:')
lines.append('            r = await c.get(url)')
lines.append('            return Response(content=r.content, status_code=r.status_code, media_type=r.headers.get("content-type"))')
lines.append('    except Exception as e: raise HTTPException(status_code=502, detail=str(e))')
lines.append('')
lines.append('@app.websocket("/terminal/{container_name}/ws")')
lines.append('async def terminal_ws(websocket: WebSocket, container_name: str):')
lines.append('    port = get_port(container_name)')
lines.append('    if not port:')
lines.append('        await websocket.close(code=1008)')
lines.append('        return')
lines.append('    subprotocols = websocket.headers.get("sec-websocket-protocol","")')
lines.append('    proto = subprotocols.split(",")[0].strip() if subprotocols else None')
lines.append('    if proto: await websocket.accept(subprotocol=proto)')
lines.append('    else: await websocket.accept()')
lines.append('    try:')
lines.append('        import websockets as wsl')
lines.append('        kw = {"subprotocols":[proto]} if proto else {}')
lines.append('        async with wsl.connect("ws://localhost:{}/ws".format(port), **kw) as backend:')
lines.append('            async def c2b():')
lines.append('                try:')
lines.append('                    while True:')
lines.append('                        try: d = await websocket.receive_bytes()')
lines.append('                        except: d = (await websocket.receive_text()).encode()')
lines.append('                        await backend.send(d)')
lines.append('                except: pass')
lines.append('            async def b2c():')
lines.append('                try:')
lines.append('                    while True:')
lines.append('                        d = await backend.recv()')
lines.append('                        if isinstance(d,bytes): await websocket.send_bytes(d)')
lines.append('                        else: await websocket.send_text(d)')
lines.append('                except: pass')
lines.append('            await asyncio.gather(c2b(), b2c())')
lines.append('    except Exception as e:')
lines.append('        try: await websocket.send_text("Error: {}".format(e))')
lines.append('        except: pass')
lines.append('    finally:')
lines.append('        try: await websocket.close()')
lines.append('        except: pass')
with open(path, 'w') as f:
    f.write('\n'.join(lines))
print("main.py written: {} lines".format(len(lines)))
END
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
cat > ~/devops-platform/start.sh << 'STARTEOF'
#!/bin/bash
set -e
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}Starting DevOps Learning Platform...${NC}"

sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

cd ~/devops-platform
rm -rf api/labs && cp -r labs api/labs
echo -e "${GREEN}Labs copied${NC}"

sudo kill -9 $(sudo lsof -t -i:8080) 2>/dev/null || true
pkill cloudflared 2>/dev/null || true
sleep 2

cd ~/devops-platform/api
nohup python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 > /tmp/api.log 2>&1 &
API_PID=$!
echo -e "${GREEN}API started (PID $API_PID)${NC}"
sleep 4

if curl -s http://localhost:8080/health > /dev/null; then
    echo -e "${GREEN}API is healthy${NC}"
else
    echo "API failed - check /tmp/api.log"
    exit 1
fi

nohup cloudflared tunnel --url http://localhost:8080 > /tmp/tunnel.log 2>&1 &
TUNNEL_PID=$!
echo -e "${GREEN}Tunnel started (PID $TUNNEL_PID)${NC}"

echo "Waiting for tunnel URL..."
for i in $(seq 1 30); do
    TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/tunnel.log 2>/dev/null | head -1)
    if [ -n "$TUNNEL_URL" ]; then break; fi
    sleep 1
done

if [ -z "$TUNNEL_URL" ]; then
    echo "Tunnel URL not found - check /tmp/tunnel.log"
    exit 1
fi

echo -e "${GREEN}Tunnel: $TUNNEL_URL${NC}"

cd ~/devops-platform
OLD_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' portal/index.html | head -1)
if [ -n "$OLD_URL" ] && [ "$OLD_URL" != "$TUNNEL_URL" ]; then
    sed -i "s|$OLD_URL|$TUNNEL_URL|g" portal/index.html
    git add portal/index.html
    git commit -m "Auto-update tunnel URL: $TUNNEL_URL"
    git push origin main
    echo -e "${GREEN}Portal updated and pushed${NC}"
else
    echo -e "${GREEN}Tunnel URL unchanged${NC}"
fi

echo ""
echo -e "${CYAN}Platform is live!${NC}"
echo -e "  Portal: https://florayuyuun123.github.io/devops-platform"
echo -e "  API:    $TUNNEL_URL/health"
echo ""
echo "Logs: tail -f /tmp/api.log  |  tail -f /tmp/tunnel.log"
echo "Stop: kill $API_PID $TUNNEL_PID"
STARTEOF

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

### API returns 500 on /terminal/

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
| **SANDBOX_REGISTRY** | In-memory dict — clears on API restart, use docker port as backup |
| **ttyd** | Tool serving a Linux terminal as a webpage on a random port |
| **trycloudflare.com** | Domain Cloudflare assigns to free quick tunnels |
| **WebSocket** | Protocol for real-time terminal communication |
| **WSL** | Windows Subsystem for Linux — runs Linux inside Windows |

---

## 28. Quick Reference

```bash
# ── Start everything (recommended) ──────────────────────────
~/devops-platform/start.sh

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


---
# LAB GUIDES

---
<!-- File: C:\Users\ADMIN\flo-tech\aws-devops\devops-platform\labs\phase-1-linux\LAB.md -->
# Linux file system & permissions

## Why this matters
Every server you manage runs Linux. This is tested in every DevOps interview.

---

## Task 1 — Where are you?
```bash
pwd          # print working directory
ls -la       # long list including hidden files
```
The first character of each line: `d` = directory, `-` = file, `l` = symlink.

## Task 2 — Explore the system
```bash
cd /etc && ls        # system config
cd /var/log && ls    # log files
cd /usr/bin && ls    # installed binaries
cd ~                 # back home
```

## Task 3 — Create and manage files
```bash
mkdir ~/workspace && cd ~/workspace
touch server.conf app.py deploy.sh
echo "PORT=8080" > server.conf
echo "HOST=0.0.0.0" >> server.conf
cat server.conf
cp server.conf server.conf.bak
mv deploy.sh release.sh
rm server.conf.bak
ls -la
```

## Task 4 — Permissions
```bash
chmod 600 server.conf   # secrets  — owner read/write only
chmod 755 release.sh    # scripts  — owner rwx, others r-x
chmod 644 app.py        # code     — owner rw,  others r
ls -la
```
**Numbers:** 4=read 2=write 1=execute. 755 = rwxr-xr-x. 600 = rw-------.

## Task 5 — Search
```bash
grep "PORT" server.conf
find /etc -name "*.conf" 2>/dev/null | head -10
```

## Challenge
Set `server.conf` to `400` (read-only, even for owner). Then try to edit it. What happens?


---
<!-- File: C:\Users\ADMIN\flo-tech\aws-devops\devops-platform\labs\phase-2-networking\LAB.md -->
# Networking, SSH & firewalls

## Why this matters
You cannot debug production issues without understanding networking.
This comes up in every DevOps and SRE interview.

---

## Task 1 — Inspect your network
```bash
ip addr show          # your IP addresses
ip route show         # routing table
cat /etc/resolv.conf  # DNS servers
```

## Task 2 — Test connectivity
```bash
ping -c 4 8.8.8.8          # ping Google DNS
ping -c 4 google.com       # tests DNS resolution + connectivity
traceroute google.com      # trace the network path
```

## Task 3 — DNS lookups
```bash
nslookup google.com        # basic DNS query
dig google.com             # detailed DNS query
dig google.com MX          # mail records
dig @8.8.8.8 google.com    # query specific DNS server
```

## Task 4 — Ports and services
```bash
ss -tlnp                   # show listening TCP ports
ss -ulnp                   # show listening UDP ports
curl -I https://google.com # HTTP headers — tests port 443
nc -zv google.com 443      # test if port 443 is open
```

## Task 5 — SSH basics
```bash
# Generate an SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub   # this is your PUBLIC key — safe to share
# Private key stays on your machine — NEVER share it
```

## Task 6 — Firewall rules (ufw)
```bash
sudo ufw status
sudo ufw allow 22/tcp       # allow SSH
sudo ufw allow 80/tcp       # allow HTTP
sudo ufw enable
sudo ufw status verbose
```

## Challenge
Find out what port `nginx` listens on by default, then check if anything
is listening on that port on your sandbox right now.


---
<!-- File: C:\Users\ADMIN\flo-tech\aws-devops\devops-platform\labs\phase-3-git\LAB.md -->
# Git version control & GitHub flow

## Why this matters
Every company uses Git. You will use it every single day as a DevOps engineer.

---

## Task 1 — Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --list
```

## Task 2 — Create a repository
```bash
mkdir my-app && cd my-app
git init
echo "# My App" > README.md
echo "PORT=8080" > .env
echo ".env" > .gitignore     # never commit secrets
git status
git add README.md .gitignore
git commit -m "Initial commit"
git log --oneline
```

## Task 3 — Branching (the daily workflow)
```bash
git checkout -b feature/add-config    # create and switch to new branch
echo "DEBUG=false" >> README.md
git add .
git commit -m "Add debug config"
git checkout main                     # go back to main
git merge feature/add-config          # merge the feature in
git branch -d feature/add-config      # clean up
git log --oneline --graph
```

## Task 4 — Undo mistakes
```bash
echo "oops" > mistake.txt
git add mistake.txt
git reset HEAD mistake.txt            # unstage the file
git checkout -- mistake.txt 2>/dev/null || true  # discard changes
git stash                             # temporarily save work
git stash pop                         # restore saved work
```

## Task 5 — Read history
```bash
git log --oneline --graph --all
git diff HEAD~1 HEAD                  # what changed in last commit
git blame README.md                   # who changed each line
```

## Challenge
Create a branch called `fix/typo`, make a change, commit it,
then merge it back into `main` and delete the branch.
Paste your `git log --oneline --graph` output somewhere.


---
<!-- File: C:\Users\ADMIN\flo-tech\aws-devops\devops-platform\labs\phase-4-docker\LAB.md -->
# Docker containers & images

## Why this matters
Docker is the entry point to modern DevOps. If you know Docker well,
you are employable. Listed in 9 out of 10 DevOps job postings.

---

## Task 1 — Your first container
```bash
docker run hello-world                    # confirm Docker works
docker run -it ubuntu:22.04 bash          # interactive Ubuntu container
# Inside the container:
ls / && cat /etc/os-release && exit
docker ps -a                              # see all containers
```

## Task 2 — Run a real service
```bash
# Run nginx web server
docker run -d -p 8081:80 --name my-web nginx
docker ps                                 # confirm it is running
curl http://localhost:8081                # test it
docker logs my-web                        # see its logs
docker stop my-web && docker rm my-web
```

## Task 3 — Write a Dockerfile
```bash
mkdir my-app && cd my-app

cat > app.py << 'APPEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Hello from my DevOps app!")
HTTPServer(('', 8080), Handler).serve_forever()
APPEOF

cat > Dockerfile << 'DFEOF'
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
EXPOSE 8080
CMD ["python3", "app.py"]
DFEOF

docker build -t my-app:v1 .
docker run -d -p 8082:8080 --name my-app my-app:v1
curl http://localhost:8082
```

## Task 4 — Docker Compose
```bash
cat > docker-compose.yml << 'DCEOF'
version: "3.9"
services:
  web:
    image: nginx:alpine
    ports:
      - "8083:80"
  api:
    build: .
    ports:
      - "8084:8080"
DCEOF

docker compose up -d
docker compose ps
docker compose logs
docker compose down
```

## Task 5 — Volumes and data persistence
```bash
docker volume create mydata
docker run -d \
  -v mydata:/data \
  --name data-container \
  ubuntu:22.04 \
  bash -c "echo 'persistent data' > /data/test.txt && sleep 3600"
docker exec data-container cat /data/test.txt
```

## Challenge
Build a Docker image for a simple app of your choice,
tag it as `yourname/app:v1`, and document the commands you used.
This is a common interview task.


---
<!-- File: C:\Users\ADMIN\flo-tech\aws-devops\devops-platform\labs\phase-5-cicd\LAB.md -->
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


---
<!-- File: C:\Users\ADMIN\flo-tech\aws-devops\devops-platform\labs\phase-6-ansible\LAB.md -->
# Ansible configuration management

## Why this matters
Ansible lets you configure 1 or 1000 servers with identical commands.
It is the most in-demand configuration management tool in Africa and globally
for sysadmin-to-DevOps transition roles.

---

## Task 1 — Understand Ansible's core concepts
- **Inventory** — the list of servers you manage
- **Playbook** — a YAML file describing what to do
- **Task** — a single action (install a package, copy a file, restart a service)
- **Role** — a reusable collection of tasks
- **Idempotent** — running it twice gives the same result (safe to re-run)

## Task 2 — Your first inventory
```bash
mkdir ~/ansible-lab && cd ~/ansible-lab

cat > inventory.ini << 'INVEOF'
[webservers]
web1 ansible_host=127.0.0.1 ansible_connection=local

[dbservers]
db1  ansible_host=127.0.0.1 ansible_connection=local

[all:vars]
ansible_user=student
INVEOF

ansible all -i inventory.ini -m ping
```

## Task 3 — Your first playbook
```bash
cat > site.yml << 'PBEOF'
---
- name: Configure web servers
  hosts: webservers
  become: true

  tasks:
    - name: Ensure curl is installed
      apt:
        name: curl
        state: present
        update_cache: yes

    - name: Create app directory
      file:
        path: /opt/myapp
        state: directory
        owner: student
        mode: '0755'

    - name: Write config file
      copy:
        content: |
          PORT=8080
          ENV=production
        dest: /opt/myapp/config.env
        mode: '0600'

    - name: Confirm deployment
      debug:
        msg: "Web server configured successfully on {{ inventory_hostname }}"
PBEOF

ansible-playbook -i inventory.ini site.yml
```

## Task 4 — Variables and templates
```bash
cat > vars.yml << 'VAREOF'
app_port: 8080
app_env: production
app_name: devops-app
VAREOF

cat > deploy.yml << 'DEPEOF'
---
- name: Deploy application
  hosts: all
  vars_files:
    - vars.yml

  tasks:
    - name: Show deployment info
      debug:
        msg: "Deploying {{ app_name }} on port {{ app_port }} in {{ app_env }}"

    - name: Create systemd service
      copy:
        content: |
          [Unit]
          Description={{ app_name }}

          [Service]
          ExecStart=/usr/bin/python3 -m http.server {{ app_port }}
          Restart=always

          [Install]
          WantedBy=multi-user.target
        dest: /tmp/{{ app_name }}.service
DEPEOF

ansible-playbook -i inventory.ini deploy.yml
```

## Task 5 — Roles (reusable structure)
```bash
ansible-galaxy init roles/webserver
ls -la roles/webserver/

cat > roles/webserver/tasks/main.yml << 'ROLEEOF'
---
- name: Install nginx
  apt:
    name: nginx
    state: present
  become: true

- name: Start nginx
  service:
    name: nginx
    state: started
    enabled: true
  become: true
ROLEEOF

cat > use-role.yml << 'UREOF'
---
- name: Setup web server using role
  hosts: webservers
  roles:
    - webserver
UREOF

ansible-playbook -i inventory.ini use-role.yml
```

## Challenge
Write an Ansible playbook that:
1. Creates three users (alice, bob, charlie)
2. Creates a directory `/opt/team` owned by all three
3. Writes a file `/opt/team/README.txt` with today's date
Run it twice — confirm it is idempotent (no errors on second run).


---
<!-- File: C:\Users\ADMIN\flo-tech\aws-devops\devops-platform\labs\phase-7-kubernetes\LAB.md -->
# Kubernetes — deploy and manage containers at scale

## Why this matters
Kubernetes (K8s) is the industry standard for running containerised apps.
It carries the highest salary premium of any single DevOps skill.

---

## Task 1 — Understand the architecture
- **Node** — a machine (VM or physical) in the cluster
- **Pod** — the smallest deployable unit (one or more containers)
- **Deployment** — manages multiple identical pods, handles updates and restarts
- **Service** — exposes pods on the network
- **Namespace** — logical separation within a cluster

```bash
kubectl get nodes           # list cluster nodes
kubectl get namespaces      # list namespaces
kubectl get pods -A         # all pods in all namespaces
```

## Task 2 — Deploy your first application
```bash
cat > deployment.yml << 'K8EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
K8EOF

kubectl apply -f deployment.yml
kubectl get pods
kubectl get deployment my-app
```

## Task 3 — Expose with a Service
```bash
cat > service.yml << 'SVCEOF'
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
SVCEOF

kubectl apply -f service.yml
kubectl get services
kubectl describe service my-app-service
```

## Task 4 — Scale and update
```bash
kubectl scale deployment my-app --replicas=5
kubectl get pods -w                          # watch pods appear

kubectl set image deployment/my-app my-app=nginx:1.25
kubectl rollout status deployment/my-app
kubectl rollout history deployment/my-app

kubectl rollout undo deployment/my-app       # rollback if needed
```

## Task 5 — ConfigMaps and Secrets
```bash
kubectl create configmap app-config \
  --from-literal=PORT=8080 \
  --from-literal=ENV=production

kubectl create secret generic app-secrets \
  --from-literal=DB_PASSWORD=supersecret

kubectl get configmaps
kubectl get secrets
kubectl describe configmap app-config
```

## Task 6 — Debug pods
```bash
kubectl logs my-app-<pod-id>              # view logs
kubectl exec -it my-app-<pod-id> -- sh   # shell into pod
kubectl describe pod my-app-<pod-id>     # full pod details
kubectl get events --sort-by='.lastTimestamp'
```

## Challenge
Deploy a 3-replica nginx deployment. Create a service to expose it.
Scale it to 6 replicas. Then roll back to 3. Document every command
and its output — this is your Kubernetes portfolio piece.


---
<!-- File: C:\Users\ADMIN\flo-tech\aws-devops\devops-platform\labs\phase-8-terraform\LAB.md -->
# Terraform — Infrastructure as Code

## Why this matters
Infrastructure as Code means your servers, networks and databases
are defined in files, version-controlled in Git, and reproducible.
Platform engineering teams require this on day one.

---

## Task 1 — Terraform basics
```bash
terraform version
mkdir ~/tf-lab && cd ~/tf-lab
```

## Task 2 — Your first configuration
```bash
cat > main.tf << 'TFEOF'
terraform {
  required_version = ">= 1.0"
}

# Local file provider — practice IaC without a cloud account
resource "local_file" "app_config" {
  filename = "/tmp/app.conf"
  content  = <<-EOT
    PORT=8080
    ENV=production
    VERSION=1.0.0
  EOT
}

resource "local_file" "readme" {
  filename = "/tmp/INFRASTRUCTURE.md"
  content  = "# Infrastructure managed by Terraform\nDo not edit manually."
}
TFEOF

terraform init      # download providers
terraform plan      # preview what will happen
terraform apply     # create the resources
cat /tmp/app.conf   # confirm files were created
```

## Task 3 — Variables and outputs
```bash
cat > variables.tf << 'VAREOF'
variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8080
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"
}
VAREOF

cat > outputs.tf << 'OUTEOF'
output "config_file_path" {
  description = "Path to the generated config file"
  value       = local_file.app_config.filename
}
OUTEOF

# Update main.tf to use variables
cat > main.tf << 'TFEOF'
terraform {
  required_version = ">= 1.0"
}

resource "local_file" "app_config" {
  filename = "/tmp/app-${var.environment}.conf"
  content  = "PORT=${var.app_port}\nENV=${var.environment}\n"
}
TFEOF

terraform apply -var="environment=production" -var="app_port=9090"
terraform output
```

## Task 4 — State management
```bash
terraform state list          # see all managed resources
terraform state show local_file.app_config
terraform plan                # see drift if files changed
terraform destroy             # destroy everything (be careful)
```

## Task 5 — Modules (reusable components)
```bash
mkdir -p modules/config-file
cat > modules/config-file/main.tf << 'MODEOF'
variable "filename" {}
variable "content"  {}

resource "local_file" "this" {
  filename = var.filename
  content  = var.content
}

output "path" { value = local_file.this.filename }
MODEOF

cat > main.tf << 'ROOTEOF'
module "web_config" {
  source   = "./modules/config-file"
  filename = "/tmp/web.conf"
  content  = "PORT=80\nSERVICE=web\n"
}

module "api_config" {
  source   = "./modules/config-file"
  filename = "/tmp/api.conf"
  content  = "PORT=8080\nSERVICE=api\n"
}
ROOTEOF

terraform init && terraform apply
```

## Challenge
Write a Terraform configuration that creates 5 config files
(web, api, db, cache, queue) using a module. All should be
created with a single `terraform apply`. Commit it to Git.


---
<!-- File: C:\Users\ADMIN\flo-tech\aws-devops\devops-platform\labs\phase-9-monitoring\LAB.md -->
# Monitoring with Prometheus & Grafana

## Why this matters
You cannot fix what you cannot see. Monitoring is how you know
a service is broken BEFORE your users do. SRE roles make this
their primary responsibility.

---

## Task 1 — Run Prometheus
```bash
mkdir ~/monitoring-lab && cd ~/monitoring-lab

cat > prometheus.yml << 'PROMEOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
PROMEOF

cat > docker-compose.yml << 'DCEOF'
version: "3.9"
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=devops123
    depends_on:
      - prometheus
DCEOF

docker compose up -d
```

## Task 2 — Explore Prometheus
Open `http://localhost:9090` in your browser.

```promql
up                            # which services are up
node_cpu_seconds_total        # CPU usage data
node_memory_MemAvailable_bytes # available memory
rate(node_cpu_seconds_total{mode="idle"}[5m])  # CPU usage rate
```

## Task 3 — Connect Grafana
1. Open `http://localhost:3001`
2. Login: admin / devops123
3. Add data source → Prometheus → URL: `http://prometheus:9090`
4. Create a dashboard → Add panel → Query: `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
5. Title it "CPU Usage %" and save

## Task 4 — Alerting rules
```bash
cat > alert-rules.yml << 'ALERTEOF'
groups:
  - name: system-alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for 2 minutes"

      - alert: LowDiskSpace
        expr: node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space"
ALERTEOF
```

## Challenge
Create a Grafana dashboard with 4 panels:
CPU usage, memory usage, disk usage, and network traffic.
Export it as JSON and save it to your Git repository.
This is a portfolio piece that impresses employers.


---
<!-- File: C:\Users\ADMIN\flo-tech\aws-devops\devops-platform\labs\phase-10-capstone\LAB.md -->
# Capstone project — deploy a production-grade application

## What you are building
A complete deployment pipeline for a web application that demonstrates
every skill from this course. This is your portfolio project.
Show it in every interview.

---

## The stack you will use
- **Git** — version control and collaboration
- **Docker** — containerise the application
- **GitHub Actions** — CI/CD pipeline
- **Ansible** — provision and configure the server
- **Kubernetes** — deploy and scale the application
- **Prometheus + Grafana** — monitor everything

---

## Phase A — Set up the repository
```bash
git clone https://github.com/YOUR_USERNAME/capstone-devops
cd capstone-devops
mkdir -p app ansible k8s monitoring .github/workflows
```

## Phase B — Build the application
```bash
cat > app/app.py << 'APPEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, os, datetime

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.respond({"status": "ok", "time": str(datetime.datetime.now())})
        elif self.path == '/metrics':
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'# HELP requests_total Total requests\n')
            self.wfile.write(b'requests_total 1\n')
        else:
            self.respond({"message": "DevOps Capstone App", "version": "1.0"})

    def respond(self, data):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def log_message(self, fmt, *args):
        print(f"[{datetime.datetime.now()}] {fmt % args}")

HTTPServer(('', int(os.getenv('PORT', 8080))), Handler).serve_forever()
APPEOF

cat > app/Dockerfile << 'DFEOF'
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8080/health || exit 1
CMD ["python3", "app.py"]
DFEOF
```

## Phase C — CI/CD pipeline
```yaml
# .github/workflows/pipeline.yml
name: Full CI/CD Pipeline

on:
  push:
    branches: [main]

jobs:
  build-test-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t capstone-app:${{ github.sha }} app/

      - name: Test health endpoint
        run: |
          docker run -d -p 8080:8080 --name test-app capstone-app:${{ github.sha }}
          sleep 3
          curl -f http://localhost:8080/health
          docker stop test-app

      - name: Push to registry
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker tag capstone-app:${{ github.sha }} ghcr.io/${{ github.repository }}/capstone-app:latest
          docker push ghcr.io/${{ github.repository }}/capstone-app:latest
```

## Phase D — Ansible provisioning
```yaml
# ansible/provision.yml
---
- name: Provision application server
  hosts: all
  become: true
  tasks:
    - name: Install Docker
      apt:
        name: docker.io
        state: present
        update_cache: yes

    - name: Start Docker
      service:
        name: docker
        state: started
        enabled: true

    - name: Pull application image
      command: docker pull ghcr.io/YOUR_USERNAME/capstone-devops/capstone-app:latest

    - name: Run application
      command: >
        docker run -d
        --name capstone-app
        --restart unless-stopped
        -p 8080:8080
        ghcr.io/YOUR_USERNAME/capstone-devops/capstone-app:latest
```

## Phase E — Kubernetes deployment
```yaml
# k8s/deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: capstone-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: capstone-app
  template:
    metadata:
      labels:
        app: capstone-app
    spec:
      containers:
      - name: capstone-app
        image: ghcr.io/YOUR_USERNAME/capstone-devops/capstone-app:latest
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 30
```

## Phase F — Submit your project
Your completed capstone must include:
- [ ] GitHub repository with all code
- [ ] Working CI/CD pipeline (green badge in README)
- [ ] Dockerfile and built image
- [ ] Ansible playbook for provisioning
- [ ] Kubernetes manifests
- [ ] Grafana dashboard screenshot
- [ ] `README.md` explaining the architecture

**This repository IS your CV.** Share the link in every job application.


