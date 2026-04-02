# Kubernetes — deploy and manage containers at scale

## Why this matters
Kubernetes (K8s) is the industry standard for running containerised apps.
It carries the highest salary premium of any single DevOps skill.

---

## Task 1 — Understand the architecture
- **Node** — a machine (VM or physical) in the cluster
- **Pod** — the smallest deployable unit (one or more containers)
- **Deployment** — manages multiple identical pods, handles updates and restarts
- **Service** — exposes pods on the network
- **Namespace** — logical separation within a cluster

```bash
kubectl get nodes           # list cluster nodes
kubectl get namespaces      # list namespaces
kubectl get pods -A         # all pods in all namespaces
```

## Task 2 — Deploy your first application
```bash
cat > deployment.yml << 'K8EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
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
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
K8EOF

kubectl apply -f deployment.yml
kubectl get pods
kubectl get deployment my-app
```

## Task 3 — Expose with a Service
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

kubectl apply -f service.yml
kubectl get services
kubectl describe service my-app-service
```

## Task 4 — Scale and update
```bash
kubectl scale deployment my-app --replicas=5
kubectl get pods -w                          # watch pods appear

kubectl set image deployment/my-app my-app=nginx:1.25
kubectl rollout status deployment/my-app
kubectl rollout history deployment/my-app

kubectl rollout undo deployment/my-app       # rollback if needed
```

## Task 5 — ConfigMaps and Secrets
```bash
kubectl create configmap app-config \
  --from-literal=PORT=8080 \
  --from-literal=ENV=production

kubectl create secret generic app-secrets \
  --from-literal=DB_PASSWORD=supersecret

kubectl get configmaps
kubectl get secrets
kubectl describe configmap app-config
```

## Task 6 — Debug pods
```bash
kubectl logs my-app-<pod-id>              # view logs
kubectl exec -it my-app-<pod-id> -- sh   # shell into pod
kubectl describe pod my-app-<pod-id>     # full pod details
kubectl get events --sort-by='.lastTimestamp'
```

## Challenge
Deploy a 3-replica nginx deployment. Create a service to expose it.
Scale it to 6 replicas. Then roll back to 3. Document every command
and its output — this is your Kubernetes portfolio piece.
