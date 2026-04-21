# Capstone Project — MS2 E-Commerce Platform

This is the summit of your DevOps journey! You are going to build and deploy a professional **E-Commerce Storefront** using every skill in your arsenal: Docker, CI/CD, and Kubernetes. This is your **Portfolio Masterpiece**.

---

## Phase A — Repository Architecture

### The Concept
Build a modular, enterprise-scale repository to manage the code, automation, and infrastructure.

### Execution
```bash
mkdir -p ~/ms2-ecommerce && cd ~/ms2-ecommerce
mkdir -p app k8s .github/workflows
```

---

## Phase B — Native Web Delivery (Nginx)

### The Concept
Instead of a simple script, we use **Nginx**—the industry standard for high-performance web delivery—to serve our storefront.

### Execution
Create a professional Dockerfile that uses Nginx to serve your platform on **Port 8080**.

```bash
cat > app/Dockerfile << 'EOF'
FROM nginx:alpine
RUN sed -i 's/listen[[:space:]]*80;/listen 8080;/' /etc/nginx/conf.d/default.conf
WORKDIR /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
EOF
```

---

## Phase C — Automating the Build (GitHub Actions)

### The Concept
Automate the 'Build and Push' cycle so that every code change is instantly ready for production.

### Execution
Ensure you are in the project root, create the folder, and save your `.github/workflows/pipeline.yml`:

```bash
mkdir -p .github/workflows
```

```bash
cat > .github/workflows/pipeline.yml << 'EOF'
name: MS2 E-Commerce CI
on: [push]
jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Docker Build
        run: docker build -t ms2-ecommerce ./app
EOF
```

---

## Phase D — Production Launch (Kubernetes)

### The Concept
Deploy the platform into a Kubernetes cluster using a **ConfigMap** to inject the high-visibility storefront UI.

### Pre-flight Checklist
Before you deploy, verify your Kubernetes cluster is awake and ready:
```bash
minikube status
```
> [!TIP]
> If it says `Stopped`, run `minikube start --driver=docker`.

### Execution

1. **The Storefront HTML**: Create the `ecommerce-config.yaml` to hold your professional dashboard.
```bash
cat > k8s/ecommerce-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: ecommerce-html
data:
  index.html: |
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>MS2 E-Commerce Platform</title>
        <style>
            body { font-family: 'Inter', sans-serif; background: #0f172a; color: white; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
            .card { background: #1e293b; padding: 40px; border-radius: 24px; border: 1px solid #334155; text-align: center; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1); }
            .badge { background: #38bdf8; color: #020617; padding: 4px 12px; border-radius: 99px; font-weight: 700; font-size: 12px; }
            h1 { margin: 16px 0; font-size: 32px; }
            .btn { background: #38bdf8; color: #020617; text-decoration: none; padding: 12px 24px; border-radius: 12px; font-weight: 600; display: inline-block; margin-top: 24px; }
        </style>
    </head>
    <body>
        <div class="card">
            <div class="badge">PRODUCTION READY</div>
            <h1>MS2 E-Commerce Platform</h1>
            <p>Powered by Kubernetes & DevOps Automation</p>
            <a href="#" class="btn" onclick="alert('Order Processed Successfully!')">Place Test Order</a>
        </div>
    </body>
    </html>
EOF
```

2. **The Deployment**: Create `k8s/deployment.yaml` and mount the ConfigMap.
```bash
cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ecommerce
  template:
    metadata:
      labels:
        app: ecommerce
    spec:
      containers:
      - name: ecommerce
        image: nginx:alpine
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: html-volume
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
      volumes:
      - name: html-volume
        configMap:
          name: ecommerce-html
EOF
```

3. **Apply and Expose**:
```bash
kubectl apply -f k8s/ecommerce-config.yaml
kubectl apply -f k8s/deployment.yaml
kubectl expose deployment ecommerce-app --type=NodePort --port=8080
```

---

## Final Review
Click the **🌐 Preview App** button in the dashboard to see your production storefront in action! 

**You have just deployed a professional, high-availability web platform. This is the gold standard for your DevOps portfolio.** 🎓🚀
