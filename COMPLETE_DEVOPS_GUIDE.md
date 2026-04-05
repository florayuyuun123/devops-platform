# COMPLETE DEVOPS PLATFORM GUIDE

<!-- File: README.md -->
# DevOps Learning Platform

Free, offline-capable, hands-on DevOps training.
Built for students with limited internet access and no expensive cloud accounts.

## Live platform
- Portal: https://florayuyuun123.github.io/devops-platform

## Curriculum — 10 phases
1. Linux fundamentals
2. Networking & security
3. Git & version control
4. Docker & containers
5. CI/CD pipelines
6. Ansible automation
7. Kubernetes
8. Terraform / IaC
9. Monitoring & observability
10. Capstone project

## Deploy your own copy
```bash
git clone https://github.com/florayuyuun123/devops-platform
cd devops-platform
# Follow SETUP.md
```

## Offline classroom node
```bash
curl -s https://raw.githubusercontent.com/florayuyuun123/devops-platform/main/offline-node/install.sh | bash
```

## Cost: $0
GitHub Pages (portal) + Local API over Tunnel + optional offline node.

---

<!-- File: phase-1-linux/LAB.md -->
# Linux File System & Permissions

Welcome to your first step in the DevOps journey! Linux is the engine of the modern internet. Whether a server is in the cloud (AWS/Azure) or in a data center, it's almost certainly running Linux. 

---

## Task 1 — Orientation (Where am I?)

### The Concept (What)
We're going to use the `pwd` command to find our current location and `ls` to see what is around us.

### Real-world Context (Why)
In DevOps, you'll often log into remote servers to fix bugs. The first thing you *must* do is verify which folder you're in so you don't accidentally delete the wrong files.

### Execution (How)
Run these commands in your terminal now.

```bash
pwd
```

```bash
ls -la
```

*Note: `ls -la` shows **all** files, including those starting with a `.`, which are often hidden configuration files.*

---

## Task 2 — Navigating the System

### The Concept (What)
We use the `cd` (Change Directory) command to move between folders like `/etc` (Configuration) and `/var/log` (System logs).

### Real-world Context (Why)
If an application is crashing, the first place a DevOps Engineer looks is `/var/log`. If you need to change a server's setting, it's almost always in `/etc`.

### Execution (How)
Try moving into these critical system folders.

```bash
cd /etc && ls
```

```bash
cd /var/log && ls
```

```bash
cd ~
```
*Note: The `~` symbol is a shortcut for your **Home** directory.*

---

## Task 3 — File Management

### The Concept (What)
Creating, editing, moving, and deleting files using `mkdir`, `touch`, `echo`, `cp`, `mv`, and `rm`.

### Real-world Context (Why)
Automation involves creating configuration files (like `server.conf`) and moving them into the right places for your apps to run.

### Execution (How)
Let's build a small workspace and manage some files.

```bash
mkdir ~/workspace && cd ~/workspace
```

```bash
touch server.conf app.py deploy.sh
```

```bash
echo "PORT=8080" > server.conf
```

```bash
cat server.conf
```

```bash
cp server.conf server.conf.bak
```

```bash
rm server.conf.bak
```

---

## Task 4 — The Power of Permissions

### The Concept (What)
Every file in Linux has an owner and a set of permissions (Read, Write, Execute). We change these using `chmod`.

### Real-world Context (Why)
Security is a core part of DevOps. You don't want a "guest" user to be able to read your database passwords! We use `chmod 600` for sensitive secrets and `chmod 755` for scripts we want to run.

### Execution (How)
Let's secure our `server.conf` and make our `deploy.sh` runnable.

```bash
chmod 600 server.conf
```

```bash
chmod 755 deploy.sh
```

```bash
ls -la
```

*Note: In `ls -la`, `rwx` means read, write, execute. `600` gives only the owner read/write access.*

---

## Task 5 — Searching and Troubleshooting

### The Concept (What)
Using `grep` to find text inside files and `find` to locate misplaced files.

### Real-world Context (Why)
Imagine a log file with 1 million lines. You can't read it all! You use `grep` to find specifically where the "ERROR" happened.

### Execution (How)
Find the port we defined earlier.

```bash
grep "PORT" server.conf
```

---

## Challenge
Set `server.conf` to `400` (read-only, even for you). Then try to edit it or delete it. What happens? This is exactly how we protect critical system files from accidental changes.

---

<!-- File: phase-2-networking/LAB.md -->
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

