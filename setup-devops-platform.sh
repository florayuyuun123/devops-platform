#!/bin/bash
# =============================================================
#  DevOps Learning Platform — Master Setup Script
#  Run this once inside your cloned GitHub repository folder.
#  It creates every file, every folder, every config the
#  platform needs, then pushes everything to GitHub.
#
#  Usage:
#    chmod +x setup-devops-platform.sh
#    ./setup-devops-platform.sh
# =============================================================

set -e  # stop immediately if any command fails

# ── Colours for readable output ──────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # no colour

log()     { echo -e "${GREEN}[OK]${NC}  $1"; }
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
section() { echo -e "\n${CYAN}${BOLD}══ $1 ══${NC}"; }
die()     { echo -e "${RED}[ERR]${NC}  $1"; exit 1; }

# ── Preflight checks ─────────────────────────────────────────
section "Preflight checks"

command -v git  >/dev/null 2>&1 || die "git is not installed. Install it first."
command -v curl >/dev/null 2>&1 || die "curl is not installed. Install it first."

# Make sure we are inside a git repository
if [ ! -d ".git" ]; then
  die "Run this script from inside your cloned GitHub repository folder.\n       cd devops-platform && ./setup-devops-platform.sh"
fi

log "Git repository detected"

# Collect GitHub username
GITHUB_USER=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]\([^/]*\)/.*|\1|' || echo "")
if [ -z "$GITHUB_USER" ]; then
  echo -e "${YELLOW}Enter your GitHub username:${NC} "
  read -r GITHUB_USER
fi
info "GitHub user: $GITHUB_USER"

BASE=$(pwd)
log "Working directory: $BASE"

# ═════════════════════════════════════════════════════════════
section "Creating directory structure"
# ═════════════════════════════════════════════════════════════

mkdir -p \
  .github/workflows \
  portal \
  api \
  sandbox \
  labs/phase-1-linux \
  labs/phase-2-networking \
  labs/phase-3-git \
  labs/phase-4-docker \
  labs/phase-5-cicd \
  labs/phase-6-ansible \
  labs/phase-7-kubernetes \
  labs/phase-8-terraform \
  labs/phase-9-monitoring \
  labs/phase-10-capstone \
  offline-node \
  scripts

log "All directories created"

# ═════════════════════════════════════════════════════════════
section "Sandbox Docker image"
# ═════════════════════════════════════════════════════════════

cat > sandbox/Dockerfile << 'DOCKEREOF'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bash curl wget git vim nano less tree htop jq \
    net-tools iputils-ping dnsutils nmap netcat-openbsd \
    python3 python3-pip ansible \
    openssh-client openssh-server \
    sudo man-db unzip \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls \
    https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl && mv kubectl /usr/local/bin/

# terraform
RUN wget -q https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip \
    && unzip terraform_1.7.0_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_1.7.0_linux_amd64.zip

# ttyd — browser-based terminal server
RUN curl -Lo /usr/local/bin/ttyd \
    https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 \
    && chmod +x /usr/local/bin/ttyd

# student user — no password needed inside sandbox
RUN useradd -m -s /bin/bash student \
    && echo "student:devops2024" | chpasswd \
    && usermod -aG sudo student \
    && echo "student ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY welcome.sh /etc/profile.d/welcome.sh
RUN chmod +x /etc/profile.d/welcome.sh

WORKDIR /home/student
USER student

# Default command: serve a web terminal on port 7681
EXPOSE 7681
CMD ["ttyd", "-W", "-p", "7681", "bash", "--login"]
DOCKEREOF

cat > sandbox/welcome.sh << 'WELCOMEOF'
#!/bin/bash
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║     DevOps Learning Platform — Sandbox       ║"
echo "║                                              ║"
echo "║  Type: cat lab/LAB.md    to read your lab    ║"
echo "║  Type: ls lab/           to list lab files   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
WELCOMEOF

log "Sandbox Dockerfile written"

# ═════════════════════════════════════════════════════════════
section "API backend (FastAPI)"
# ═════════════════════════════════════════════════════════════

cat > api/requirements.txt << 'EOF'
fastapi==0.109.0
uvicorn==0.27.0
python-multipart==0.0.7
pyjwt==2.8.0
passlib[bcrypt]==1.7.4
python-jose[cryptography]==3.3.0
aiofiles==23.2.1
EOF

cat > api/main.py << 'APIEOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import subprocess, os, json, time, secrets

