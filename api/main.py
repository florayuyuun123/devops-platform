import os, asyncio, subprocess, json, time, secrets, httpx
from fastapi import FastAPI, HTTPException, Request, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel

app = FastAPI(title="DevOps Learning Platform", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

SESSIONS, SANDBOX_REGISTRY = {}, {}
REGISTRY_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sandboxes.json")

def save_registry():
    try:
        with open(REGISTRY_FILE, "w") as f:
            json.dump(SANDBOX_REGISTRY, f)
    except Exception as e: print(f"ERROR: Could not save registry: {e}")

def load_registry():
    global SANDBOX_REGISTRY
    if os.path.exists(REGISTRY_FILE):
        try:
            with open(REGISTRY_FILE, "r") as f:
                SANDBOX_REGISTRY = json.load(f)
        except Exception as e: print(f"ERROR: Could not load registry: {e}")

load_registry()

LABS_PATH = os.path.abspath(os.path.normpath(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "labs")))

class AuthRequest(BaseModel):
    username: str
    password: str

class SandboxRequest(BaseModel):
    lab_id: str
    student_id: str
    duration_minutes: int = 60

class ProgressUpdate(BaseModel):
    student_id: str
    lab_id: str
    task_id: str
    completed: bool

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
def health_check():
    return {
        "status": "ok", 
        "version": "2.2", 
        "file_path": os.path.abspath(__file__),
        "sandboxes": len(SANDBOX_REGISTRY)
    }

@app.get("/labs")
def get_labs():
    labs = []
    if os.path.exists(LABS_PATH):
        for d in sorted(os.listdir(LABS_PATH), key=lambda x: int(x.split("-")[1]) if len(x.split("-"))>1 and x.split("-")[1].isdigit() else 99):
            mf = os.path.join(LABS_PATH, d, "meta.json")
            if os.path.exists(mf):
                labs.append(json.load(open(mf)))
    return {"labs": labs, "total": len(labs)}

@app.get("/labs/{lab_id}")
def get_lab(lab_id: str):
    if os.path.exists(LABS_PATH):
        for d in sorted(os.listdir(LABS_PATH)):
            mf = os.path.join(LABS_PATH, d, "meta.json")
            if os.path.exists(mf):
                meta = json.load(open(mf))
                if meta.get("id") == lab_id:
                    lf = os.path.join(LABS_PATH, d, "LAB.md")
                    return {**meta, "content": open(lf).read() if os.path.exists(lf) else ""}
    raise HTTPException(status_code=404, detail="Lab not found")

