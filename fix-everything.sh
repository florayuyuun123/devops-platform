#!/bin/bash
# DevOps Platform Master Restoration Script (v3.1)
# ONE command — handles everything including URL sync after reboot.

set -e
PROJECT_ROOT="/home/devops/devops-platform"
cd "$PROJECT_ROOT"

echo "🚀 DevOps Platform — Full Restoration Starting..."
echo "=================================================="

# 1. Clean Slate
echo ""
echo "🧹 Step 1/5: Clearing old containers..."
sudo docker rm -f $(sudo docker ps -aq) 2>/dev/null || true

# 2. Reset Persistence
echo "💾 Step 2/5: Resetting session memory..."
rm -f "$PROJECT_ROOT/api/sandboxes.json"

# 3. Pull Latest Code
echo "📥 Step 3/5: Pulling latest fixes from GitHub..."
git fetch origin main
git reset --hard origin/main

# 4. Restart Services
echo "🔌 Step 4/5: Restarting API and Tunnel services..."
sudo systemctl restart devops-api
sudo systemctl restart devops-tunnel

# 5. Wait for Tunnel URL and auto-update portal
echo ""
echo "⏳ Step 5/5: Waiting for Cloudflare Tunnel URL..."
echo "   (This may take up to 60 seconds — please wait)"

TUNNEL_URL=""
for i in $(seq 1 60); do
    # Clear old log and wait for fresh URL
    TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/devops-tunnel.log 2>/dev/null | tail -1)
    if [ -n "$TUNNEL_URL" ]; then
        echo "   ✅ Tunnel online: $TUNNEL_URL"
        break
    fi
    printf "   Attempt $i/60...\r"
    sleep 1
done

if [ -z "$TUNNEL_URL" ]; then
    echo ""
    echo "⚠️  WARNING: Tunnel URL not found after 60s."
    echo "   Try running: sudo systemctl status devops-tunnel"
    exit 1
fi

# Update the portal URL
echo ""
echo "🔗 Updating portal with new tunnel URL..."
OLD_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' portal/index.html | head -1)

if [ -n "$OLD_URL" ] && [ "$OLD_URL" != "$TUNNEL_URL" ]; then
    sed -i "s|$OLD_URL|$TUNNEL_URL|g" portal/index.html
    git add portal/index.html
    git commit -m "Auto-Recovery: New tunnel URL after reboot → $TUNNEL_URL"
    git push origin main
    echo "   ✅ Portal updated and pushed to GitHub!"
    echo ""
    echo "=================================================="
    echo "✅ ALL DONE! Platform is fully restored."
    echo "=================================================="
    echo ""
    echo "⏳ IMPORTANT: Wait 2 minutes for GitHub Pages to update."
    echo "   Then open your portal and log in:"
    echo "   👉 https://florayuyuun123.github.io/devops-platform/portal/"
    echo ""
    echo "   New backend URL: $TUNNEL_URL"
    echo ""
else
    echo "   ✅ Portal URL is already up to date."
    echo ""
    echo "=================================================="
    echo "✅ ALL DONE! Platform is fully restored."
    echo "=================================================="
    echo ""
    echo "   Open your portal and log in:"
    echo "   👉 https://florayuyuun123.github.io/devops-platform/portal/"
    echo ""
fi
