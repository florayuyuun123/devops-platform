import asyncio
import subprocess
from fastapi import WebSocket
import websockets

async def proxy_terminal(websocket: WebSocket, container_name: str,
                          sandbox_registry: dict):
    await websocket.accept()

    port = None
    for name, info in sandbox_registry.items():
        if name == container_name:
            port = info.get("port")
            break

    if not port:
        result = subprocess.run(
            ["docker", "port", container_name, "7681"],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            port = int(result.stdout.strip().split(":")[-1])

    if not port:
        await websocket.send_text("Container not found")
        await websocket.close()
        return

    try:
        async with websockets.connect(f"ws://localhost:{port}/ws") as backend:
            async def forward_to_backend():
                try:
                    while True:
                        data = await websocket.receive_bytes()
                        await backend.send(data)
                except Exception:
                    pass

            async def forward_to_client():
                try:
                    while True:
                        data = await backend.recv()
                        if isinstance(data, bytes):
                            await websocket.send_bytes(data)
                        else:
                            await websocket.send_text(data)
                except Exception:
                    pass

            await asyncio.gather(
                forward_to_backend(),
                forward_to_client()
            )
    except Exception as e:
        try:
            await websocket.send_text(f"Connection error: {e}")
        except Exception:
            pass