---

<!-- File: phase-3-git/LAB.md -->
# Git Version Control & GitHub Flow

In DevOps, we treat everything as code—even our servers. If it's not in Git, it doesn't exist. Git is your "Save Game" button and your "Undo" button for your entire career.

---

## Task 1 — Configuring Your Identity

### The Concept (What)
We tell Git who we are using `git config`.

### Real-world Context (Why)
When something breaks in production at 3:00 AM, the `git blame` command tells the team exactly who wrote that line of code. If your name isn't on it, they can't call you for help!

### Execution (How)
Configure your global identity on this machine.

```bash
git config --global user.name "Your Name"
```

```bash
git config --global user.email "you@example.com"
```

```bash
git config --global init.defaultBranch main
```

---

## Task 2 — Creating Your First Repository

### The Concept (What)
A "Repository" (or Repo) is a folder that Git is watching. We use `git init` to start watching and `git commit` to save a snapshot.

### Real-world Context (Why)
If you make a mistake today, you can use Git to travel back in time to yesterday's perfect version. This is how we safely update apps used by millions of people.

### Execution (How)
Initialize a new project and make your first commit.

```bash
mkdir my-app && cd my-app
```

```bash
git init
```

```bash
echo "# My App" > README.md
```

```bash
echo "PORT=8080" > .env
```

```bash
echo ".env" > .gitignore
```
*Note: We add `.env` to `.gitignore` so we NEVER accidentally share our private keys or passwords on the internet.*

```bash
git add README.md .gitignore
```

```bash
git commit -m "Initial commit"
```

---

## Task 3 — Branching (The Daily Workflow)

### The Concept (What)
A "Branch" is a parallel version of your code. You work on a branch so you don't break the "Main" version that customers are using.

### Real-world Context (Why)
At a job, you *never* work directly on `main`. You create a branch (like `feature/add-login`), finish your work, and then merge it back once it's tested.

### Execution (How)
Create a new feature branch and merge it.

```bash
git checkout -b feature/add-config
```

```bash
echo "DEBUG=false" >> README.md
```

```bash
git add .
```

```bash
git commit -m "Add debug config"
```

```bash
git checkout main
```

```bash
git merge feature/add-config
```

---

## Task 4 — Undoing Mistakes

### The Concept (What)
Using `git reset` and `git checkout` to throw away bad code you haven't committed yet.

### Real-world Context (Why)
Everyone makes mistakes. If you accidentally delete a critical file or break a configuration, Git can restore it instantly.

### Execution (How)
Create a "mistake" and undo it.

```bash
echo "oops" > mistake.txt
```

```bash
git add mistake.txt
```

```bash
git reset HEAD mistake.txt
```

```bash
git checkout -- mistake.txt 2>/dev/null || true
```

---

## Task 5 — Reading History

### The Concept (What)
Using `git log` and `git diff` to see what happened in the past.

### Real-world Context (Why)
If a server starts crashing today, you check `git log` to see exactly what changed in the last 24 hours. Most bugs are caused by recent changes!

### Execution (How)
Inspect your project's history.

```bash
git log --oneline --graph --all
```

```bash
git diff HEAD~1 HEAD
```

---

## Challenge
Create a branch called `fix/typo`, make a small change to `README.md`, commit it, then merge it back into `main` and delete the branch. Use `git log --oneline --graph` to see your beautiful merge history.

---

<!-- File: phase-4-docker/LAB.md -->
# Docker Containers & Images

Docker is the most important tool in modern DevOps. If you master Docker, you are instantly employable. It solves the famous "It works on my machine" problem by package applications into portable "Containers."

---

## Task 1 — Your First Container

### The Concept (What)
A **Container** is a lightweight, standalone package that includes everything needed to run an application. We run them using `docker run`.

### Real-world Context (Why)
Before Docker, setting up a new developer's laptop took days. With Docker, it takes 5 seconds because the entire environment is already inside the container.

### Execution (How)
Run a simple "Hello-world" and then dive into a full Ubuntu Linux container.

```bash
docker run hello-world
```

```bash
docker run -it ubuntu:22.04 bash
```
*Note: Inside the container, you are a "root" user in a completely isolated world. Type `exit` to come back to your sandbox.*

---

## Task 2 — Running a Web Service (Nginx)

### The Concept (What)
We can run background services (like a web server) using the `-d` (detached) flag and map ports using `-p`.

