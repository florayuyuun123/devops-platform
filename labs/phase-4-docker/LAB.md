# Docker Containers & Images

Docker is the most important tool in modern DevOps. If you master Docker, you are instantly employable. It solves the famous "It works on my machine" problem by package applications into portable "Containers."

---

## Task 1 — Your First Container

### The Concept (What)
A **Container** is a lightweight, standalone package that includes everything needed to run an application. We run them using `docker run`.

### Real-world Context (Why)
Before Docker, setting up a new developer's laptop took days. With Docker, it takes 5 seconds because the entire environment is already inside the container.

### Execution (How)
Run a simple "Hello-world" and then dive into a full Ubuntu Linux container.

```bash
docker run hello-world
```

```bash
docker run -it ubuntu:22.04 bash
```
*Note: Inside the container, you are a "root" user in a completely isolated world. Type `exit` to come back to your sandbox.*

---

## Task 2 — Running a Web Service (Nginx)

### The Concept (What)
We can run background services (like a web server) using the `-d` (detached) flag and map ports using `-p`.

### Real-world Context (Why)
In a real company, you don't just run one app. You run 50 copies of your app, each in its own container, all controlled by a central system.

### Execution (How)
Run an Nginx web server and test it.

```bash
docker run -d -p 8081:80 --name my-web nginx
```

```bash
docker ps
```

```bash
curl http://localhost:8081
```

```bash
docker stop my-web && docker rm my-web
```

---

## Task 3 — Building Your Own Image (Dockerfile)

### The Concept (What)
A **Dockerfile** is a recipe for building your own custom image. We use `docker build` to turn this recipe into a reusable "Image."

### Real-world Context (Why)
Developers write the code, and DevOps Engineers write the Dockerfile to ensure that code runs perfectly in production.

### Execution (How)
Create a simple Python app and build a Docker image for it.

```bash
mkdir -p ~/my-app && cd ~/my-app
```

```bash
cat > app.py << 'APPEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Hello from my DevOps app!")
HTTPServer(('', 8080), Handler).serve_forever()
APPEOF
```

```bash
cat > Dockerfile << 'DFEOF'
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
EXPOSE 8080
CMD ["python3", "app.py"]
DFEOF
```

```bash
docker build -t my-app:v1 .
```

```bash
docker run -d -p 8082:8080 --name my-run-app my-app:v1
```

```bash
curl http://localhost:8082
```

---

## Task 4 — Multi-Container Apps (Docker Compose)

### The Concept (What)
**Docker Compose** allows you to start multiple containers at once (e.g., a Web App + a Database) using a single YAML file.

### Real-world Context (Why)
Most apps aren't just one file; they need databases, caches, and queues. Docker Compose "orchestrates" them so they can all talk to each other automatically.

### Execution (How)
Launch a web server and your custom API together.

```bash
cat > docker-compose.yml << 'DCEOF'
version: "3.9"
services:
  web:
    image: nginx:alpine
    ports:
      - "8083:80"
  api:
    image: my-app:v1
    ports:
      - "8084:8080"
DCEOF
```

```bash
docker compose up -d
```

```bash
docker compose ps
```

```bash
docker compose down
```

---

## Challenge
Find out how to list only the **IDs** of your containers (HINT: use `docker ps -aq`). This is a very common command used in automation scripts!
