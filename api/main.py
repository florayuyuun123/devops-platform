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