### Real-world Context (Why)
In a real company, you don't just run one app. You run 50 copies of your app, each in its own container, all controlled by a central system.

### Execution (How)
Run an Nginx web server and test it.

```bash
docker run -d -p 8081:80 --name my-web nginx
```

```bash
docker ps
```

```bash
curl http://localhost:8081
```

```bash
docker stop my-web && docker rm my-web
```

---

## Task 3 — Building Your Own Image (Dockerfile)

### The Concept (What)
A **Dockerfile** is a recipe for building your own custom image. We use `docker build` to turn this recipe into a reusable "Image."

### Real-world Context (Why)
Developers write the code, and DevOps Engineers write the Dockerfile to ensure that code runs perfectly in production.

### Execution (How)
Create a simple Python app and build a Docker image for it.

```bash
mkdir -p ~/my-app && cd ~/my-app
```

```bash
cat > app.py << 'APPEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Hello from my DevOps app!")
HTTPServer(('', 8080), Handler).serve_forever()
APPEOF
```

```bash
cat > Dockerfile << 'DFEOF'
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
EXPOSE 8080
CMD ["python3", "app.py"]
DFEOF
```

```bash
docker build -t my-app:v1 .
```

```bash
docker run -d -p 8082:8080 --name my-run-app my-app:v1
```

```bash
curl http://localhost:8082
```

---

## Task 4 — Multi-Container Apps (Docker Compose)

### The Concept (What)
**Docker Compose** allows you to start multiple containers at once (e.g., a Web App + a Database) using a single YAML file.

### Real-world Context (Why)
Most apps aren't just one file; they need databases, caches, and queues. Docker Compose "orchestrates" them so they can all talk to each other automatically.

### Execution (How)
Launch a web server and your custom API together.

```bash
cat > docker-compose.yml << 'DCEOF'
version: "3.9"
services:
  web:
    image: nginx:alpine
    ports:
      - "8083:80"
  api:
    image: my-app:v1
    ports:
      - "8084:8080"
DCEOF
```

```bash
docker compose up -d
```

```bash
docker compose ps
```

```bash
docker compose down
```

---

## Challenge
Find out how to list only the **IDs** of your containers (HINT: use `docker ps -aq`). This is a very common command used in automation scripts!

---

<!-- File: phase-5-cicd/LAB.md -->
# CI/CD Pipelines with GitHub Actions

CI/CD is the heart of DevOps. It is how professional teams "ship" software safely and quickly. If you can build and maintain a pipeline, you are essentially a full-fledged DevOps Engineer.

---

## Task 1 — The Pipeline Concept (The "Factory Line")

### The Concept (What)
A **Pipeline** is a series of automated steps that run whenever code is pushed. If the steps pass, the code is "shipped." If they fail, the pipeline stops to protect the app.

### Real-world Context (Why)
At a company, you might have 100 developers. You cannot manually check every single line of code! A pipeline acts as a 24/7 security guard that tests everything automatically.

### Execution (How)
1. **Build** — Packaging the code (like creating a Docker image).
2. **Test** — Running automated scripts to find bugs.
3. **Deploy** — Sending the finished app to the server.

---

## Task 2 — Your First Workflow (YAML)

### The Concept (What)
A **Workflow** is the YAML file that tells GitHub Actions *exactly* what to do.

### Real-world Context (Why)
Writing this file is your primary job. You are defining the "Rules of Engagement" for how software gets built at your company.

### Execution (How)
Create this file in your GitHub repo at `.github/workflows/ci.yml`.

```yaml
name: CI Pipeline

on:
  push:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install pytest

      - name: Run tests
        run: echo "No tests yet — but if I had them, I would run them here!"
```

---

## Task 3 — Automated Docker Builds

### The Concept (What)
We add a step to our pipeline to build a Docker image every time we push code.

### Real-world Context (Why)
You want to know *immediately* if a developer's change "broke the build." If the Docker build fails in the pipeline, it won't break the actual website for customers.

### Execution (How)
Add this step to your `ci.yml` file under the others.

```yaml
      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .
```
*Note: `${{ github.sha }}` is a unique ID for every commit. This ensures every version of your app has its own unique name.*

---

## Task 4 — Deployment (CD)

### The Concept (What)
**Continuous Deployment (CD)** is the final step where the successfully tested code is pushed to a live server.

### Real-world Context (Why)
"Time to Market" is critical. If a developer fixes a bug at 9:00 AM, the pipeline can have it live for customers by 9:05 AM without any human manager needing to click "Go."

