#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load from .env (no export of full file to avoid breaking on special chars)
if [ ! -f .env ]; then
    echo "Error: .env not found. Create .env with VPS_PASSWORD and SEGMENT_SERVICE_URL."
    exit 1
fi
_env_var() { grep -E "^${1}=" .env | cut -d= -f2- | sed -e 's/^["'\'']//' -e 's/["'\'']$//'; }
VPS_PASS="$(_env_var VPS_PASSWORD)"
SEGMENT_URL="$(_env_var SEGMENT_SERVICE_URL)"
VPS_IP="${VPS_IP:-$(echo "$SEGMENT_URL" | sed -n 's|.*://\([^:/]*\).*|\1|p')}"
VPS_USER="${VPS_USER:-root}"
SERVICE_DIR="/opt/segment-service"

if [ -z "$VPS_PASS" ]; then
    echo "Error: VPS_PASSWORD not set in .env"
    exit 1
fi
if [ -z "$VPS_IP" ]; then
    echo "Error: Could not get VPS_IP from SEGMENT_SERVICE_URL in .env"
    exit 1
fi

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo "sshpass could not be found. Please install it with 'brew install sshpass' (MacOS) or 'apt-get install sshpass' (Linux)."
    exit 1
fi

echo "Deploying to $VPS_IP..."

# 1. Upload main.py, requirements.txt, and static folder
echo "Uploading files..."
sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no vps-segment-service/main.py $VPS_USER@$VPS_IP:$SERVICE_DIR/
sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no vps-segment-service/requirements.txt $VPS_USER@$VPS_IP:$SERVICE_DIR/
sshpass -p "$VPS_PASS" scp -r -o StrictHostKeyChecking=no vps-segment-service/static $VPS_USER@$VPS_IP:$SERVICE_DIR/

# 2. Update requirements (aiofiles)
echo "Updating requirements on server..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_IP "cd $SERVICE_DIR && ./venv/bin/pip install -r requirements.txt"

# 3. Restart service
echo "Restarting service..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_IP "systemctl restart segment-service"

echo "Deployment complete!"