app = FastAPI(title="DevOps Learning Platform", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

SESSIONS = {}
SANDBOX_REGISTRY = {}

# ── Models ────────────────────────────────────────────────────
class AuthRequest(BaseModel):
    username: str
    password: str

class SandboxRequest(BaseModel):
    student_id: str
    lab_id: str

class ProgressUpdate(BaseModel):
    student_id: str
    lab_id: str
    task_id: str
    completed: bool

# ── Auth ──────────────────────────────────────────────────────
@app.post("/auth/login")
def login(req: AuthRequest):
    token = secrets.token_hex(32)
    SESSIONS[token] = {"username": req.username, "created": int(time.time())}
    return {"token": token, "username": req.username}

@app.post("/auth/register")
def register(req: AuthRequest):
    return login(req)

# ── Health ────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "platform": "DevOps Learning Platform v1.0",
            "timestamp": int(time.time())}

# ── Labs ──────────────────────────────────────────────────────
@app.get("/labs")
def get_labs():
    labs_path = "/app/labs"
    labs = []
    if os.path.exists(labs_path):
        for phase_dir in sorted(os.listdir(labs_path)):
            meta_file = f"{labs_path}/{phase_dir}/meta.json"
            if os.path.exists(meta_file):
                with open(meta_file) as f:
                    labs.append(json.load(f))
    return {"labs": labs, "total": len(labs)}

@app.get("/labs/{lab_id}")
def get_lab(lab_id: str):
    labs_path = "/app/labs"
    for phase_dir in sorted(os.listdir(labs_path)):
        meta_file = f"{labs_path}/{phase_dir}/meta.json"
        if os.path.exists(meta_file):
            with open(meta_file) as f:
                meta = json.load(f)
            if meta.get("id") == lab_id:
                lab_file = f"{labs_path}/{phase_dir}/LAB.md"
                content = open(lab_file).read() if os.path.exists(lab_file) else ""
                return {**meta, "content": content}
    raise HTTPException(status_code=404, detail="Lab not found")

# ── Sandboxes ─────────────────────────────────────────────────
@app.post("/sandbox/start")
def start_sandbox(req: SandboxRequest):
    container_name = f"sb_{req.student_id}_{req.lab_id}".replace("-", "_")

    # Already running?
    check = subprocess.run(
        ["docker", "ps", "-q", "-f", f"name={container_name}"],
        capture_output=True, text=True
    )
    if check.stdout.strip():
        port = SANDBOX_REGISTRY.get(container_name, {}).get("port", 7681)
        return {"status": "already_running", "container": container_name,
                "port": port, "terminal_path": f"/terminal/{container_name}"}

    # Assign a port
    port = 7700 + (abs(hash(container_name)) % 200)

    lab_path = f"/app/labs/{req.lab_id}"
    cmd = [
        "docker", "run", "-d",
        "--name", container_name,
        "--memory", "512m",
        "--cpus", "0.5",
        "-p", f"{port}:7681",
        "--label", f"student={req.student_id}",
        "--label", f"lab={req.lab_id}",
        "--label", f"started={int(time.time())}",
    ]
    if os.path.exists(lab_path):
        cmd += ["-v", f"{lab_path}:/home/student/lab:ro"]
    cmd.append("devops-sandbox:latest")

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise HTTPException(status_code=500, detail=result.stderr)

    SANDBOX_REGISTRY[container_name] = {
        "student_id": req.student_id,
        "lab_id": req.lab_id,
        "port": port,
        "started": int(time.time())
    }
    return {"status": "started", "container": container_name,
            "port": port, "terminal_path": f"/terminal/{container_name}"}

@app.delete("/sandbox/{container_name}")
def stop_sandbox(container_name: str):
    subprocess.run(["docker", "stop", container_name], capture_output=True)
    subprocess.run(["docker", "rm",   container_name], capture_output=True)
    SANDBOX_REGISTRY.pop(container_name, None)
    return {"status": "stopped", "container": container_name}

@app.get("/sandbox/active")
def list_active():
    result = subprocess.run(
        ["docker", "ps", "--format",
         '{"name":"{{.Names}}","status":"{{.Status}}"}',
         "-f", "label=student"],
        capture_output=True, text=True
    )
    sandboxes = []
    for line in result.stdout.strip().split("\n"):
        if line.strip():
            try:
                sandboxes.append(json.loads(line))
            except Exception:
                pass
    return {"sandboxes": sandboxes, "count": len(sandboxes)}

# ── Progress ──────────────────────────────────────────────────
@app.post("/progress")
def update_progress(update: ProgressUpdate):
    key = f"{update.student_id}_{update.lab_id}"
    if key not in SESSIONS:
        SESSIONS[key] = {}
    SESSIONS[key][update.task_id] = update.completed
    return {"status": "saved"}

@app.get("/progress/{student_id}")
def get_progress(student_id: str):
    progress = {k: v for k, v in SESSIONS.items()
                if k.startswith(student_id)}
    return {"student_id": student_id, "progress": progress}
APIEOF

