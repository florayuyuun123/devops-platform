# Kubernetes Masterclass — Orchestration at Scale

Kubernetes (often called K8s) is the industry standard for running containerized applications intelligently across fleets of servers. This module covers everything from basic Pods to Services and ConfigMaps.

---

## Task 1 — Provision the Local Cluster (Day 1)

Before interacting with Kubernetes, we need a cluster. In this sandbox, you have full Docker engine access, so we will use **Minikube** with the Docker driver.

```bash
minikube start --driver=docker
```
*Wait a minute or two for the cluster to fully provision.* Verify the node is ready:

```bash
kubectl get nodes
```

---

## Task 2 — Pods & Deployments (Day 2)

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

## Task 3 — Services and Networking (Day 3)

Pods die and get new IPs. A **Service** provides a stable IP or port to reach them. We will create a `ClusterIP` (internal access only) and a `NodePort` (external access).

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

## Task 4 — ConfigMaps and Storage (Day 4)

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

Now, let's mount this ConfigMap into a new Pod so Nginx serves our custom HTML!
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

Wait until it runs, then test it from inside the cluster using port-forwarding:
```bash
kubectl port-forward pod/config-demo-pod 8080:80 &
curl http://localhost:8080
```
*(Press Enter to return to the prompt after checking the output, then `kill %1` to stop port-forwarding).*

---

## Task 5 — Cleanup
It is crucial to keep your cluster clean. Delete the resources we created:

```bash
kubectl delete -f config-pod.yaml
kubectl delete -f app-config.yaml
kubectl delete -f nodeport-service.yaml
kubectl delete -f deployment.yaml
```

You are now ready for the **E-Commerce Capstone Project**!
