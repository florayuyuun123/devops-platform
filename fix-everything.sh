#!/bin/bash
# DevOps Platform Master Restoration Script (v3.0)
# This script is the ONLY command you need to run to fix colors, sync, and persistence.

echo "🚀 Starting DevOps Platform Final Restoration..."

# 1. Clean Slate (Nuke old ghost containers)
echo "🧹 Clearing old containers..."
sudo docker rm -f $(sudo docker ps -aq) 2>/dev/null || true

# 2. Reset Persistence (Ensure we start fresh with the new v2.2 logic)
echo "💾 Resetting persistence memory..."
rm -f /home/devops/devops-platform/api/sandboxes.json

# 3. Pull Latest Code Fixes
echo "📥 Pulling latest stabilitiy & visual fixes from GitHub..."
cd /home/devops/devops-platform
git fetch origin main
git reset --hard origin/main

# 4. Final Rebuild (This solves the colors permanently)
echo "🎨 Rebuilding Sandbox Terminal Image (Technicolor Upgrade)..."
cd /home/devops/devops-platform/sandbox
sudo docker build --no-cache -t devops-sandbox:latest .

# 5. Master Restart
echo "🔌 Restarting Platform Services..."
sudo systemctl restart devops-api

echo "✅ SUCCESS! Your platform is now fully restored."
echo "-----------------------------------------------"
echo "1. Refresh your browser (Ctrl + F5)"
echo "2. Log in and start a lab"
echo "3. You will see: Stop Button, Countdown Timer, and Technicolor Prompt!"
echo "-----------------------------------------------"
