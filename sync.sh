#!/bin/bash
# TTS Grafana Dashboard Sync Script
# Run this after pushing changes to GitHub

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "TTS Grafana Dashboard Sync"
echo "========================================="

# Check if we're in a git repo
if [ ! -d ".git" ]; then
    echo "ERROR: Not a git repository. Please run 'git init' first."
    exit 1
fi

# Pull latest changes
echo ""
echo "[1/3] Pulling latest changes from GitHub..."
git pull origin main

echo ""
echo "[2/3] Checking file permissions..."
chmod -R 644 dashboards/**/*.json 2>/dev/null || true
chmod -R 644 provisioning/**/*.yaml 2>/dev/null || true
chmod -R 644 promtail/*.yaml 2>/dev/null || true

echo ""
echo "[3/3] Done!"
echo ""
echo "========================================="
echo "Grafana will auto-reload dashboards within 30 seconds."
echo "If you made changes to provisioning configs, restart Grafana:"
echo "  cd ~/loki-stack && docker-compose restart grafana"
echo "========================================="
