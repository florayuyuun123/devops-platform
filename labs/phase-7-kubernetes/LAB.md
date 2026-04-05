# Kubernetes — Container Orchestration at Scale

Kubernetes (often called K8s) is the industry standard for running containerized apps. While Docker runs one container, Kubernetes runs *thousands* of containers across hundreds of servers. It is the most valuable skill on a DevOps resume today.

---

## Task 1 — Core Architecture (The "Team")

### The Concept (What)
- **Pod** — The smallest unit (like a single worker).
- **Deployment** — The manager that ensures you always have the right number of workers.
- **Service** — The "Phone Number" used to reach your workers.
- **Node** — the physical or virtual server where the workers live.

### Real-world Context (Why)
If a server crashes in the middle of the night, Kubernetes notices instantly. It will automatically move your "Pods" to a healthy server before your customers even notice something went wrong.

### Execution (How)
Explore the cluster using `kubectl`.

```bash
kubectl get nodes
```

```bash
kubectl get namespaces
```

```bash
kubectl get pods -A
```

---

## Task 2 — Your First Deployment

### The Concept (What)
A **Deployment** is a YAML file that describes the "Desired State" of your app (e.g., "I want 3 copies of Nginx running").

### Real-world Context (Why)
Instead of manually starting 3 containers, you tell Kubernetes what you want, and it *guarantees* that state. If one container dies, Kubernetes starts a new one automatically.

### Execution (How)
Create and apply your first deployment.

```bash
cat > deployment.yml << 'K8EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:alpine
        ports:
        - containerPort: 80
K8EOF
```

```bash
kubectl apply -f deployment.yml
```

```bash
kubectl get pods
```

---

## Task 3 — Exposing with a Service

### The Concept (What)
A **Service** provides a single, stable IP address or name to reach your group of Pods.

### Real-world Context (Why)
Pods are temporary; they get deleted and recreated with new IP addresses all the time. A Service acts like a "Front Desk" that always knows where to find the active Pods.

### Execution (How)
Create a Service to route traffic to your 3 Nginx pods.

```bash
cat > service.yml << 'SVCEOF'
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
SVCEOF
```

```bash
kubectl apply -f service.yml
```

```bash
kubectl get services
```

---

## Task 4 — Scaling and Rollbacks

### The Concept (What)
Scaling is changing the number of running pods. A Rollback is "undoing" a bad update.

### Real-world Context (Why)
If your app goes viral on TikTok, you can scale from 3 pods to 300 pods in seconds. If you push a bad update that breaks the site, you can "Rollback" to the previous working version instantly.

### Execution (How)
Scale your app to 5 replicas and then practice an update.

```bash
kubectl scale deployment my-app --replicas=5
```

```bash
kubectl get pods
```

```bash
kubectl rollout history deployment/my-app
```

---

## Task 5 — Debugging (Investigation)

### The Concept (What)
Using `logs` and `describe` to find out why a pod is failing.

### Real-world Context (Why)
90% of a DevOps Engineer's day is spent investigating why something isn't working. `kubectl describe` is your best friend—it tells you the exact error (e.g., "Out of Memory" or "Image not found").

### Execution (How)
Check the logs of one of your pods.

```bash
POD_NAME=$(kubectl get pods -l app=my-app -o jsonpath="{.items[0].metadata.name}")
kubectl logs $POD_NAME
```

```bash
kubectl describe pod $POD_NAME
```

---

## Challenge
Try to scale your deployment to **0** replicas. What happens when you run `kubectl get pods`? Then scale it back to **3**. This is how we gracefully shut down or restart entire applications!
