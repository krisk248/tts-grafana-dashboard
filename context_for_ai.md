# TTS Grafana Dashboard - AI Context Documentation

## Project Overview

This project provides **Git-based Grafana dashboard provisioning** for TTS DIC QA environment with support for:
- Traditional Windows/Linux server logs (UAE, KSA regions)
- Docker container logs (AI Chatbot on Harbor server)

**Created**: December 2024
**Company**: TTS Total Technologies and Solutions FZ-LLC
**Team**: DEVSECOPS

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        HARBOR SERVER (192.168.1.133)                    │
│                                                                         │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    │
│   │    GRAFANA      │    │      LOKI       │    │    PROMTAIL     │    │
│   │    :3000        │◄───│     :3100       │◄───│     :9081       │    │
│   │                 │    │                 │    │                 │    │
│   │  Dashboards     │    │  Log Storage    │    │  Log Collector  │    │
│   └─────────────────┘    └─────────────────┘    └────────┬────────┘    │
│                                                          │              │
│                                                          │ Docker Socket│
│                                                          ▼              │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                    DOCKER CONTAINERS                             │  │
│   │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────────┐ │  │
│   │  │   app   │ │postgres │ │worker-  │ │worker-  │ │prompt-faq │ │  │
│   │  │         │ │         │ │approved │ │upload   │ │   -ui     │ │  │
│   │  │         │ │         │ │ -docs   │ │-questions│ │           │ │  │
│   │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └───────────┘ │  │
│   └─────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. Grafana Provisioning
- **Path**: `/etc/grafana/provisioning/`
- **Dashboard Provider**: Watches `/var/lib/grafana/dashboards/` for JSON files
- **Auto-reload**: Every 30 seconds

### 2. Loki
- **Port**: 3100
- **Purpose**: Log aggregation and storage
- **Query Language**: LogQL

### 3. Promtail
- **Port**: 9081 (admin API only, NOT for log transfer)
- **Purpose**: Scrapes Docker container logs via Docker socket
- **Config**: `promtail/promtail-docker.yaml`

---

## How Docker Log Collection Works

### Promtail Configuration Explained

```yaml
scrape_configs:
  - job_name: ai-chatbot-openai
    docker_sd_configs:
      - host: unix:///var/run/docker.sock    # Connect to Docker socket
        refresh_interval: 5s
        filters:
          - name: name
            values: ["open-ai-*"]            # Only discover these containers
    relabel_configs:
      # Use Docker Compose service name as service_type
      - source_labels: ['__meta_docker_container_label_com_docker_compose_service']
        target_label: service_type
```

### Key Labels Applied
| Label | Value | Source |
|-------|-------|--------|
| `project` | `AI-Chatbot` | Static |
| `machine` | `Harbor-Server` | Static |
| `environment` | `Docker` | Static |
| `service_type` | `app`, `postgres`, etc. | From Docker Compose service name |
| `container` | Full container name | From Docker |

### LogQL Query Example
```
{project="AI-Chatbot", service_type="app"} |~ "ERROR"
```

---

## Dashboard Structure

```
Main Dashboard (TTS DIC QA Monitoring)
├── UAE Applications (7 projects, 30 services)
│   └── Regional hub → Project log dashboards
├── KSA Applications (4 projects, 38 services)
│   └── Regional hub → Project log dashboards
└── AI Chatbot (1 project, 5 services)
    └── Direct log dashboard (5 container panels)
```

---

## File Structure

```
tts-grafana-dashboard/
├── provisioning/
│   ├── dashboards/dashboards.yaml     # Dashboard providers
│   └── datasources/datasources.yaml   # Loki datasource
├── dashboards/
│   ├── main/
│   │   └── DIC_QA_Main_Dashboard.json
│   ├── uae/
│   │   └── *.json (UAE dashboards)
│   ├── ksa/
│   │   └── *.json (KSA dashboards)
│   └── ai-chatbot/
│       └── AI_Chatbot_Logs.json
├── promtail/
│   └── promtail-docker.yaml
├── docker-compose.yml
├── sync.sh
├── README.md
└── context_for_ai.md (this file)
```

---

## How to Add New Docker Containers

### Step 1: Update Promtail Config

If adding containers with a new name pattern, edit `promtail/promtail-docker.yaml`:

```yaml
# Add a new job or update existing filter
docker_sd_configs:
  - host: unix:///var/run/docker.sock
    filters:
      - name: name
        values: ["open-ai-*", "new-app-*"]  # Add new pattern
```

### Step 2: Update Dashboard

Edit `dashboards/ai-chatbot/AI_Chatbot_Logs.json` to add new panel:

```json
{
  "title": "AI-CHATBOT - NEW-SERVICE",
  "targets": [{
    "expr": "{project=\"AI-Chatbot\", service_type=\"new-service\"}"
  }]
}
```

### Step 3: Push and Sync

```bash
# On your local machine
git add -A && git commit -m "Add new container" && git push

# On Harbor server
cd ~/loki-stack/tts-grafana-dashboard
git pull origin main
docker-compose restart promtail
```

---

## How to Add New Region/Project (Non-Docker)

### Step 1: Add to CSV
Edit `APPLICATIONS_CONFIG_TEMPLATE.csv`:
```csv
ENV,Place,System,machine,ProjectName,ProcessName,LogPath
QA,NEW-REGION,Windows,Server-Name,Project-Name,tomcat,C:\path\to\logs
```

### Step 2: Run Generator
```bash
python generate_dashboards_v7.py
```

### Step 3: Copy Generated Files
Copy from `v7/` to appropriate `dashboards/` folder.

---

## Troubleshooting

### No Data in Dashboard

1. **Check if container is producing logs**:
   ```bash
   docker logs <container-name> 2>&1 | tail -10
   ```

2. **Check Promtail is discovering container**:
   ```bash
   docker logs promtail 2>&1 | grep "added Docker target"
   ```

3. **Check Loki has the labels**:
   ```bash
   curl -s 'http://localhost:3100/loki/api/v1/series' \
     --data-urlencode 'match[]={project="AI-Chatbot"}' | jq
   ```

### Promtail Errors

**"at least one label pair is required"**
- Cause: Some containers discovered but labels not set
- Fix: Use Docker native filters instead of relabel `action: keep`

**Port conflict (9080)**
- Cause: Another service using port 9080
- Fix: Change Promtail's `http_listen_port` to 9081

### Dashboard Not Updating

```bash
# Force sync
cd ~/loki-stack/tts-grafana-dashboard
git pull origin main

# Grafana auto-reloads within 30 seconds
# Or restart Grafana:
docker-compose restart grafana
```

---

## Important Notes

1. **Promtail only captures NEW logs** - Historical logs from before Promtail started are not captured

2. **Port 9081 is admin only** - Promtail's http_listen_port is for health checks, not log transfer. Logs are pushed to Loki:3100

3. **Docker Compose service label** - Most reliable way to get service names:
   ```yaml
   __meta_docker_container_label_com_docker_compose_service
   ```

4. **Git sync is manual** - Run `git pull` on Harbor server after pushing changes

---

## GitHub Repository

- **URL**: https://github.com/krisk248/tts-grafana-dashboard
- **Branch**: main

---

## Contact

TTS Total Technologies and Solutions FZ-LLC
DEVSECOPS Team
