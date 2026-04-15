# Kubernetes — Container Orchestration at Scale

Kubernetes (often called K8s) is the industry standard for running containerized applications. While Docker runs a single container, Kubernetes orchestrates thousands of containers across hundreds of servers intelligently. It is one of the most critical skills on a DevOps resume today.

---

## Task 1 — Provision the Local Cluster

### The Concept
Before interacting with Kubernetes, you need a running cluster. In this sandbox, we use **Minikube**, which creates a local, lightweight Kubernetes cluster inside Docker.

### Execution
Start the Minikube cluster using the Docker driver. This will take a few moments to provision your local node.

```bash
minikube start --driver=docker
```

Once it completes, verify that your node is ready and you can reach the cluster:

```bash
kubectl get nodes
```

---

## Task 2 — Working with Pods

### The Concept
A **Pod** is the smallest deployable unit in Kubernetes. It encapsulates one or more containers (usually just one) and provides them with shared storage and network resources.

### Execution
Examine and deploy `nginx-pod.yaml`. It defines a single Pod running the `nginx` image.

```bash
cat > nginx-pod.yaml << 'K8EOF'
apiVersion: v1
kind: Pod
metadata:
  name: sample-pod
spec:
  containers:
    - name: nginx-container
      image: nginx
      ports:
        - containerPort: 80
K8EOF
```

Apply the configuration to your cluster:

```bash
kubectl apply -f nginx-pod.yaml
```

Check the status of your pod:

```bash
kubectl get pods
```

View detailed creation events (essential for debugging):

```bash
kubectl describe pod sample-pod
```

View the IP and Node assignment given to the Pod:

```bash
kubectl get pod -o wide
```

---

## Task 3 — Working with Deployments

### The Concept
A **Deployment** is a manager that controls your Pods. Instead of manually starting and monitoring containers, you tell a Deployment what you want (e.g., "I want 3 Nginx replicas running"), and it continuously ensures that exact state exists. If a node crashes, the Deployment immediately spins up new Pods elsewhere.

### Execution
Define a Deployment in `nginx-deployment.yaml` for 3 replicas:

```bash
cat > nginx-deployment.yaml << 'DEPEOF'
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
DEPEOF
```

Apply the deployment:

```bash
kubectl apply -f nginx-deployment.yaml
```

Verify the deployment and the ReplicaSets it manages:

```bash
kubectl get deployments
```

```bash
kubectl get replicasets
```

See all the managed pods spanning up:

```bash
kubectl get pods
```

---

## Task 4 — Scaling and Introspection

### The Concept
Deployments make scaling applications effortless. If your app experiences a spike in traffic, you can increase the replica count in seconds.

### Execution
Scale your deployment up to 5 replicas:

```bash
kubectl scale deployment nginx-deployment --replicas=5
```

Watch the new pods being created in real time (use `Ctrl+C` to exit):

```bash
kubectl get pods --watch
```

List pods across *all namespaces* to see the core Kubernetes systems running:

```bash
kubectl get pods -A
```

---

## Task 5 — Cleanup

Delete the resources to free up the cluster. It's best practice to keep your cluster clean.

```bash
# Delete the individual pod
kubectl delete pod sample-pod
```

```bash
# Delete the deployment (which automatically deletes its 5 managed pods)
kubectl delete deployment nginx-deployment
```

Verify everything is removing gracefully:

```bash
kubectl get pods
```

---

## Challenge
Can you scale a deployment to **0** replicas? Try re-applying your `nginx-deployment.yaml`, then run `kubectl scale deployment nginx-deployment --replicas=0`. Check `kubectl get pods` to see what happens. This is how we gracefully shut down applications for maintenance!
