#!/bin/bash
# Script to run cloudflared tunnel and update the portal URL automatically
# This is used by the devops-tunnel.service

PROJECT_ROOT="/home/devops/devops-platform"
cd "$PROJECT_ROOT"

# Log file for tunnel
TUNNEL_LOG="/tmp/devops-tunnel.log"
rm -f "$TUNNEL_LOG"

# Start cloudflared in the background within this script
cloudflared tunnel --url http://localhost:8080 > "$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!

# Function to cleanup on service stop
cleanup() {
    kill $TUNNEL_PID
    exit 0
}
trap cleanup SIGTERM SIGINT

echo "Waiting for Cloudflare Tunnel URL..."
for i in {1..60}; do
    TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$TUNNEL_LOG" | head -1)
    if [ -n "$TUNNEL_URL" ]; then
        echo "New Tunnel URL: $TUNNEL_URL"
        
        # Update the portal index.html
        OLD_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' portal/index.html | head -1)
        if [ -n "$OLD_URL" ] && [ "$OLD_URL" != "$TUNNEL_URL" ]; then
            sed -i "s|$OLD_URL|$TUNNEL_URL|g" portal/index.html
            git add portal/index.html
            git commit -m "Systemd auto-update: $TUNNEL_URL"
            git push origin main
            echo "Portal updated and pushed."
        fi
        break
    fi
    sleep 2
done

# Keep script running while the tunnel is alive
wait $TUNNEL_PID
