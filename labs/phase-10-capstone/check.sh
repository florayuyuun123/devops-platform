#!/bin/bash
# Phase 10 Capstone Automated Validation

# 1. Namespace
STATUS_NS="running"
if kubectl get ns ecommerce >/dev/null 2>&1; then
    STATUS_NS="success"
fi

# 2. ConfigMap
STATUS_CM="running"
if kubectl get cm ecommerce-html -n ecommerce >/dev/null 2>&1; then
    STATUS_CM="success"
fi

# 3. Secure Deployment
STATUS_DEP="running"
if kubectl get deployment ecommerce-app -n ecommerce >/dev/null 2>&1; then
    READY=$(kubectl get deployment ecommerce-app -n ecommerce -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" -ge 1 ]; then STATUS_DEP="success"; fi
fi

# 4. Service / NodePort
STATUS_SVC="running"
if kubectl get svc ecommerce-service -n ecommerce >/dev/null 2>&1; then
    NP=$(kubectl get svc ecommerce-service -n ecommerce -o jsonpath='{.spec.ports[0].nodePort}')
    if [ "$NP" == "30082" ]; then STATUS_SVC="success"; fi
fi

# Output JSON
cat <<EOF
{
  "stages": [
    {"id": "c1", "name": "Namespace: ecommerce", "status": "$STATUS_NS"},
    {"id": "c2", "name": "Frontend ConfigMap", "status": "$STATUS_CM"},
    {"id": "c3", "name": "Secure Deployment", "status": "$STATUS_DEP"},
    {"id": "c4", "name": "NodePort 30082", "status": "$STATUS_SVC"}
  ]
}
EOF
