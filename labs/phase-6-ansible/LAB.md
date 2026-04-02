# Ansible configuration management

## Why this matters
Ansible lets you configure 1 or 1000 servers with identical commands.
It is the most in-demand configuration management tool in Africa and globally
for sysadmin-to-DevOps transition roles.

---

## Task 1 — Understand Ansible's core concepts
- **Inventory** — the list of servers you manage
- **Playbook** — a YAML file describing what to do
- **Task** — a single action (install a package, copy a file, restart a service)
- **Role** — a reusable collection of tasks
- **Idempotent** — running it twice gives the same result (safe to re-run)

## Task 2 — Your first inventory
```bash
mkdir ~/ansible-lab && cd ~/ansible-lab

cat > inventory.ini << 'INVEOF'
[webservers]
web1 ansible_host=127.0.0.1 ansible_connection=local

[dbservers]
db1  ansible_host=127.0.0.1 ansible_connection=local

[all:vars]
ansible_user=student
INVEOF

ansible all -i inventory.ini -m ping
```

## Task 3 — Your first playbook
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
        update_cache: yes

    - name: Create app directory
      file:
        path: /opt/myapp
        state: directory
        owner: student
        mode: '0755'

    - name: Write config file
      copy:
        content: |
          PORT=8080
          ENV=production
        dest: /opt/myapp/config.env
        mode: '0600'

    - name: Confirm deployment
      debug:
        msg: "Web server configured successfully on {{ inventory_hostname }}"
PBEOF

ansible-playbook -i inventory.ini site.yml
```

## Task 4 — Variables and templates
```bash
cat > vars.yml << 'VAREOF'
app_port: 8080
app_env: production
app_name: devops-app
VAREOF

cat > deploy.yml << 'DEPEOF'
---
- name: Deploy application
  hosts: all
  vars_files:
    - vars.yml

  tasks:
    - name: Show deployment info
      debug:
        msg: "Deploying {{ app_name }} on port {{ app_port }} in {{ app_env }}"

    - name: Create systemd service
      copy:
        content: |
          [Unit]
          Description={{ app_name }}

          [Service]
          ExecStart=/usr/bin/python3 -m http.server {{ app_port }}
          Restart=always

          [Install]
          WantedBy=multi-user.target
        dest: /tmp/{{ app_name }}.service
DEPEOF

ansible-playbook -i inventory.ini deploy.yml
```

## Task 5 — Roles (reusable structure)
```bash
ansible-galaxy init roles/webserver
ls -la roles/webserver/

cat > roles/webserver/tasks/main.yml << 'ROLEEOF'
---
- name: Install nginx
  apt:
    name: nginx
    state: present
  become: true

- name: Start nginx
  service:
    name: nginx
    state: started
    enabled: true
  become: true
ROLEEOF

cat > use-role.yml << 'UREOF'
---
- name: Setup web server using role
  hosts: webservers
  roles:
    - webserver
UREOF

ansible-playbook -i inventory.ini use-role.yml
```

## Challenge
Write an Ansible playbook that:
1. Creates three users (alice, bob, charlie)
2. Creates a directory `/opt/team` owned by all three
3. Writes a file `/opt/team/README.txt` with today's date
Run it twice — confirm it is idempotent (no errors on second run).
