#!/bin/bash
set -e

DOMAIN="vestiyerapp.com"
EMAIL="destek@vestiyerapp.com"
UPSTREAM="http://127.0.0.1:8000"

echo "[1/4] Installing Nginx and Certbot..."
apt-get update -qq
apt-get install -y nginx certbot python3-certbot-nginx

echo "[2/4] Configuring Nginx for $DOMAIN..."
cat > /etc/nginx/sites-available/$DOMAIN <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_pass $UPSTREAM;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx

echo "[3/4] Obtaining SSL Certificate..."
# Non-interactive certbot
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m $EMAIL --redirect

echo "[4/4] Verifying Nginx status..."
systemctl status nginx --no-pager

echo "Nginx setup complete! https://$DOMAIN should be accessible."