@app.post("/sandbox")
def start_sandbox(req: SandboxRequest):
    # Ensure student ID is clean and lowercase
    sid = req.student_id.lower().strip()
    lid = req.lab_id.replace("-","_")
    cn = "sb_{}_{}".format(sid, lid)
    
    if subprocess.run(["docker","ps","-q","-f","name={}".format(cn)], capture_output=True, text=True).stdout.strip():
        return {"status":"already_running","container":cn,"port":get_port(cn),"terminal_path":"/terminal/{}".format(cn)}
    
    subprocess.run(["docker","rm","-f",cn], capture_output=True)
    import hashlib
    h = int(hashlib.sha1(cn.encode()).hexdigest(), 16)
    port = 7700 + (h % 200)
    
    # Find the correct lab folder by matching the ID in meta.json
    lp = None
    if os.path.exists(LABS_PATH):
        for d in os.listdir(LABS_PATH):
            mf = os.path.join(LABS_PATH, d, "meta.json")
            if os.path.exists(mf):
                try:
                    with open(mf) as f:
                        meta = json.load(f)
                        if meta.get("id") == req.lab_id:
                            lp = os.path.join(LABS_PATH, d)
                            break
                except: continue
    cmd = ["docker","run","-d","--name",cn,"--memory","2048m","--cpus","2.0","--network","host","-v","/var/run/docker.sock:/var/run/docker.sock","--label","student={}".format(req.student_id),"--label","lab={}".format(req.lab_id)]
    cmd.append("devops-sandbox:latest")
    cmd.extend(["sh", "-c", f"ttyd -p {port} -s 10000 bash --login"])
    
    print("LOG: Starting sandbox: " + " ".join(cmd))
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0: raise HTTPException(status_code=500, detail=r.stderr)

    # 100% Reliable File Injection (Bypass WSL Volume bugs)
    if lp and os.path.exists(lp):
        alp = os.path.realpath(lp)
        subprocess.run(["docker","exec",cn,"mkdir","-p","/home/student/lab"])
        subprocess.run(["docker","cp", alp + "/.", cn + ":/home/student/lab/"])
        subprocess.run(["docker","exec","-u","root",cn,"chown","-R","student:student","/home/student/lab"])
        print("LOG: Lab files injected successfully")
    
    # Bypass Host-Container GID mismatches for Docker integration
    subprocess.run(["docker","exec","-u","root",cn,"chmod","666","/var/run/docker.sock"])
    print("LOG: Docker socket permissions explicitly relaxed for student access")

    # ── ttyd Readiness Check ─────────────────────────────────────
    # Wait until ttyd is actually listening before telling the browser to load.
    # This eliminates the blank-screen delay on the frontend iframe.
    print(f"LOG: Waiting for ttyd on port {port}...")
    ttyd_ready = False
    for _ in range(30):  # up to 15 seconds (30 x 0.5s)
        try:
            import socket
            s = socket.create_connection(("localhost", port), timeout=1)
            s.close()
            ttyd_ready = True
            print(f"LOG: ttyd is ready on port {port}")
            break
        except OSError:
            time.sleep(0.5)
    if not ttyd_ready:
        print(f"WARNING: ttyd did not respond on port {port} within 15s")

    SANDBOX_REGISTRY[cn] = {
        "student_id":req.student_id,
        "lab_id":req.lab_id,
        "port":port,
        "started":int(time.time()),
        "duration": req.duration_minutes
    }
    save_registry()
    return {
        "status":"started",
        "container":cn,
        "lab_id": req.lab_id,
        "port":port,
        "terminal_path":"/terminal/{}".format(cn),
        "started": SANDBOX_REGISTRY[cn]["started"]
    }

@app.get("/sandbox/{container_name}/check")
def check_progress(container_name: str):
    # Logic to run check.sh inside container
    try:
        r = subprocess.run(["docker","exec",container_name,"bash","-c","[ -f /home/student/lab/check.sh ] && bash /home/student/lab/check.sh || echo '{\"stages\":[]}'"], capture_output=True, text=True)
        return json.loads(r.stdout)
    except:
        return {"stages":[{"id":"init","name":"Initializing","status":"running"}]}

@app.delete("/sandbox/{container_name}")
def stop_sandbox(container_name: str):
    subprocess.run(["docker","stop",container_name], capture_output=True)
    subprocess.run(["docker","rm",container_name], capture_output=True)
    SANDBOX_REGISTRY.pop(container_name, None)
    save_registry()
    return {"status":"stopped"}

@app.get("/sandbox/active")
def list_active():
    res = []
    for cn, data in SANDBOX_REGISTRY.items():
        res.append({
            "name": cn,
            "lab_id": data.get("lab_id"),
            "student_id": data.get("student_id"),
            "started": data.get("started", 0),
            "duration": data.get("duration", 60),
            "terminal_path": "/terminal/{}".format(cn)
        })
    return {"sandboxes": res, "count": len(res)}

@app.post("/progress")
def update_progress(u: ProgressUpdate):
    k = "{}_{}".format(u.student_id, u.lab_id)
    SESSIONS.setdefault(k, {})[u.task_id] = u.completed
    return {"status":"saved"}

@app.get("/progress/{student_id}")
def get_progress(student_id: str):
    return {"student_id":student_id,"progress":{k:v for k,v in SESSIONS.items() if k.startswith(student_id)}}

