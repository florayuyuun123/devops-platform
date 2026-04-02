#!/bin/bash
# DevOps Platform — Offline Node Installer
# Turns any Ubuntu 22.04 machine into a standalone learning node.
# Students connect to it over WiFi — no internet needed.

set -e
REPO="https://github.com/florayuyuun123/devops-platform"
PLATFORM_DIR="/opt/devops-platform"

echo "================================================"
echo "  DevOps Platform — Offline Node Setup"
echo "================================================"

sudo apt-get update -y
sudo apt-get install -y docker.io docker-compose curl git python3-pip nginx

sudo mkdir -p $PLATFORM_DIR
sudo chown $USER:$USER $PLATFORM_DIR
git clone $REPO $PLATFORM_DIR 2>/dev/null || git -C $PLATFORM_DIR pull

docker pull ghcr.io/florayuyuun123/devops-platform/devops-sandbox:latest 2>/dev/null ||   docker build -t devops-sandbox:latest $PLATFORM_DIR/sandbox

pip3 install fastapi uvicorn python-multipart 2>/dev/null

sudo tee /etc/nginx/sites-available/devops-platform > /dev/null << 'NGINXEOF'
server {
    listen 80 default_server;
    root /opt/devops-platform/portal;
    index index.html;
    location / { try_files $uri $uri/ /index.html; }
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
    }
    location /terminal/ {
        proxy_pass http://localhost:7681/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINXEOF

sudo ln -sf /etc/nginx/sites-available/devops-platform             /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

sudo tee /etc/systemd/system/devops-api.service > /dev/null << 'SVCEOF'
[Unit]
Description=DevOps Platform API
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/devops-platform/api
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8080
Restart=always

[Install]
WantedBy=multi-user.target
SVCEOF

sudo systemctl daemon-reload
sudo systemctl enable --now devops-api

LOCAL_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "================================================"
echo "  Offline node ready!"
echo "  Students open: http://$LOCAL_IP"
echo "================================================"
