import os, asyncio, subprocess, json, time, secrets, httpx
from fastapi import FastAPI, HTTPException, Request, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel

app = FastAPI(title="DevOps Learning Platform", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

SESSIONS, SANDBOX_REGISTRY = {}, {}
LABS_PATH = os.path.abspath(os.path.normpath(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "labs")))

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
    return {"status": "ok", "platform": "DevOps Learning Platform", "version": "1.0.0", "labs_found": os.path.exists(LABS_PATH)}

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

@app.post("/sandbox/start")
def start_sandbox(req: SandboxRequest):
    cn = "sb_{}_{}".format(req.student_id, req.lab_id).replace("-","_")
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
    cmd = ["docker","run","-d","--name",cn,"--memory","512m","--cpus","0.5","--network","host","-v","/var/run/docker.sock:/var/run/docker.sock","--label","student={}".format(req.student_id),"--label","lab={}".format(req.lab_id)]
    if lp and os.path.exists(lp):
        alp = os.path.realpath(lp)
        cmd += ["-v","{}:/home/student/lab:ro".format(alp)]
    cmd.append("devops-sandbox:latest")
    cmd.extend(["ttyd", "-p", str(port), "tmux", "new-session", "-A", "-s", "devops", "bash", "--login"])
    print("LOG: Starting container with command: " + " ".join(cmd))
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print("LOG: Docker error: " + r.stderr)
        raise HTTPException(status_code=500, detail=r.stderr)
    SANDBOX_REGISTRY[cn] = {"student_id":req.student_id,"lab_id":req.lab_id,"port":port,"started":int(time.time())}
    return {"status":"started","container":cn,"port":port,"terminal_path":"/terminal/{}".format(cn)}

@app.delete("/sandbox/{container_name}")
def stop_sandbox(container_name: str):
    subprocess.run(["docker","stop",container_name], capture_output=True)
    subprocess.run(["docker","rm",container_name], capture_output=True)
    SANDBOX_REGISTRY.pop(container_name, None)
    return {"status":"stopped"}

@app.get("/sandbox/active")
def list_active():
    r = subprocess.run(["docker","ps","--format","{{.Names}}","--filter","label=student"], capture_output=True, text=True)
    names = [n for n in r.stdout.strip().split("\n") if n]
    return {"sandboxes": [{"name": n} for n in names], "count": len(names)}

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