@app.get("/debug/terminal/{container_name}")
async def debug_terminal(container_name: str):
    port = get_port(container_name)
    test = None
    if port:
        try:
            async with httpx.AsyncClient(timeout=5) as c:
                r = await c.get("http://localhost:{}/".format(port))
                test = "OK {}".format(r.status_code)
        except Exception as e: test = "FAIL {}".format(e)
    return {"container":container_name,"port":port,"ttyd":test}

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
            # Remove any direct port references that would leak through
            import re
            body = re.sub(
                b'http://localhost:[0-9]+',
                b'',
                body
            )
            # Inject script to fix WebSocket URL before ttyd connects
            ws_fix = b'''<script>
(function() {
    var _WebSocket = window.WebSocket;
    window.WebSocket = function(url, protocols) {
        if (url.indexOf("localhost") !== -1 || url.indexOf("127.0.0.1") !== -1) {
            var loc = window.location;
            var proto = loc.protocol === "https:" ? "wss:" : "ws:";
            url = proto + "//" + loc.host + "/terminal/''' + container_name.encode() + b'''/ws";
        }
        return protocols ? new _WebSocket(url, protocols) : new _WebSocket(url);
    };
    window.WebSocket.prototype = _WebSocket.prototype;
    window.WebSocket.CONNECTING = _WebSocket.CONNECTING;
    window.WebSocket.OPEN = _WebSocket.OPEN;
    window.WebSocket.CLOSING = _WebSocket.CLOSING;
    window.WebSocket.CLOSED = _WebSocket.CLOSED;
})();
</script>'''
            body = body.replace(b'<head>', b'<head>' + ws_fix)
            return Response(content=body, media_type=resp.headers.get("content-type","text/html"))
    except Exception as e: raise HTTPException(status_code=502, detail=str(e))

@app.get("/terminal/{container_name}/{path:path}")
async def terminal_asset(container_name: str, path: str, request: Request):
    port = get_port(container_name)
    if not port: raise HTTPException(status_code=404, detail="not found")
    q = request.url.query
    url = "http://localhost:{}/{}{}".format(port, path, "?"+q if q else "")
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(url)
            return Response(content=r.content, status_code=r.status_code, media_type=r.headers.get("content-type"))
    except Exception as e: raise HTTPException(status_code=502, detail=str(e))

@app.websocket("/terminal/{container_name}/ws")
async def terminal_ws(websocket: WebSocket, container_name: str):
    port = get_port(container_name)
    if not port:
        await websocket.close(code=1008)
        return

    # Get subprotocol from client (ttyd uses 'tty' protocol)
    subprotocols = websocket.headers.get("sec-websocket-protocol", "")
    proto = subprotocols.split(",")[0].strip() if subprotocols else None

    # Accept with the same subprotocol the client requested
    if proto:
        await websocket.accept(subprotocol=proto)
    else:
        await websocket.accept()

    try:
        import websockets as wsl
        # Connect to ttyd backend with the same subprotocol
        ws_kwargs = {}
        if proto:
            ws_kwargs["subprotocols"] = [proto]
        async with wsl.connect(
            "ws://localhost:{}/ws".format(port),
            **ws_kwargs
        ) as backend:
            async def c2b():
                try:
                    while True:
                        try:
                            d = await websocket.receive_bytes()
                        except Exception:
                            try:
                                d = (await websocket.receive_text()).encode()
                            except Exception:
                                break
                        await backend.send(d)
                except Exception:
                    pass

            async def b2c():
                try:
                    while True:
                        d = await backend.recv()
                        if isinstance(d, bytes):
                            await websocket.send_bytes(d)
                        else:
                            await websocket.send_text(d)
                except Exception:
                    pass

            await asyncio.gather(c2b(), b2c())
    except Exception as e:
        try:
            await websocket.send_text("Error: {}".format(e))
        except Exception:
            pass
    finally:
        try:
            await websocket.close()
        except Exception:
            pass