cat > api/Dockerfile << 'EOF'
FROM python:3.11-slim

RUN apt-get update && apt-get install -y docker.io && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
EOF



log "API backend written"

# ═════════════════════════════════════════════════════════════
section "Student portal (GitHub Pages)"
# ═════════════════════════════════════════════════════════════

cat > portal/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>DevOps Learning Platform</title>
<style>
  :root {
    --bg:#0f1117; --surface:#1a1d27; --surface2:#22263a;
    --accent:#4f8ef7; --accent2:#38d9a9;
    --text:#e2e8f0; --muted:#8892a4; --border:#2d3350;
    --danger:#f56565; --success:#48bb78; --warning:#ed8936;
  }
  *{box-sizing:border-box;margin:0;padding:0;}
  body{font-family:'Segoe UI',system-ui,sans-serif;background:var(--bg);color:var(--text);min-height:100vh;}
  header{background:var(--surface);border-bottom:1px solid var(--border);padding:0 24px;height:60px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:100;}
  .logo{font-size:18px;font-weight:700;color:var(--accent);}
  .logo span{color:var(--accent2);}
  .btn{padding:8px 18px;border-radius:8px;border:none;cursor:pointer;font-size:14px;font-weight:500;transition:opacity .2s;}
  .btn:hover{opacity:.85;}
  .btn-primary{background:var(--accent);color:#fff;}
  .btn-ghost{background:transparent;color:var(--muted);border:1px solid var(--border);}
  .btn-sm{padding:6px 14px;font-size:13px;}
  .btn-success{background:var(--success);color:#fff;}
  .btn-danger{background:var(--danger);color:#fff;}

  #login-screen{min-height:100vh;display:flex;align-items:center;justify-content:center;}
  .login-card{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:48px 40px;width:100%;max-width:420px;}
  .login-card h1{font-size:24px;margin-bottom:8px;}
  .login-card p{color:var(--muted);font-size:14px;margin-bottom:32px;}
  .form-group{margin-bottom:16px;}
  .form-group label{display:block;font-size:13px;color:var(--muted);margin-bottom:6px;}
  .form-group input{width:100%;background:var(--surface2);border:1px solid var(--border);border-radius:8px;padding:10px 14px;color:var(--text);font-size:15px;}
  .form-group input:focus{outline:none;border-color:var(--accent);}
  .form-error{color:var(--danger);font-size:13px;margin-top:8px;}

  #app-screen{display:none;}
  .main-layout{display:grid;grid-template-columns:260px 1fr;min-height:calc(100vh - 60px);}
  .sidebar{background:var(--surface);border-right:1px solid var(--border);padding:20px 0;overflow-y:auto;}
  .sidebar-label{font-size:11px;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);padding:8px 16px 4px;}
  .phase-header{display:flex;align-items:center;gap:8px;padding:8px 16px;cursor:pointer;font-size:13px;font-weight:500;color:var(--muted);transition:background .15s;}
  .phase-header:hover{background:var(--surface2);color:var(--text);}
  .phase-dot{width:8px;height:8px;border-radius:50%;background:var(--border);flex-shrink:0;}
  .phase-dot.active{background:var(--accent);}
  .phase-dot.done{background:var(--success);}
  .lab-item{padding:7px 16px 7px 32px;border-radius:6px;cursor:pointer;font-size:13px;color:var(--muted);transition:background .15s;}
  .lab-item:hover{background:var(--surface2);color:var(--text);}
  .lab-item.selected{background:var(--accent)22;color:var(--accent);}

  .content{overflow-y:auto;}
  .content-inner{max-width:860px;padding:32px 40px;}

  .lab-title{font-size:26px;font-weight:700;margin-bottom:10px;}
  .lab-meta{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:20px;}
  .badge{padding:3px 10px;border-radius:20px;font-size:12px;font-weight:500;}
  .badge-phase{background:var(--accent)22;color:var(--accent);}
  .badge-time{background:var(--surface2);color:var(--muted);}
  .badge-level{background:var(--success)22;color:var(--success);}

  .action-bar{display:flex;gap:12px;align-items:center;margin-bottom:24px;padding:14px 16px;background:var(--surface);border-radius:12px;border:1px solid var(--border);}
  .sandbox-status{font-size:13px;color:var(--muted);margin-left:auto;}
  .sandbox-status.running{color:var(--success);}

  .lab-content{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:28px;line-height:1.75;font-size:15px;}
  .lab-content h1{font-size:22px;margin-bottom:8px;color:var(--accent2);}
  .lab-content h2{font-size:17px;margin-top:28px;margin-bottom:12px;padding-bottom:8px;border-bottom:1px solid var(--border);}
  .lab-content h3{font-size:15px;margin-top:20px;margin-bottom:8px;color:var(--accent);}
  .lab-content p{margin-bottom:14px;}
  .lab-content code{background:var(--surface2);border:1px solid var(--border);padding:2px 7px;border-radius:5px;font-family:'Fira Code',monospace;font-size:13px;color:var(--accent2);}
  .lab-content pre{background:#0d1117;border:1px solid var(--border);border-radius:10px;padding:18px 20px;overflow-x:auto;margin:14px 0;}
  .lab-content pre code{background:none;border:none;padding:0;font-size:14px;color:#e2e8f0;line-height:1.6;}
  .lab-content ul,.lab-content ol{padding-left:22px;margin-bottom:14px;}
  .lab-content li{margin-bottom:6px;}
  .lab-content strong{color:var(--accent2);}
  .lab-content blockquote{border-left:3px solid var(--accent);padding:8px 16px;margin:14px 0;color:var(--muted);}

  .terminal-panel{position:fixed;bottom:0;left:0;right:0;height:360px;background:#0d1117;border-top:2px solid var(--accent);z-index:200;display:none;flex-direction:column;}
  .terminal-panel.open{display:flex;}
  .terminal-topbar{display:flex;align-items:center;padding:6px 16px;background:var(--surface);border-bottom:1px solid var(--border);gap:12px;}
  .terminal-title{font-size:13px;font-weight:500;color:var(--accent2);}
  .terminal-close{margin-left:auto;background:none;border:none;color:var(--muted);cursor:pointer;font-size:20px;line-height:1;}
  .terminal-frame{flex:1;border:none;background:#0d1117;}

  .welcome-screen{padding:40px 0 16px;}
  .welcome-screen h1{font-size:30px;font-weight:700;margin-bottom:10px;}
  .welcome-screen h1 span{color:var(--accent);}
  .welcome-screen p{color:var(--muted);font-size:15px;margin-bottom:28px;}
  .phase-cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(210px,1fr));gap:14px;}
  .phase-card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:18px;cursor:pointer;transition:border-color .2s,transform .15s;}
  .phase-card:hover{border-color:var(--accent);transform:translateY(-2px);}
  .phase-card-num{font-size:11px;color:var(--muted);margin-bottom:6px;text-transform:uppercase;letter-spacing:.05em;}
  .phase-card-title{font-size:14px;font-weight:600;margin-bottom:6px;}
  .phase-card-desc{font-size:12px;color:var(--muted);}

  .loading{display:flex;align-items:center;gap:8px;color:var(--muted);font-size:14px;padding:20px 0;}
  .spinner{width:16px;height:16px;border:2px solid var(--border);border-top-color:var(--accent);border-radius:50%;animation:spin .8s linear infinite;}
  @keyframes spin{to{transform:rotate(360deg);}}

  @media(max-width:700px){
    .main-layout{grid-template-columns:1fr;}
    .sidebar{display:none;}
    .content-inner{padding:20px 16px;}
  }
</style>
</head>
<body>

<div id="login-screen">
  <div class="login-card">
    <h1>DevOps Platform</h1>
    <p>Free hands-on DevOps training — no installs required</p>
    <div class="form-group">
      <label>Username</label>
      <input type="text" id="login-user" placeholder="Your name or student ID" />
    </div>
    <div class="form-group">
      <label>Password</label>
      <input type="password" id="login-pass" placeholder="Choose a password" />
    </div>
    <div id="login-error" class="form-error" style="display:none"></div>
    <button class="btn btn-primary" style="width:100%;margin-top:8px" onclick="doLogin()">
      Sign in / Register
    </button>
    <p style="text-align:center;margin-top:14px;font-size:13px;color:var(--muted)">
      New student? Just enter any username and password — your account is created automatically.
    </p>
  </div>
</div>

<div id="app-screen">
  <header>
    <div class="logo">DevOps<span>Platform</span></div>
    <div style="display:flex;align-items:center;gap:16px;">
      <span id="user-label" style="font-size:14px;color:var(--muted)"></span>
      <button class="btn btn-ghost btn-sm" onclick="doLogout()">Sign out</button>
    </div>
  </header>
  <div class="main-layout">
    <div class="sidebar">
      <div class="sidebar-label">Curriculum</div>
      <div id="sidebar-labs"></div>
    </div>
    <div class="content">
      <div class="content-inner" id="main-content">
        <div class="loading"><div class="spinner"></div> Loading...</div>
      </div>
    </div>
  </div>
</div>

<div class="terminal-panel" id="terminal-panel">
  <div class="terminal-topbar">
    <div class="terminal-title" id="terminal-title">Terminal</div>
    <button class="terminal-close" onclick="closeTerminal()">×</button>
  </div>
  <iframe class="terminal-frame" id="terminal-frame" src="about:blank"></iframe>
</div>

<script>
const API = 'https://placeholder.trycloudflare.com';
let currentUser = null, currentToken = null, allLabs = [], activeSandbox = null;

const PHASES = [
  {id:'phase-1-linux',       title:'Linux fundamentals'},
  {id:'phase-2-networking',  title:'Networking & security'},
  {id:'phase-3-git',         title:'Git & version control'},
  {id:'phase-4-docker',      title:'Docker & containers'},
  {id:'phase-5-cicd',        title:'CI/CD pipelines'},
  {id:'phase-6-ansible',     title:'Ansible automation'},
  {id:'phase-7-kubernetes',  title:'Kubernetes'},
  {id:'phase-8-terraform',   title:'Terraform / IaC'},
  {id:'phase-9-monitoring',  title:'Monitoring & observability'},
  {id:'phase-10-capstone',   title:'Capstone project'},
];

async function doLogin() {
  const user = document.getElementById('login-user').value.trim();
  const pass = document.getElementById('login-pass').value.trim();
  if (!user || !pass) { showErr('Please enter username and password.'); return; }
  try {
    const r = await fetch(`${API}/auth/login`, {
      method:'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({username:user, password:pass})
    });
    const d = await r.json();
    currentToken = d.token; currentUser = d.username;
    localStorage.setItem('token', currentToken);
    localStorage.setItem('user', currentUser);
    showApp();
  } catch(e) { showErr('Cannot reach server. You may be offline — try the local node URL.'); }
}

function showErr(m) {
  const el = document.getElementById('login-error');
  el.textContent = m; el.style.display = 'block';
}

function doLogout() {
  localStorage.clear(); currentUser = currentToken = null;
  document.getElementById('login-screen').style.display = 'flex';
  document.getElementById('app-screen').style.display = 'none';
}

async function showApp() {
  document.getElementById('login-screen').style.display = 'none';
  document.getElementById('app-screen').style.display = 'block';
  document.getElementById('user-label').textContent = currentUser;
  await loadLabs();
  showWelcome();
}

async function loadLabs() {
  try {
    const r = await fetch(`${API}/labs`);
    const d = await r.json();
    allLabs = d.labs || [];
  } catch(e) {
    allLabs = PHASES.map((p,i) => ({id:p.id, title:p.title, phase:i+1,
      difficulty:'beginner', duration_minutes:60,
      description:'Start a sandbox to access this lab.'}));
  }
  renderSidebar();
}

function renderSidebar() {
  document.getElementById('sidebar-labs').innerHTML = PHASES.map((ph,i) => {
    const labs = allLabs.filter(l => l.id && l.id.startsWith(ph.id));
    return `<div>
      <div class="phase-header" onclick="showPhase('${ph.id}')">
        <div class="phase-dot"></div>Phase ${i+1}: ${ph.title}
      </div>
      ${labs.map(l => `<div class="lab-item" id="nav-${l.id}"
        onclick="showLab('${l.id}')">${l.title}</div>`).join('')}
    </div>`;
  }).join('');
}

function showWelcome() {
  document.getElementById('main-content').innerHTML = `
    <div class="welcome-screen">
      <h1>Welcome, <span>${currentUser}</span></h1>
      <p>10 phases · 40+ labs · 100% hands-on · works offline</p>
      <div class="phase-cards">
        ${PHASES.map((p,i) => `
          <div class="phase-card" onclick="showPhase('${p.id}')">
            <div class="phase-card-num">Phase ${i+1}</div>
            <div class="phase-card-title">${p.title}</div>
            <div class="phase-card-desc">Click to start</div>
          </div>`).join('')}
      </div>
    </div>`;
}

function showPhase(phaseId) {
  const ph = PHASES.find(p => p.id === phaseId);
  const labs = allLabs.filter(l => l.id && l.id.startsWith(phaseId));
  document.getElementById('main-content').innerHTML = `
    <div style="padding:32px 0 16px">
      <h2 style="font-size:22px;margin-bottom:8px">${ph.title}</h2>
      <p style="color:var(--muted);margin-bottom:24px">${labs.length} lab(s)</p>
      ${labs.map(l => `
        <div class="phase-card" onclick="showLab('${l.id}')" style="margin-bottom:12px">
          <div class="phase-card-title">${l.title}</div>
          <div class="phase-card-desc" style="margin-top:6px">${l.description||''}</div>
          <div style="margin-top:10px;display:flex;gap:8px">
            <span class="badge badge-time">${l.duration_minutes||60} min</span>
            <span class="badge badge-level">${l.difficulty||'beginner'}</span>
          </div>
        </div>`).join('') || '<p style="color:var(--muted)">Labs coming soon.</p>'}
    </div>`;
}

async function showLab(labId) {
  document.querySelectorAll('.lab-item').forEach(e => e.classList.remove('selected'));
  const nav = document.getElementById(`nav-${labId}`);
  if (nav) nav.classList.add('selected');
  document.getElementById('main-content').innerHTML =
    '<div class="loading"><div class="spinner"></div> Loading lab...</div>';
  try {
    const r = await fetch(`${API}/labs/${labId}`);
    const lab = await r.json();
    renderLab(lab);
  } catch(e) {
    document.getElementById('main-content').innerHTML =
      '<div style="padding:32px 0;color:var(--muted)">Start a sandbox to read this lab offline.</div>';
  }
}

function renderLab(lab) {
  const running = activeSandbox && activeSandbox.lab_id === lab.id;
  document.getElementById('main-content').innerHTML = `
    <div class="lab-title">${lab.title}</div>
    <div class="lab-meta">
      <span class="badge badge-phase">Phase ${lab.phase}</span>
      <span class="badge badge-time">${lab.duration_minutes} min</span>
      <span class="badge badge-level">${lab.difficulty}</span>
    </div>
    <div class="action-bar">
      <button class="btn btn-success btn-sm" onclick="startSandbox('${lab.id}')">
        ${running ? 'Open terminal' : 'Start sandbox'}
      </button>
      ${running ? `<button class="btn btn-danger btn-sm"
        onclick="stopSandbox('${activeSandbox.container}')">Stop</button>` : ''}
      <span class="sandbox-status ${running?'running':''}" id="sandbox-status">
        ${running ? 'Sandbox running' : 'No active sandbox'}
      </span>
    </div>
    <div class="lab-content">${md(lab.content || lab.description || '')}</div>`;
}

function md(t) {
  if (!t) return '';
  return t
    .replace(/```[\w]*\n([\s\S]*?)```/g, '<pre><code>$1</code></pre>')
    .replace(/^### (.+)$/gm,'<h3>$1</h3>')
    .replace(/^## (.+)$/gm,'<h2>$1</h2>')
    .replace(/^# (.+)$/gm,'<h1>$1</h1>')
    .replace(/\*\*(.+?)\*\*/g,'<strong>$1</strong>')
    .replace(/`([^`]+)`/g,'<code>$1</code>')
    .replace(/^- (.+)$/gm,'<li>$1</li>')
    .replace(/\n\n/g,'</p><p>')
    .replace(/^(?!<)/gm,'<p>');
}

async function startSandbox(labId) {
  document.getElementById('sandbox-status').textContent = 'Starting...';
  try {
    const r = await fetch(`${API}/sandbox/start`, {
      method:'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({student_id: currentUser, lab_id: labId})
    });
    const d = await r.json();
    activeSandbox = {...d, lab_id: labId};
    openTerminal(d.terminal_path, labId);
    document.getElementById('sandbox-status').textContent = 'Sandbox running';
    document.getElementById('sandbox-status').className = 'sandbox-status running';
  } catch(e) {
    document.getElementById('sandbox-status').textContent = 'Failed to start sandbox';
  }
}

async function stopSandbox(name) {
  await fetch(`${API}/sandbox/${name}`, {method:'DELETE'});
  activeSandbox = null;
  document.getElementById('sandbox-status').textContent = 'Stopped';
  document.getElementById('sandbox-status').className = 'sandbox-status';
}

function openTerminal(path, labId) {
  document.getElementById('terminal-title').textContent = `Terminal — ${labId}`;
  document.getElementById('terminal-frame').src = `${API}${path}`;
  document.getElementById('terminal-panel').classList.add('open');
  document.querySelector('.content').style.paddingBottom = '360px';
}

function closeTerminal() {
  document.getElementById('terminal-panel').classList.remove('open');
  document.querySelector('.content').style.paddingBottom = '0';
}

window.addEventListener('load', () => {
  const t = localStorage.getItem('token'), u = localStorage.getItem('user');
  if (t && u) { currentToken = t; currentUser = u; showApp(); }
  document.getElementById('login-pass')
    .addEventListener('keydown', e => { if (e.key==='Enter') doLogin(); });
});
</script>
</body>
</html>
HTMLEOF

log "Student portal written"

# ═════════════════════════════════════════════════════════════
section "Lab content — all 10 phases"
# ═════════════════════════════════════════════════════════════

# ── Helper to write a lab ─────────────────────────────────────
write_lab() {
  local dir="$1" id="$2" title="$3" phase="$4" phase_name="$5"
  local difficulty="$6" duration="$7" description="$8"
  mkdir -p "$dir"
  cat > "$dir/meta.json" << METAEOF
{
  "id": "$id",
  "title": "$title",
  "phase": $phase,
  "phase_name": "$phase_name",
  "difficulty": "$difficulty",
  "duration_minutes": $duration,
  "description": "$description"
}
METAEOF
}

# Phase 1 — Linux
write_lab "labs/phase-1-linux" "phase-1-linux" \
  "Linux file system & permissions" 1 "Linux fundamentals" \
  "beginner" 45 \
  "Navigate Linux, manage files and understand permissions — the foundation of all DevOps work."

cat > labs/phase-1-linux/LAB.md << 'EOF'
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
EOF

# Phase 2 — Networking
write_lab "labs/phase-2-networking" "phase-2-networking" \
  "Networking, SSH & firewalls" 2 "Networking & security" \
  "beginner" 60 \
  "Understand TCP/IP, DNS, ports and SSH — diagnosed in every technical interview."

cat > labs/phase-2-networking/LAB.md << 'EOF'
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
EOF

# Phase 3 — Git
write_lab "labs/phase-3-git" "phase-3-git" \
  "Git version control & GitHub flow" 3 "Git & version control" \
  "beginner" 60 \
  "Git is used in every software team on the planet. Non-negotiable skill."

cat > labs/phase-3-git/LAB.md << 'EOF'
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
EOF

# Phase 4 — Docker
write_lab "labs/phase-4-docker" "phase-4-docker" \
  "Docker containers & images" 4 "Docker & containers" \
  "intermediate" 75 \
  "Docker is listed in 90% of DevOps job ads. You will use this every day."

cat > labs/phase-4-docker/LAB.md << 'EOF'
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
EOF

# Phase 5 — CI/CD
write_lab "labs/phase-5-cicd" "phase-5-cicd" \
  "CI/CD pipelines with GitHub Actions" 5 "CI/CD pipelines" \
  "intermediate" 90 \
  "Automate build, test and deploy. Senior roles require pipeline ownership."

cat > labs/phase-5-cicd/LAB.md << 'EOF'
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
EOF

# Phase 6 — Ansible
write_lab "labs/phase-6-ansible" "phase-6-ansible" \
  "Ansible configuration management" 6 "Ansible automation" \
  "intermediate" 90 \
  "Ansible is the top tool for automating server configuration. Huge demand in hybrid cloud roles."

cat > labs/phase-6-ansible/LAB.md << 'EOF'
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
EOF

# Phase 7 — Kubernetes
write_lab "labs/phase-7-kubernetes" "phase-7-kubernetes" \
  "Kubernetes — deploy and manage containers at scale" 7 "Kubernetes" \
  "advanced" 120 \
  "Kubernetes carries the highest salary premium of any DevOps skill. Learn to deploy, scale and manage."

cat > labs/phase-7-kubernetes/LAB.md << 'EOF'
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
EOF

# Phase 8 — Terraform
write_lab "labs/phase-8-terraform" "phase-8-terraform" \
  "Terraform — Infrastructure as Code" 8 "Terraform / IaC" \
  "advanced" 90 \
  "Define and provision infrastructure with code. Essential for cloud engineering roles."

cat > labs/phase-8-terraform/LAB.md << 'EOF'
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
EOF

# Phase 9 — Monitoring
write_lab "labs/phase-9-monitoring" "phase-9-monitoring" \
  "Monitoring with Prometheus & Grafana" 9 "Monitoring & observability" \
  "advanced" 90 \
  "Know what is running in production. SRE and platform roles require observability on day one."

cat > labs/phase-9-monitoring/LAB.md << 'EOF'
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
EOF

# Phase 10 — Capstone
write_lab "labs/phase-10-capstone" "phase-10-capstone" \
  "Capstone project — deploy a production-grade app" 10 "Capstone project" \
  "advanced" 480 \
  "Deploy a full application using every skill learned. This becomes your portfolio piece for interviews."

cat > labs/phase-10-capstone/LAB.md << 'EOF'
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
EOF

log "All 10 phases of lab content written"

# ═════════════════════════════════════════════════════════════
section "GitHub Actions — automated deployment"
# ═════════════════════════════════════════════════════════════

cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy Platform

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy-portal:
    name: Deploy portal to GitHub Pages
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/configure-pages@v4
      - uses: actions/upload-pages-artifact@v3
        with:
          path: portal
      - id: deployment
        uses: actions/deploy-pages@v4

  build-sandbox:
    name: Build sandbox image
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@v5
        with:
          context: sandbox
          push: true
          tags: ghcr.io/${{ github.repository }}/devops-sandbox:latest
EOF

log "GitHub Actions workflow written"

# ═════════════════════════════════════════════════════════════
section "Offline node installer"
# ═════════════════════════════════════════════════════════════

cat > offline-node/install.sh << OFFEOF
#!/bin/bash
# DevOps Platform — Offline Node Installer
# Turns any Ubuntu 22.04 machine into a standalone learning node.
# Students connect to it over WiFi — no internet needed.

set -e
REPO="https://github.com/${GITHUB_USER}/devops-platform"
PLATFORM_DIR="/opt/devops-platform"

echo "================================================"
echo "  DevOps Platform — Offline Node Setup"
echo "================================================"

sudo apt-get update -y
sudo apt-get install -y docker.io docker-compose curl git python3-pip nginx

sudo mkdir -p \$PLATFORM_DIR
sudo chown \$USER:\$USER \$PLATFORM_DIR
git clone \$REPO \$PLATFORM_DIR 2>/dev/null || git -C \$PLATFORM_DIR pull

docker pull ghcr.io/${GITHUB_USER}/devops-platform/devops-sandbox:latest 2>/dev/null || \
  docker build -t devops-sandbox:latest \$PLATFORM_DIR/sandbox

pip3 install fastapi uvicorn python-multipart 2>/dev/null

sudo tee /etc/nginx/sites-available/devops-platform > /dev/null << 'NGINXEOF'
server {
    listen 80 default_server;
    root /opt/devops-platform/portal;
    index index.html;
    location / { try_files \$uri \$uri/ /index.html; }
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host \$host;
    }
    location /terminal/ {
        proxy_pass http://localhost:7681/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINXEOF

sudo ln -sf /etc/nginx/sites-available/devops-platform \
            /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

sudo tee /etc/systemd/system/devops-api.service > /dev/null << 'SVCEOF'
[Unit]
Description=DevOps Platform API
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/devops-platform/api
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8080
Restart=always

[Install]
WantedBy=multi-user.target
SVCEOF

sudo systemctl daemon-reload
sudo systemctl enable --now devops-api

LOCAL_IP=\$(hostname -I | awk '{print \$1}')
echo ""
echo "================================================"
echo "  Offline node ready!"
echo "  Students open: http://\$LOCAL_IP"
echo "================================================"
OFFEOF

chmod +x offline-node/install.sh
log "Offline node installer written"

# ═════════════════════════════════════════════════════════════
section "Root files"
# ═════════════════════════════════════════════════════════════

cat > .gitignore << 'EOF'
__pycache__/
*.pyc
.env
*.key
*.pem
node_modules/
.DS_Store
api/labs/
EOF

cat > README.md << READMEEOF
# DevOps Learning Platform

Free, offline-capable, hands-on DevOps training.
Built for students with limited internet access and no expensive cloud accounts.

## Live platform
- Portal: https://${GITHUB_USER}.github.io/devops-platform

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
\`\`\`bash
git clone https://github.com/${GITHUB_USER}/devops-platform
cd devops-platform
# Follow SETUP.md
\`\`\`

## Offline classroom node
\`\`\`bash
curl -s https://raw.githubusercontent.com/${GITHUB_USER}/devops-platform/main/offline-node/install.sh | bash
\`\`\`

## Cost: \$0
GitHub Pages (portal) + Local API over Tunnel + optional offline node.
READMEEOF

cat > SETUP.md << 'SETUPEOF'
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
SETUPEOF

log "Root files written"

# ═════════════════════════════════════════════════════════════
section "File summary"
# ═════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}Files created:${NC}"
find . -type f | grep -v '.git/' | sort | while read f; do
  echo -e "  ${GREEN}+${NC} $f"
done

TOTAL=$(find . -type f | grep -v '.git/' | wc -l)
echo ""
echo -e "${BOLD}Total: $TOTAL files${NC}"

# ═════════════════════════════════════════════════════════════
section "Push to GitHub"
# ═════════════════════════════════════════════════════════════

echo ""
echo -e "${YELLOW}Ready to push to GitHub?${NC} (y/n): "
read -r PUSH_NOW

if [[ "$PUSH_NOW" =~ ^[Yy]$ ]]; then
  git add .
  git commit -m "feat: initial platform — 10 phases, full automation, offline support"
  git push origin main
  log "Pushed to GitHub. Check the Actions tab in ~30 seconds."
  echo ""
  echo -e "  Portal will be live at: ${CYAN}https://${GITHUB_USER}.github.io/devops-platform${NC}"
  echo -e "  API will be live at:    ${CYAN}https://placeholder.trycloudflare.com${NC}"
else
  echo ""
  info "When ready, push manually:"
  echo "  git add ."
  echo "  git commit -m 'Initial platform'"
  echo "  git push origin main"
fi

echo ""
echo -e "${GREEN}${BOLD}Platform setup complete!${NC}"
echo -e "Next: Follow ${CYAN}SETUP.md${NC} to connect Fly.io and enable GitHub Pages."
echo -e "Get a Grey.co virtual card before day 7 to keep Fly.io free permanently."
echo ""
