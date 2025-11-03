#!/bin/bash


echo ">>> [Pharazon] Menambahkan Nginx Cache"

grep -q "proxy_cache_path" /etc/nginx/nginx.conf || \
sed -i '/http {/a \    proxy_cache_path /var/cache/nginx keys_zone=php_cache:10m inactive=60m max_size=1g;' /etc/nginx/nginx.conf

sed -i '/proxy_pass http:\/\/Kesatria_Lorien;/d' /etc/nginx/sites-available/default


sed -i '/add_header X-Proxy-Cache/d' /etc/nginx/sites-available/default

grep -q "proxy_cache php_cache;" /etc/nginx/sites-available/default || \
sed -i '/location \/ {/a \
        proxy_pass http://Kesatria_Lorien;\
        proxy_cache php_cache;\
        proxy_cache_valid 200 60m;\
        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;\
        add_header X-Proxy-Cache $upstream_cache_status;' /etc/nginx/sites-available/default

echo ">>> [Pharazon] Restart Nginx"
nginx -t
pkill nginx 2>/dev/null || true; nginx
echo "✅ Pharazon (Soal 20) Cache Aktif."