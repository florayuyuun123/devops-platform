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