### Execution (How)
An example of how a deployment block looks in GitHub Actions.

```yaml
  deploy-staging:
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to staging
        run: |
          echo "Deploying to staging server..."
          echo "Commit: ${{ github.sha }}"
```

---

## Task 5 — Secrets (Security First)

### The Concept (What)
**GitHub Secrets** allow you to hide your passwords and API keys from the public, while still letting the pipeline use them.

### Real-world Context (Why)
If you hardcode a password in a public GitHub repo, a bot will find it and hack you in less than 60 seconds. **NEVER** put secrets in your code. Put them in the GitHub Settings > Secrets tab instead.

---

## Challenge
Find out how to add a "Status Badge" (a small green icon) to your README.md file that shows if your pipeline is passing or failing. This is a "badge of honor" for any professional repository!

---

<!-- File: phase-6-ansible/LAB.md -->
# Ansible Configuration Management

Automation is the secret sauce of DevOps. Instead of typing the same 50 commands on 50 different servers, you write one "Playbook" and let Ansible do the work for you.

---

## Task 1 — The Inventory (Who am I talking to?)

### The Concept (What)
An **Inventory** is a simple list of the servers you want to manage.

### Real-world Context (Why)
At a big company, you might have `[webservers]`, `[databases]`, and `[testing]`. This file keeps them organized so you can target one group without touching the others.

### Execution (How)
Let's create our first inventory file. We are using `127.0.0.1` (your local sandbox) as the target.

```bash
mkdir -p ~/ansible-lab && cd ~/ansible-lab
```

```bash
cat > inventory.ini << 'INVEOF'
[webservers]
web1 ansible_host=127.0.0.1 ansible_connection=local

[dbservers]
db1  ansible_host=127.0.0.1 ansible_connection=local

[all:vars]
ansible_user=student
INVEOF
```

**Verify the connection:**
```bash
ansible all -i inventory.ini -m ping
```

---

## Task 2 — The Playbook (What should I do?)

### The Concept (What)
A **Playbook** is a YAML file that lists the steps (Tasks) you want Ansible to perform.

### Real-world Context (Why)
This is "Infrastructure as Code." Instead of keeping a messy Word document of instructions, you keep this file in Git. If a server dies, you just run the playbook to build a perfect replacement in seconds.

### Execution (How)
Create a playbook to install `curl` and setup a directory.

```bash
cat > site.yml << 'PBEOF'
---
- name: Configure web servers
  hosts: webservers
  become: true

  tasks:
    - name: Ensure curl is installed
      apt:
        name: curl
        state: present

    - name: Create app directory
      file:
        path: /opt/myapp
        state: directory
        mode: '0755'
PBEOF
```

**Run the playbook:**
```bash
ansible-playbook -i inventory.ini site.yml
```

---

## Task 3 — Variables (Making it Reusable)

### The Concept (What)
Variables allow you to change settings (like a port number or app name) without editing the main code.

### Real-world Context (Why)
You might want the same app to run on Port 80 in "Production" but Port 8080 in "Testing." Variables make this possible.

### Execution (How)
Create a variable file and a deployment playbook.

```bash
cat > vars.yml << 'VAREOF'
app_port: 8080
app_name: devops-app
VAREOF
```

```bash
cat > deploy.yml << 'DEPEOF'
---
- name: Deploy application
  hosts: all
  vars_files:
    - vars.yml

  tasks:
    - name: Show deployment info
      debug:
        msg: "Deploying {{ app_name }} on port {{ app_port }}"
DEPEOF
```

**Run the deployment:**
```bash
ansible-playbook -i inventory.ini deploy.yml
```

---

## Task 4 — Roles (Professional Structure)

### The Concept (What)
**Roles** are like folders that keep your code clean and reusable across different projects.

### Real-world Context (Why)
Professional DevOps teams use roles so they can share code easily. You might have a "webserver" role used by 10 different departments at your company.

### Execution (How)
Initialize a new role and configure it.

```bash
ansible-galaxy init roles/webserver
```

```bash
cat > roles/webserver/tasks/main.yml << 'ROLEEOF'
---
- name: Install nginx
  apt:
    name: nginx
    state: present
  become: true
ROLEEOF
```

---

## Challenge
Write an Ansible playbook that creates a user named `junior-dev`. Run it twice. Did it try to create the user again on the second run? This "intelligence" (only doing work if needed) is called **Idempotency**.

