#!/usr/bin/env bash
# VPS segment servisine yayınlama: dosyaları atar, servisi yeniden başlatır.
set -e

VPS_HOST="${VPS_HOST:-root@31.97.45.46}"
REMOTE_DIR="/opt/segment-service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "[1/4] main.py ve requirements.txt kopyalanıyor..."
scp "$SCRIPT_DIR/main.py" "$SCRIPT_DIR/requirements.txt" "$VPS_HOST:$REMOTE_DIR/"

echo "[2/4] static/ kopyalanıyor..."
scp -r "$SCRIPT_DIR/static" "$VPS_HOST:$REMOTE_DIR/"

echo "[3/4] VPS'te bağımlılıklar güncelleniyor ve servis yeniden başlatılıyor..."
ssh "$VPS_HOST" "cd $REMOTE_DIR && ./venv/bin/pip install -q -r requirements.txt && systemctl restart segment-service"

echo "[4/4] Sağlık kontrolü..."
sleep 2
ssh "$VPS_HOST" "curl -s http://127.0.0.1:8000/health" || true

echo "Deploy tamamlandı."
