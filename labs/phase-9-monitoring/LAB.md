# Monitoring with Prometheus & Grafana

## Why this matters
You cannot fix what you cannot see. Monitoring is how you know
a service is broken BEFORE your users do. SRE roles make this
their primary responsibility.

---

## Task 1 — Run Prometheus
```bash
mkdir ~/monitoring-lab && cd ~/monitoring-lab

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

cat > docker-compose.yml << 'DCEOF'
version: "3.9"
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'

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
    depends_on:
      - prometheus
DCEOF

docker compose up -d
```

## Task 2 — Explore Prometheus
Open `http://localhost:9090` in your browser.

```promql
up                            # which services are up
node_cpu_seconds_total        # CPU usage data
node_memory_MemAvailable_bytes # available memory
rate(node_cpu_seconds_total{mode="idle"}[5m])  # CPU usage rate
```

## Task 3 — Connect Grafana
1. Open `http://localhost:3001`
2. Login: admin / devops123
3. Add data source → Prometheus → URL: `http://prometheus:9090`
4. Create a dashboard → Add panel → Query: `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
5. Title it "CPU Usage %" and save

## Task 4 — Alerting rules
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
          description: "CPU usage is above 80% for 2 minutes"

      - alert: LowDiskSpace
        expr: node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space"
ALERTEOF
```

## Challenge
Create a Grafana dashboard with 4 panels:
CPU usage, memory usage, disk usage, and network traffic.
Export it as JSON and save it to your Git repository.
This is a portfolio piece that impresses employers.
