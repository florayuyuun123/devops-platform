# Networking, SSH & Firewalls

You cannot bridge the gap from a SysAdmin to a DevOps Engineer without mastering networking. In the cloud, every resource (server, database, load balancer) is just an IP address on a network. 

---

## Task 1 — Orientation (Who can I see?)

### The Concept (What)
We use `ip addr` to find our local address, `ip route` to find our gateway, and `/etc/resolv.conf` to check our DNS servers.

### Real-world Context (Why)
If a server can't talk to a database, you first check if they're on the same network. If they can't browse the web, you check if they have a "gateway" (a way out).

### Execution (How)
Inspect your current sandbox network configuration.

```bash
ip addr show
```

```bash
ip route show
```

```bash
cat /etc/resolv.conf
```

---

## Task 2 — Testing Connectivity

### The Concept (What)
Using `ping` to check if a server is "alive" and `traceroute` to see the paths (routers) your data takes through the internet.

### Real-world Context (Why)
If a customer complains that your app is slow in South Africa but fast in Europe, you use `traceroute` to see if there's a "bad link" anywhere in the chain.

### Execution (How)
Ping Google's DNS and trace the path to Google.

```bash
ping -c 4 8.8.8.8
```

```bash
ping -c 4 google.com
```

*Note: If `ping google.com` fails but `ping 8.8.8.8` works, you have a **DNS** problem!*

---

## Task 3 — DNS Lookups

### The Concept (What)
DNS (Domain Name System) is the "phonebook" of the internet. We use `nslookup` and `dig` to find the IP address behind a domain name.

### Real-world Context (Why)
In DevOps, we often use "CNAME" records to point a domain (like `api.myapp.com`) to a load balancer. If the app is down, the first thing we check is if the DNS record is pointed correctly.

### Execution (How)
Query Google's domain information.

```bash
nslookup google.com
```

```bash
dig google.com
```

---

## Task 4 — Ports and Services

### The Concept (What)
Servers have 65,535 "ports." Think of them as doors to specific apps. `80/443` is for web, `22` is for SSH. We check these using `ss` and `curl`.

### Real-world Context (Why)
If you deploy a new web server and it's not responding, the firewall might be blocking Port 80. You use `ss -tlnp` to see if the app is actually listening on that port.

### Execution (How)
Check what ports are open on your sandbox.

```bash
ss -tlnp
```

```bash
curl -I https://google.com
```

---

## Task 5 — SSH Security

### The Concept (What)
SSH (Secure Shell) is how you remotely control servers. Instead of passwords, we use **SSH Keys** (a Private Key and a Public Key).

### Real-world Context (Why)
Passwords can be guessed or brute-forced. SSH Keys are thousands of times more secure and are mandatory in professional DevOps environments.

### Execution (How)
Generate your first secure SSH key pair.

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

```bash
cat ~/.ssh/id_ed25519.pub
```
*Note: This `.pub` file is your PUBLIC key. You can safely share this. Your private key (`id_ed25519`) must NEVER leave your machine.*

---

## Task 6 — Firewalls (UFW)

### The Concept (What)
A Firewall is a security guard for your ports. We use `ufw` (Uncomplicated Firewall) to block everyone except specific people.

### Real-world Context (Why)
If you leave Port 22 (SSH) open to the whole world, hackers will try to log in every second. A good DevOps setup only allows your specific IP to use SSH.

### Execution (How)
Allow SSH and HTTP traffic, then turn the firewall on.

```bash
sudo ufw allow 22/tcp
```

```bash
sudo ufw allow 80/tcp
```

```bash
sudo ufw status
```

---

## Challenge
Find out what port `nginx` listens on by default (HINT: it's for the web). Then check if anything is listening on that port on your sandbox right now using the `ss` command from Task 4.
