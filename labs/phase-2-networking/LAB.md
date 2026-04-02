# Networking, SSH & firewalls

## Why this matters
You cannot debug production issues without understanding networking.
This comes up in every DevOps and SRE interview.

---

## Task 1 — Inspect your network
```bash
ip addr show          # your IP addresses
ip route show         # routing table
cat /etc/resolv.conf  # DNS servers
```

## Task 2 — Test connectivity
```bash
ping -c 4 8.8.8.8          # ping Google DNS
ping -c 4 google.com       # tests DNS resolution + connectivity
traceroute google.com      # trace the network path
```

## Task 3 — DNS lookups
```bash
nslookup google.com        # basic DNS query
dig google.com             # detailed DNS query
dig google.com MX          # mail records
dig @8.8.8.8 google.com    # query specific DNS server
```

## Task 4 — Ports and services
```bash
ss -tlnp                   # show listening TCP ports
ss -ulnp                   # show listening UDP ports
curl -I https://google.com # HTTP headers — tests port 443
nc -zv google.com 443      # test if port 443 is open
```

## Task 5 — SSH basics
```bash
# Generate an SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub   # this is your PUBLIC key — safe to share
# Private key stays on your machine — NEVER share it
```

## Task 6 — Firewall rules (ufw)
```bash
sudo ufw status
sudo ufw allow 22/tcp       # allow SSH
sudo ufw allow 80/tcp       # allow HTTP
sudo ufw enable
sudo ufw status verbose
```

## Challenge
Find out what port `nginx` listens on by default, then check if anything
is listening on that port on your sandbox right now.
