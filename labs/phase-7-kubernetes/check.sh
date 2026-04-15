#!/bin/bash
# Phase 7 Kubernetes Automated Validation

# 1. Cluster Provisioning
STATUS_CLUSTER="running"
if kubectl get nodes >/dev/null 2>&1; then
    STATUS_CLUSTER="success"
fi

# 2. Pods & Deployment (Target: 5 replicas)
STATUS_REPLICAS="running"
if kubectl get deployment nginx-deployment >/dev/null 2>&1; then
    READY=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.readyReplicas}')
    TOTAL=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.replicas}')
    if [ "$READY" == "5" ]; then STATUS_REPLICAS="success"; fi
fi

# 3. NodePort Service
STATUS_SERVICE="running"
if kubectl get svc nginx-nodeport >/dev/null 2>&1; then
    NP=$(kubectl get svc nginx-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
    if [ "$NP" == "30080" ]; then STATUS_SERVICE="success"; fi
fi

# 4. ConfigMaps
STATUS_CONFIG="running"
if kubectl get cm app-config >/dev/null 2>&1; then
    STATUS_CONFIG="success"
fi

# Output JSON for Platform UI
cat <<EOF
{
  "stages": [
    {"id": "s1", "name": "Cluster (Minikube)", "status": "$STATUS_CLUSTER"},
    {"id": "s2", "name": "Nginx (5 Replicas)", "status": "$STATUS_REPLICAS"},
    {"id": "s3", "name": "NodePort (30080)", "status": "$STATUS_SERVICE"},
    {"id": "s4", "name": "App ConfigMap", "status": "$STATUS_CONFIG"}
  ]
}
EOF
