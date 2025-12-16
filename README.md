# TTS DIC QA Monitoring - Grafana Dashboards

Git-based Grafana dashboard provisioning for TTS DIC QA environment.

## Quick Start

### 1. Backup Current Setup (IMPORTANT!)

```bash
cd ~/loki-stack
cp docker-compose.yml docker-compose.yml.backup
```

### 2. Clone This Repo to loki-stack

```bash
cd ~/loki-stack
git clone https://github.com/YOUR_USERNAME/tts-grafana-dashboard.git
```

### 3. Update docker-compose.yml

Add these volume mounts to your `grafana` service:

```yaml
grafana:
  volumes:
    - grafana-data:/var/lib/grafana
    # Add these two lines:
    - ./tts-grafana-dashboard/provisioning:/etc/grafana/provisioning
    - ./tts-grafana-dashboard/dashboards:/var/lib/grafana/dashboards
```

Add the `promtail` service (see docker-compose.yml in this repo).

Add `promtail-positions:` to the volumes section.

### 4. Restart Services

```bash
cd ~/loki-stack
docker-compose down
docker-compose up -d
```

### 5. Verify

Open http://192.168.1.133:3000 and check:
- Main Dashboard has 3 cards (UAE, KSA, AI Chatbot)
- AI Chatbot dashboard shows 5 container log panels

## Dashboard Structure

```
Main Dashboard (TTS DIC QA Monitoring)
├── UAE Applications (7 projects, 30 services)
│   ├── ADIB Logs
│   ├── ADXIPO Logs
│   ├── ADXSIP Logs
│   ├── DFM Logs
│   ├── IPO-MIGRATION Logs
│   ├── MBANK Logs
│   └── RUYA-BANK Logs
├── KSA Applications (4 projects, 38 services)
│   ├── ARC Logs
│   ├── BRHUB Logs
│   ├── Investor OnBoarding Logs
│   └── TTSRE Logs
└── AI Chatbot (1 project, 5 services)
    └── Container logs (app, workers, postgres, ui)
```

## Syncing Changes

After pushing changes to GitHub:

```bash
cd ~/loki-stack/tts-grafana-dashboard
./sync.sh
```

Or manually:

```bash
cd ~/loki-stack/tts-grafana-dashboard
git pull origin main
# Grafana auto-reloads within 30 seconds
```

## File Structure

```
tts-grafana-dashboard/
├── provisioning/
│   ├── dashboards/dashboards.yaml    # Dashboard providers
│   └── datasources/datasources.yaml  # Loki datasource
├── dashboards/
│   ├── main/                         # Main dashboard
│   ├── uae/                          # UAE dashboards
│   ├── ksa/                          # KSA dashboards
│   └── ai-chatbot/                   # AI Chatbot dashboard
├── promtail/
│   └── promtail-docker.yaml          # Docker log collection
├── docker-compose.yml                # Reference compose file
├── sync.sh                           # Manual sync script
└── README.md                         # This file
```

## Adding New Dashboards

1. Create JSON file in appropriate folder
2. Commit and push to GitHub
3. Run `./sync.sh` on Harbor server
4. Dashboard appears in Grafana within 30 seconds

## Rollback

If something breaks:

```bash
cd ~/loki-stack
cp docker-compose.yml.backup docker-compose.yml
docker-compose down
docker-compose up -d
```

## Support

TTS Total Technologies and Solutions FZ-LLC
DEVSECOPS Team
