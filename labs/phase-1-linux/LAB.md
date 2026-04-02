# Linux file system & permissions

## Why this matters
Every server you manage runs Linux. This is tested in every DevOps interview.

---

## Task 1 — Where are you?
```bash
pwd          # print working directory
ls -la       # long list including hidden files
```
The first character of each line: `d` = directory, `-` = file, `l` = symlink.

## Task 2 — Explore the system
```bash
cd /etc && ls        # system config
cd /var/log && ls    # log files
cd /usr/bin && ls    # installed binaries
cd ~                 # back home
```

## Task 3 — Create and manage files
```bash
mkdir ~/workspace && cd ~/workspace
touch server.conf app.py deploy.sh
echo "PORT=8080" > server.conf
echo "HOST=0.0.0.0" >> server.conf
cat server.conf
cp server.conf server.conf.bak
mv deploy.sh release.sh
rm server.conf.bak
ls -la
```

## Task 4 — Permissions
```bash
chmod 600 server.conf   # secrets  — owner read/write only
chmod 755 release.sh    # scripts  — owner rwx, others r-x
chmod 644 app.py        # code     — owner rw,  others r
ls -la
```
**Numbers:** 4=read 2=write 1=execute. 755 = rwxr-xr-x. 600 = rw-------.

## Task 5 — Search
```bash
grep "PORT" server.conf
find /etc -name "*.conf" 2>/dev/null | head -10
```

## Challenge
Set `server.conf` to `400` (read-only, even for owner). Then try to edit it. What happens?
