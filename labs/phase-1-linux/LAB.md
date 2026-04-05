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