---

<!-- File: phase-7-kubernetes/LAB.md -->
# Kubernetes — Container Orchestration at Scale

Kubernetes (often called K8s) is the industry standard for running containerized apps. While Docker runs one container, Kubernetes runs *thousands* of containers across hundreds of servers. It is the most valuable skill on a DevOps resume today.

---

## Task 1 — Core Architecture (The "Team")

### The Concept (What)
- **Pod** — The smallest unit (like a single worker).
- **Deployment** — The manager that ensures you always have the right number of workers.
- **Service** — The "Phone Number" used to reach your workers.
- **Node** — the physical or virtual server where the workers live.

### Real-world Context (Why)
If a server crashes in the middle of the night, Kubernetes notices instantly. It will automatically move your "Pods" to a healthy server before your customers even notice something went wrong.

### Execution (How)
Explore the cluster using `kubectl`.

```bash
kubectl get nodes
```

```bash
kubectl get namespaces
```

```bash
kubectl get pods -A
```

---

## Task 2 — Your First Deployment

### The Concept (What)
A **Deployment** is a YAML file that describes the "Desired State" of your app (e.g., "I want 3 copies of Nginx running").

### Real-world Context (Why)
Instead of manually starting 3 containers, you tell Kubernetes what you want, and it *guarantees* that state. If one container dies, Kubernetes starts a new one automatically.

### Execution (How)
Create and apply your first deployment.

```bash
cat > deployment.yml << 'K8EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:alpine
        ports:
        - containerPort: 80
K8EOF
```

```bash
kubectl apply -f deployment.yml
```

```bash
kubectl get pods
```

---

## Task 3 — Exposing with a Service

### The Concept (What)
A **Service** provides a single, stable IP address or name to reach your group of Pods.

### Real-world Context (Why)
Pods are temporary; they get deleted and recreated with new IP addresses all the time. A Service acts like a "Front Desk" that always knows where to find the active Pods.

### Execution (How)
Create a Service to route traffic to your 3 Nginx pods.

```bash
cat > service.yml << 'SVCEOF'
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
SVCEOF
```

```bash
kubectl apply -f service.yml
```

```bash
kubectl get services
```

---

## Task 4 — Scaling and Rollbacks

### The Concept (What)
Scaling is changing the number of running pods. A Rollback is "undoing" a bad update.

### Real-world Context (Why)
If your app goes viral on TikTok, you can scale from 3 pods to 300 pods in seconds. If you push a bad update that breaks the site, you can "Rollback" to the previous working version instantly.

### Execution (How)
Scale your app to 5 replicas and then practice an update.

```bash
kubectl scale deployment my-app --replicas=5
```

```bash
kubectl get pods
```

```bash
kubectl rollout history deployment/my-app
```

---

## Task 5 — Debugging (Investigation)

### The Concept (What)
Using `logs` and `describe` to find out why a pod is failing.

### Real-world Context (Why)
90% of a DevOps Engineer's day is spent investigating why something isn't working. `kubectl describe` is your best friend—it tells you the exact error (e.g., "Out of Memory" or "Image not found").

### Execution (How)
Check the logs of one of your pods.

```bash
POD_NAME=$(kubectl get pods -l app=my-app -o jsonpath="{.items[0].metadata.name}")
kubectl logs $POD_NAME
```

```bash
kubectl describe pod $POD_NAME
```

---

## Challenge
Try to scale your deployment to **0** replicas. What happens when you run `kubectl get pods`? Then scale it back to **3**. This is how we gracefully shut down or restart entire applications!

---

<!-- File: phase-8-terraform/LAB.md -->
# Terraform — Infrastructure as Code (IaC)

In the old days, if you needed a server, you had to click a hundred buttons in the AWS or Azure console. With **Terraform**, you simply write a text file describing the server you want, and Terraform builds it for you. This is "Infrastructure as Code."

---

## Task 1 — The Concept of State

### The Concept (What)
Terraform uses a **State File** to keep track of every resource it has created. When you change your code, Terraform compares it to the state file and only changes what is necessary.

### Real-world Context (Why)
If you have 10,000 servers, you cannot remember which ones you created or what their settings are. Terraform's state file is the "Single Source of Truth" that prevents you from accidentally deleting your company's infrastructure.

### Execution (How)
Check your version and prepare your workspace.

```bash
terraform version
```