@app.get("/view/{container_name}/{port_num}/{path:path}")
async def preview_proxy(container_name: str, port_num: int, path: str, request: Request):
    if container_name not in SANDBOX_REGISTRY:
        raise HTTPException(status_code=404, detail="Sandbox session not found")
    
    # Smart Discovery: Try to find the internal Minikube IP inside the container
    # We cache this in the registry so we only run 'minikube ip' once.
    target_ip = SANDBOX_REGISTRY[container_name].get("k8s_ip")
    if not target_ip:
        try:
            # Increased patience for Kubernetes startups (Bug 2)
            r = subprocess.run(["docker","exec",container_name,"minikube","ip"], capture_output=True, text=True, timeout=8)
            if r.returncode == 0 and r.stdout.strip():
                target_ip = r.stdout.strip()
                # ONLY cache if it's a real IP address, not a fallback
                SANDBOX_REGISTRY[container_name]["k8s_ip"] = target_ip
                save_registry()
            else:
                target_ip = "localhost"
        except:
            target_ip = "localhost"

    target_url = "http://{}:{}/{}".format(target_ip, port_num, path)
    if request.url.query:
        target_url += "?" + request.url.query

    try:
        async with httpx.AsyncClient(timeout=10, follow_redirects=True) as c:
            headers = {k: v for k, v in request.headers.items() if k.lower() != "host"}
            resp = await c.get(target_url, headers=headers)
            
            content = resp.content
            print(f"LOG: Preview Proxy HIT | Path: '{path}' | Size: {len(content)} bytes")
            
            raw_type = resp.headers.get("content-type", "").lower()
            content_type = raw_type.split(";")[0].strip()
            
            # Universal MIME Intelligence (Nuclear Fix)
            import mimetypes
            guessed_type, _ = mimetypes.guess_type(path)
            if guessed_type:
                # Force the guessed type for critical assets
                content_type = guessed_type
                print(f"LOG: Preview Proxy [!!!] FORCING MIME Type: {content_type}")
            elif not content_type or content_type in ["text/plain", "application/octet-stream", "binary/octet-stream"]:
                # Second-tier check for HTML content if no extension exists
                low_content = content.lower()[:1000]
                if b"<!doctype html" in low_content or b"<html" in low_content:
                    content_type = "text/html"
                    print(f"LOG: Preview Proxy [!!!] FORCING HTML MODE")
                else:
                    content_type = "text/html" # Default fallback for preview sub-pages

            # Robust HTML Injection
            if content_type == "text/html":
                base_url = "/view/{}/{}/".format(container_name, port_num)
                base_tag = f'<base href="{base_url}">'.encode()
                
                # Find <head> or <html> tag (case-insensitive)
                import re
                head_match = re.search(b'<(head|html)[^>]*>', content, re.IGNORECASE)
                if head_match:
                    insert_at = head_match.end()
                    content = content[:insert_at] + base_tag + content[insert_at:]
                else:
                    content = base_tag + content

            # Final Headers: Force the browser's hand
            final_headers = {
                "Content-Type": content_type,
                "Cache-Control": "no-cache, no-store, must-revalidate",
                "Pragma": "no-cache",
                "X-Frame-Options": "ALLOWALL",
                "Content-Security-Policy": "frame-ancestors *",
                "Access-Control-Allow-Origin": "*"
            }
            # Specifically RELAX nosniff to allow browser recovery for lab previews
            # final_headers["X-Content-Type-Options"] = "nosniff" # REMOVED for Nuclear Fix
            
            # Forward other safe headers
            for k, v in resp.headers.items():
                lk = k.lower()
                if lk not in ["content-length", "content-encoding", "transfer-encoding", "content-type", "cache-control", "pragma", "x-frame-options", "content-security-policy", "x-content-type-options"]:
                    final_headers[k] = v

            return Response(content=content, status_code=resp.status_code, headers=final_headers)
    except Exception as e:
        raise HTTPException(status_code=502, detail="Failed to reach app on {}:{}. Error: {}".format(target_ip, port_num, e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=7715, log_level="info")