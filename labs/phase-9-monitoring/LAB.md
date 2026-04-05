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
