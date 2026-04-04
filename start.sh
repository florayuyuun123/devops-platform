#!/bin/bash
# Start the DevOps platform
# Run this every time your machine starts

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}Starting DevOps Learning Platform...${NC}"

# Fix Docker permissions
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

# Copy labs
cd ~/devops-platform
rm -rf api/labs
cp -r labs api/labs
echo -e "${GREEN}Labs copied${NC}"

# Kill anything on port 8080
sudo kill -9 $(sudo lsof -t -i:8080) 2>/dev/null || true
sleep 1

# Start API in background
cd ~/devops-platform/api
python3 -m uvicorn main:app --host 0.0.0.0 --port 8080 &
API_PID=$!
echo -e "${GREEN}API started (PID $API_PID)${NC}"
sleep 3

# Test API
if curl -s http://localhost:8080/health > /dev/null; then
    echo -e "${GREEN}API is healthy${NC}"
else
    echo "API failed to start"
    exit 1
fi

# Start tunnel and capture URL
echo -e "${GREEN}Starting Cloudflare tunnel...${NC}"
TUNNEL_LOG=$(mktemp)
cloudflared tunnel --url http://localhost:8080 > "$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!

# Wait for tunnel URL
echo "Waiting for tunnel URL..."
for i in $(seq 1 30); do
    TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$TUNNEL_LOG" 2>/dev/null | head -1)
    if [ -n "$TUNNEL_URL" ]; then
        break
    fi
    sleep 1
done

if [ -z "$TUNNEL_URL" ]; then
    echo "Tunnel URL not found - check manually"
    exit 1
fi

echo -e "${GREEN}Tunnel URL: $TUNNEL_URL${NC}"

# Update portal with new tunnel URL
cd ~/devops-platform
OLD_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' portal/index.html | head -1)
if [ -n "$OLD_URL" ] && [ "$OLD_URL" != "$TUNNEL_URL" ]; then
    sed -i "s|$OLD_URL|$TUNNEL_URL|g" portal/index.html
    git add portal/index.html
    git commit -m "Auto-update tunnel URL to $TUNNEL_URL"
    git push origin main
    echo -e "${GREEN}Portal updated and pushed${NC}"
else
    echo -e "${GREEN}Tunnel URL unchanged - no push needed${NC}"
fi

echo ""
echo -e "${CYAN}Platform is live!${NC}"
echo -e "  Portal: https://florayuyuun123.github.io/devops-platform"
echo -e "  API:    $TUNNEL_URL"
echo -e "  PIDs:   API=$API_PID  Tunnel=$TUNNEL_PID"
echo ""
echo "To stop: kill $API_PID $TUNNEL_PID"