```bash
mkdir -p ~/tf-lab && cd ~/tf-lab
```

---

## Task 2 — Your First Configuration (The "Plan")

### The Concept (What)
We use `.tf` files to define our resources. `terraform init` downloads the tools, `terraform plan` shows you what will happen, and `terraform apply` actually does the work.

### Real-world Context (Why)
In DevOps, we **NEVER** run `apply` without looking at the `plan` first. The plan tells you exactly what Terraform is about to do, preventing catastrophic mistakes before they happen.

### Execution (How)
Create a small configuration that manages a local file (this is how we practice without needing an AWS account).

```bash
cat > main.tf << 'TFEOF'
terraform {
  required_version = ">= 1.0"
}

resource "local_file" "app_config" {
  filename = "/tmp/app.conf"
  content  = "PORT=8080\nENV=production\nVERSION=1.0.0"
}
TFEOF
```

```bash
terraform init
```

```bash
terraform plan
```

```bash
terraform apply -auto-approve
```

```bash
cat /tmp/app.conf
```

---

## Task 3 — Variables & Outputs

### The Concept (What)
**Variables** allow you to reuse your code for different environments (Development vs. Production). **Outputs** show you the final results of your work (like a server's IP address).

### Real-world Context (Why)
You don't want to copy-paste the same 1,000 lines of code for your "Testing" and "Production" clusters. You write the code once and use Variables to change the settings for each.

### Execution (How)
Add variables and outputs to your project.

```bash
cat > variables.tf << 'VAREOF'
variable "app_port" {
  type    = number
  default = 8080
}

variable "environment" {
  type    = string
  default = "staging"
}
VAREOF
```

```bash
cat > outputs.tf << 'OUTEOF'
output "config_file_path" {
  value = local_file.app_config.filename
}
OUTEOF
```

**Run it with custom variables:**
```bash
terraform apply -var="environment=production" -var="app_port=9090" -auto-approve
```

---

## Task 4 — Infrastructure Modules

### The Concept (What)
A **Module** is a reusable "package" of Terraform code.

### Real-world Context (Why)
If your company has 50 teams that all need a "Web Server," you write one perfect "Web Server Module" and share it with everyone. This ensures everyone follows the same security standards.

### Execution (How)
Create a reusable module and call it twice.

```bash
mkdir -p modules/config-file
```

```bash
cat > modules/config-file/main.tf << 'MODEOF'
variable "filename" {}
variable "content"  {}
resource "local_file" "this" {
  filename = var.filename
  content  = var.content
}
MODEOF
```

```bash
cat > main.tf << 'ROOTEOF'
module "web_config" {
  source   = "./modules/config-file"
  filename = "/tmp/web.conf"
  content  = "PORT=80\n"
}

module "api_config" {
  source   = "./modules/config-file"
  filename = "/tmp/api.conf"
  content  = "PORT=8080\n"
}
ROOTEOF
```

```bash
terraform init && terraform apply -auto-approve
```

---

## Challenge
Run `terraform destroy` and then check if the files in `/tmp` still exist. This is the most powerful (and dangerous) command in DevOps—it deletes everything your code created in one go!

---

<!-- File: phase-9-monitoring/LAB.md -->
# Monitoring with Prometheus & Grafana

You cannot fix what you cannot see. Monitoring is how you know a service is broken BEFORE your users do. In a Senior DevOps or SRE (Site Reliability Engineer) role, this is your most important daily responsibility.

---

## Task 1 — The Monitoring Stack (The "Ears and Eyes")

### The Concept (What)
- **Prometheus** — The "Database" that stores numbers (metrics) about your servers.
- **Node Exporter** — A small agent that "listens" to the server's CPU and Memory.
- **Grafana** — The "Dashboard" that turns those numbers into beautiful, easy-to-read graphs.

### Real-world Context (Why)
If your website gets slow, a graph in Grafana will instantly show you that the CPU is at 99%. Without this, you would be guessing in the dark while your company loses money.

### Execution (How)
Launch the entire monitoring stack using Docker Compose.

```bash
mkdir -p ~/monitoring-lab && cd ~/monitoring-lab
```

```bash
cat > prometheus.yml << 'PROMEOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
PROMEOF
```

```bash
cat > docker-compose.yml << 'DCEOF'
version: "3.9"
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=devops123
DCEOF
```

```bash
docker compose up -d
```

---

## Task 2 — Querying Data (PromQL)

### The Concept (What)
**PromQL** is the language used to ask Prometheus for data.

### Real-world Context (Why)
You might want to know: "What was the average CPU usage over the last 5 minutes?" PromQL allows you to calculate this instantly so you can identify "spikes" in traffic.

### Execution (How)
Open the Prometheus UI (usually on port 9090) and try these queries:

```promql
up
```

```promql
node_cpu_seconds_total
```

```promql
node_memory_MemAvailable_bytes
```

---

## Task 3 — Alerting Rules (The "Alarm")

### The Concept (What)
An **Alert** is a rule that says: "If CPU is > 80% for more than 2 minutes, send me an email/Slack message."

### Real-world Context (Why)
You don't want to stare at a dashboard all day. You want the system to wake you up ONLY when there is a real problem that needs fixing.

### Execution (How)
An example of how an alert rule is defined in YAML.

```bash
cat > alert-rules.yml << 'ALERTEOF'
groups:
  - name: system-alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
ALERTEOF
```

---

## Challenge
Find out how to view the "Targets" in the Prometheus UI. This screen shows you exactly which servers Prometheus is successfully talking to (and which ones are failing!).

---

<!-- File: phase-10-capstone/LAB.md -->
# Capstone Project — The Production-Grade App

This is what you've been working toward! You are now going to build a complete deployment pipeline for a web application that demonstrates every single skill you've learned. This isn't just a lab—this is your **Portfolio Project**. Show this to every recruiter and hiring manager.

---

## Phase A — Repository Architecture (The "Library")

### The Concept (What)
We create a highly organized directory structure to hold our App, our Ansible playbooks, our Kubernetes manifests, and our Monitoring configs.

### Real-world Context (Why)
A messy repository is a sign of a junior engineer. A clean, modular structure tells an employer that you understand how to manage complex, enterprise-scale projects.

### Execution (How)
Initialize your capstone folder and build the structure.

```bash
mkdir -p ~/capstone-devops && cd ~/capstone-devops
```

```bash
mkdir -p app ansible k8s monitoring .github/workflows
```

---

## Phase B — Building the Application (Docker)

### The Concept (What)
We write a professional Python application that includes "Health Checks" and "Metrics," then package it into a Docker image.

### Real-world Context (Why)
In production, a load balancer needs to know if your app is "healthy" before it sends traffic. By adding a `/health` endpoint, you are making your app "Cloud-Native."

### Execution (How)
Create the app and the Dockerfile.

```bash
cat > app/app.py << 'APPEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, os, datetime

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200); self.end_headers()
            self.wfile.write(b'{"status": "ok"}')
        else:
            self.send_response(200); self.end_headers()
            self.wfile.write(b'{"message": "DevOps Capstone App"}')

HTTPServer(('', 8080), Handler).serve_forever()
APPEOF
```

```bash
cat > app/Dockerfile << 'DFEOF'
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
EXPOSE 8080
CMD ["python3", "app.py"]
DFEOF
```

---

## Phase C — Automation (CI/CD)

### The Concept (What)
We create a GitHub Actions pipeline that builds, tests, and pushes our image automatically.

### Real-world Context (Why)
You want to be the "Engineer of 10x Impact." Automation means you spend your time designing systems, not manually running commands.

### Execution (How)
An example of your final `.github/workflows/pipeline.yml` structure.

```yaml
name: Full CI/CD Pipeline
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and Test
        run: docker build -t capstone-app .
```

---

## Phase D — Infrastructure (Kubernetes)

### The Concept (What)
We write the Kubernetes manifest to deploy our app with **High Availability** (3 replicas).

### Real-world Context (Why)
If you only run 1 copy of your app, and it crashes, the site is down. By running 3 copies, you ensure that your business never goes offline.

### Execution (How)
Create the final Kubernetes Deployment.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: capstone-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: capstone-app
  template:
    metadata:
      labels:
        app: capstone-app
    spec:
      containers:
      - name: capstone-app
        image: yourname/capstone-app:latest
        ports:
        - containerPort: 8080
```

---

## Final Submission Checklist
To call yourself a Graduate of the DevOps Platform, your project must include:
- [ ] GitHub repository with all code.
- [ ] Working CI/CD pipeline (Green checkmark).
- [ ] Optimized Dockerfile.
- [ ] Kubernetes manifests for scaling.
- [ ] `README.md` explaining YOUR architecture.

**This project is your ticket to a high-paying DevOps career. Good luck!**

---

