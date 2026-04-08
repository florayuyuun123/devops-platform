#!/bin/bash
cd /home/devops/devops-platform
NEW=$(grep -o 'https://[a-zA-Z0-9._-]*\.trycloudflare\.com' /tmp/devops-tunnel.log | tail -1)
OLD=$(grep -o 'https://[a-zA-Z0-9._-]*\.trycloudflare\.com' portal/index.html | head -1)
echo "OLD: $OLD"
echo "NEW: $NEW"
if [ -n "$NEW" ] && [ "$OLD" != "$NEW" ]; then
  sed -i "s|$OLD|$NEW|g" portal/index.html
  git add portal/index.html
  git commit -m "Auto-fix: live tunnel URL $NEW"
  git push origin main
  echo "SUCCESS: Portal updated to $NEW"
else
  echo "INFO: URL unchanged or tunnel not ready"
fi
