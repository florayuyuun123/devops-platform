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
