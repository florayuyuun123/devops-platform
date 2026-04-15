# Kubernetes Masterclass — Orchestration at Scale

Kubernetes (often called K8s) is the industry standard for running containerized applications intelligently across fleets of servers. This module covers everything from basic Pods to Services, ConfigMaps, RBAC Security, and Helm package management.

---

## Task 1 — Provision the Local Cluster

Before interacting with Kubernetes, we need a cluster. In this sandbox, you have full Docker engine access, so we will use **Minikube** with the Docker driver.

```bash
# Optional: Clear any old "Ghost Pods" from your host machine first
minikube delete --all --purge

# Start the cluster
minikube start --driver=docker
```
*Wait a minute or two for the cluster to fully provision.* 

> [!TIP]
> **Troubleshooting:** If the startup fails with a "version" or "state" error, run `minikube delete --all --purge` and then try the start command again.

Verify the node is ready:

```bash
kubectl get nodes
```

---

## Task 2 — Pods & Deployments

A **Pod** is the smallest unit (1+ containers). A **Deployment** manages those Pods, ensuring a specific number of replicas are always running.

Create a Deployment of 3 Nginx replicas:

```bash
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.19
          ports:
            - containerPort: 80
EOF
```

Apply and verify:
```bash
kubectl apply -f deployment.yaml
kubectl get pods
```

Scale it up to 5 replicas instantly:
```bash
kubectl scale deployment nginx-deployment --replicas=5
kubectl get pods
```

---

## Task 3 — Services and Networking

Pods die and get new IPs. A **Service** provides a stable IP or port to reach them. We will create a `NodePort` service to allow external access.

Create a NodePort Service:
```bash
cat > nodeport-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
EOF
```

Apply and observe the assigned ports:
```bash
kubectl apply -f nodeport-service.yaml
kubectl get services
```
*Since we mapped it to `30080`, any traffic hitting the Node on `30080` will be routed to your Nginx pods.*

---

## Task 4 — ConfigMaps and Storage

We use **ConfigMaps** to inject configuration files into containers without rebuilding images.

Create a simple ConfigMap that holds an HTML index page:
```bash
cat > app-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  index.html: |
    <h1>Welcome to the K8s Masterclass!</h1>
    <p>Stored completely inside a ConfigMap.</p>
EOF
```
```bash
kubectl apply -f app-config.yaml
```

Now, mount this ConfigMap into a new Pod so Nginx serves our custom HTML!
```bash
cat > config-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: config-demo-pod
spec:
  containers:
    - name: nginx
      image: nginx:alpine
      volumeMounts:
      - name: config-volume
        mountPath: /usr/share/nginx/html
  volumes:
    - name: config-volume
      configMap:
        name: app-config
EOF
```
```bash
kubectl apply -f config-pod.yaml
```

---

## Task 5 — Role-Based Access Control (RBAC)

**RBAC** allows you to restrict what users or Service Accounts can do in the cluster (Least Privilege Principle).

1. Create a Namespace and a ServiceAccount:
```bash
kubectl create namespace dev
kubectl create serviceaccount demo-sa --namespace=dev
```

2. Create a **Role** that only allows someone to *read* pods in the `dev` namespace:
```bash
cat > role.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
EOF
```
```bash
kubectl apply -f role.yaml
```

3. Tie the Role to the ServiceAccount using a **RoleBinding**:
```bash
cat > rolebinding.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: dev
subjects:
- kind: ServiceAccount
  name: demo-sa
  namespace: dev
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF
```
```bash
kubectl apply -f rolebinding.yaml
```

4. **Verify the Permissions**:
Test if `demo-sa` can list pods (Should say "yes"):
```bash
kubectl auth can-i list pods --as=system:serviceaccount:dev:demo-sa --namespace=dev
```
Test if `demo-sa` can delete pods (Should say "no"):
```bash
kubectl auth can-i delete pods --as=system:serviceaccount:dev:demo-sa --namespace=dev
```

---

## Task 6 — Helm & StatefulSets

**Helm** is a package manager for Kubernetes. Rather than writing YAML files manually, we can install pre-configured packages (like databases) called "Charts." A database requires a **StatefulSet** because it needs persistent identity and data.

Let's install **Redis** using Helm:

1. Install the Helm CLI:
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

2. Add a generic Repository containing the Redis Chart (Wait for updates to finish):
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

3. Install Redis:
```bash
kubectl create namespace redis-app
helm install redis bitnami/redis --namespace redis-app --set auth.enabled=true --set auth.password=mypassword --set master.persistence.enabled=true
```

4. Verify it was created as a **StatefulSet** (Notice the indexed naming convention `redis-master-0` instead of random characters):
```bash
kubectl get statefulset -n redis-app
kubectl get pods -n redis-app
```

---

## Task 7 — Cleanup
It is crucial to keep your cluster clean. Let's practice deleting everything we created today:

```bash
# Delete Helm release
helm uninstall redis -n redis-app

# Delete RBAC infrastructure
kubectl delete -f rolebinding.yaml
kubectl delete -f role.yaml

# Delete Base infrastructure
kubectl delete -f config-pod.yaml
kubectl delete -f app-config.yaml
kubectl delete -f nodeport-service.yaml
kubectl delete -f deployment.yaml

# Delete Namespaces
kubectl delete namespace redis-app
kubectl delete namespace dev
```

You are now officially a Kubernetes expert. Head over to **Phase 10: Capstone Project** to deploy a comprehensive E-Commerce Application!
