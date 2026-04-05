# Capstone Project — The Production-Grade App

This is what you've been working toward! You are now going to build a complete deployment pipeline for a web application that demonstrates every single skill you've learned. This isn't just a lab—this is your **Portfolio Project**. Show this to every recruiter and hiring manager.

---

## Phase A — Repository Architecture (The "Library")

### The Concept (What)
We create a highly organized directory structure to hold our App, our Ansible playbooks, our Kubernetes manifests, and our Monitoring configs.

### Real-world Context (Why)
A messy repository is a sign of a junior engineer. A clean, modular structure tells an employer that you understand how to manage complex, enterprise-scale projects.

### Execution (How)
Initialize your capstone folder and build the structure.

```bash
mkdir -p ~/capstone-devops && cd ~/capstone-devops
```

```bash
mkdir -p app ansible k8s monitoring .github/workflows
```

---

## Phase B — Building the Application (Docker)

### The Concept (What)
We write a professional Python application that includes "Health Checks" and "Metrics," then package it into a Docker image.

### Real-world Context (Why)
In production, a load balancer needs to know if your app is "healthy" before it sends traffic. By adding a `/health` endpoint, you are making your app "Cloud-Native."

### Execution (How)
Create the app and the Dockerfile.

```bash
cat > app/app.py << 'APPEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, os, datetime

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200); self.end_headers()
            self.wfile.write(b'{"status": "ok"}')
        else:
            self.send_response(200); self.end_headers()
            self.wfile.write(b'{"message": "DevOps Capstone App"}')

HTTPServer(('', 8080), Handler).serve_forever()
APPEOF
```

```bash
cat > app/Dockerfile << 'DFEOF'
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
EXPOSE 8080
CMD ["python3", "app.py"]
DFEOF
```

---

## Phase C — Automation (CI/CD)

### The Concept (What)
We create a GitHub Actions pipeline that builds, tests, and pushes our image automatically.

### Real-world Context (Why)
You want to be the "Engineer of 10x Impact." Automation means you spend your time designing systems, not manually running commands.

### Execution (How)
An example of your final `.github/workflows/pipeline.yml` structure.

```yaml
name: Full CI/CD Pipeline
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and Test
        run: docker build -t capstone-app .
```

---

## Phase D — Infrastructure (Kubernetes)

### The Concept (What)
We write the Kubernetes manifest to deploy our app with **High Availability** (3 replicas).

### Real-world Context (Why)
If you only run 1 copy of your app, and it crashes, the site is down. By running 3 copies, you ensure that your business never goes offline.

### Execution (How)
Create the final Kubernetes Deployment.

```yaml
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
        image: yourname/capstone-app:latest
        ports:
        - containerPort: 8080
```

---

## Final Submission Checklist
To call yourself a Graduate of the DevOps Platform, your project must include:
- [ ] GitHub repository with all code.
- [ ] Working CI/CD pipeline (Green checkmark).
- [ ] Optimized Dockerfile.
- [ ] Kubernetes manifests for scaling.
- [ ] `README.md` explaining YOUR architecture.

**This project is your ticket to a high-paying DevOps career. Good luck!**
