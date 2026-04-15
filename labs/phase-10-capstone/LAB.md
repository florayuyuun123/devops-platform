# Capstone Project — The E-Commerce Deployment

This is what you've been working toward! You are now going to deploy a complete **E-Commerce Application** using Kubernetes. This isn't just a lab—this is your **Portfolio Project**. It brings together everything you've learned: Deployments, ConfigMaps, Networking, and Container Security.

> [!NOTE]
> **Automated Validation:** Just like the previous module, this project uses the "Progress Validation" pipeline at the bottom of the page. Watch it turn **Green** as you build your platform!

---

## Phase A — Architecture and Namespace

### The Concept
A professional deployment isolates its resources. We will start by creating a dedicated **Namespace** for our e-commerce platform.

### Execution

```bash
minikube start --driver=docker
```

```bash
kubectl create namespace ecommerce
```

Check your namespaces:
```bash
kubectl get namespaces
```

**✅ How to Prove It:**
*   You should see the `ecommerce` namespace in the list.
*   This proves your platform is logically isolated from the rest of the cluster!

---

## Phase B — The Frontend ConfigMap

### The Concept
Instead of hardcoding our website HTML into a Docker image, we will store the entire E-Commerce frontend inside a Kubernetes **ConfigMap**. This allows us to update the website without rebuilding containers!

### Execution
Create the massive ConfigMap containing the E-Commerce HTML frontend. *Copy and paste this entire block carefully!*

```bash
cat > ecommerce-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: ecommerce-html
  namespace: ecommerce
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>MS2 E-Commerce Platform</title>
        <style>
            body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
            .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            h1 { color: #2c3e50; text-align: center; }
            .form-group { margin-bottom: 15px; }
            label { display: block; margin-bottom: 5px; font-weight: bold; }
            input, select, textarea { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
            button { background: #3498db; color: white; padding: 12px 30px; border: none; border-radius: 5px; cursor: pointer; }
            button:hover { background: #2980b9; }
            .status { background: #e8f5e8; padding: 15px; border-radius: 5px; margin-top: 20px; }
            .product-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
            .product { border: 1px solid #ddd; padding: 15px; border-radius: 5px; text-align: center; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>MS2 E-Commerce Platform</h1>
            <p><strong>Powered by Kubernetes Microservices</strong></p>
            <div class="product-grid">
                <div class="product">
                    <h3>Smartphone Pro</h3>
                    <p>Price: $899</p>
                    <button onclick="selectProduct('Smartphone Pro', 899)">Select</button>
                </div>
                <div class="product">
                    <h3>Laptop Ultra</h3>
                    <p>Price: $1299</p>
                    <button onclick="selectProduct('Laptop Ultra', 1299)">Select</button>
                </div>
            </div>
            <form id="orderForm" onsubmit="submitOrder(event)">
                <h2>Customer Order Form</h2>
                <div class="form-group">
                    <label>Full Name:</label>
                    <input type="text" name="customerName" required>
                </div>
                <div class="form-group">
                    <label>Selected Product:</label>
                    <input type="text" id="product" name="product" readonly>
                </div>
                <button type="submit">Place Order</button>
            </form>
            <div class="status">
                <h3>Kubernetes Infrastructure Status</h3>
                <p>NGINX Gateway: Active | Namespace: ecommerce</p>
            </div>
        </div>
        <script>
            let selectedPrice = 0;
            function selectProduct(name, price) {
                document.getElementById('product').value = name;
                selectedPrice = price;
            }
            function submitOrder(event) {
                event.preventDefault();
                alert('Order Submitted Successfully!\nOrder ID: K8S-' + Math.random().toString(36).substr(2, 9).toUpperCase());
            }
        </script>
    </body>
    </html>
EOF
```

```bash
kubectl apply -f ecommerce-config.yaml
```

---

## Phase C — The Application Deployment

### The Concept
We will deploy a Python HTTP Server using best-practice Kubernetes security configurations (Running as Non-Root, restricted Pod resources, and comprehensive Health Probes).

### Execution
Define the deployment that mounts our ConfigMap as the `/app` root directory.

```bash
cat > ecommerce-app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-app
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ecommerce-app
  template:
    metadata:
      labels:
        app: ecommerce-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
      - name: python-server
        image: python:3.9-alpine
        command: ["python", "-m", "http.server", "8080"]
        workingDir: /app
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
        volumeMounts:
        - name: html-content
          mountPath: /app
      volumes:
      - name: html-content
        configMap:
          name: ecommerce-html
EOF
```

```bash
kubectl apply -f ecommerce-app.yaml
```

Check your deployment's status carefully to ensure the container started securely:
```bash
kubectl get pods -n ecommerce
```

**✅ How to Prove It:**
*   Run `kubectl get pods -n ecommerce`. You should see one pod for `ecommerce-app` with status **Running**.
*   Run `kubectl describe pod -n ecommerce -l app=ecommerce-app`. Look at the **Volumes** section to verify that `ecommerce-html` is mounted.
*   Check the **SecurityContext**: You should see that it's correctly running as a restricted user (UID 1000).

---

## Phase D — Service Exposure 

### The Concept
The application is running inside the cluster. Now we must open an external port to allow customer web traffic in. We use a **NodePort** Service.

### Execution

```bash
cat > ecommerce-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: ecommerce-service
  namespace: ecommerce
spec:
  selector:
    app: ecommerce-app
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30082
  type: NodePort
EOF
```

```bash
kubectl apply -f ecommerce-service.yaml
```

---

## Phase E — Final Testing and Browser Preview

1. Get the status of all your platform's resources:
```bash
kubectl get all -n ecommerce
```

2. **🌐 Real-World Browser Preview**:
Now that your E-Commerce service is live on port **30082**, let's view it in your browser:
*   Look at the top of this Lab page and click the **🌐 Preview App** button.
*   A new browser tab will open showing your **MS2 E-Commerce Platform**!
*   *Note: It may take up to 20 seconds for the cluster networking to fully bridge after click.*

3. (Self-Correction/Manual Check) If you want to verify via terminal instead:
```bash
# Get the IP of your cluster
MINIKUBE_IP=$(minikube ip)
# Fetch the HTML
curl http://${MINIKUBE_IP}:30082
```

## Congratulations! 🎉
You have formally architected, secured, deployed, and routed an entire Web Application using industry-standard Kubernetes conventions. You are ready for a DevOps career!
