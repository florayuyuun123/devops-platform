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
