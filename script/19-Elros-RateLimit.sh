#!/bin/bash


echo ">>> [Elros] Menambahkan Rate Limit 10r/s"


grep -q "limit_req_zone" /etc/nginx/nginx.conf || \
sed -i '/http {/a \    limit_req_zone $binary_remote_addr zone=global_limit:10m rate=10r/s;' /etc/nginx/nginx.conf


grep -q "limit_req zone" /etc/nginx/sites-available/default || \
sed -i '/location \/ {/a \        limit_req zone=global_limit burst=20 nodelay;' /etc/nginx/sites-available/default

echo ">>> [Elros] Restart Nginx"
nginx -t
pkill nginx 2>/dev/null || true; nginx
echo "✅ Elros (Soal 19) Rate Limit Aktif."