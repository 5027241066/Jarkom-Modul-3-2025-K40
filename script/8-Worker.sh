#!/bin/bash
# 8B) Worker patch – DB .env + domain-only + port unik
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

: "${SERVER:?Set SERVER=elendil.k40.com|isildur.k40.com|anarion.k40.com}"
: "${PORT:?Set PORT=8001|8002|8003}"

APP_DIR="/var/www/laravel"
DB_HOST="palantir.k40.com"
DB_NAME="laravel"
DB_USER="laravel"
DB_PASS="laravel123"

echo ">>> [${SERVER}] Install php-mysql & nginx"
apt-get update -y
apt-get install -y php8.4-mysql mariadb-client nginx

[ -d "$APP_DIR" ] || { echo "⚠️ $APP_DIR tidak ada. Jalankan nomor 7 dulu."; exit 1; }

echo ">>> [${SERVER}] Update .env (DB pakai domain)"
cd "$APP_DIR"
cp .env .env.bak.$(date +%s) 2>/dev/null || true
grep -q '^DB_CONNECTION=' .env && sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env || echo 'DB_CONNECTION=mysql' >> .env
grep -q '^DB_HOST=' .env       && sed -i 's/^DB_HOST=.*/DB_HOST='"$DB_HOST"'/' .env || echo "DB_HOST=$DB_HOST" >> .env
grep -q '^DB_PORT=' .env       && sed -i 's/^DB_PORT=.*/DB_PORT=3306/' .env       || echo "DB_PORT=3306" >> .env
grep -q '^DB_DATABASE=' .env   && sed -i 's/^DB_DATABASE=.*/DB_DATABASE='"$DB_NAME"'/' .env || echo "DB_DATABASE=$DB_NAME" >> .env
grep -q '^DB_USERNAME=' .env   && sed -i 's/^DB_USERNAME=.*/DB_USERNAME='"$DB_USER"'/' .env || echo "DB_USERNAME=$DB_USER" >> .env
grep -q '^DB_PASSWORD=' .env   && sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD='"$DB_PASS"'/' .env || echo "DB_PASSWORD=$DB_PASS" >> .env

echo ">>> [${SERVER}] Nginx vhost (domain-only di port ${PORT})"
cat >/etc/nginx/sites-available/laravel <<EOF
server {
    listen ${PORT} default_server;
    return 444;
}
server {
    listen ${PORT};
    server_name ${SERVER};

    root /var/www/laravel/public;
    index index.php index.html;

    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    location ~ /\.ht { deny all; }
}
EOF

ln -sf /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/laravel
rm -f /etc/nginx/sites-enabled/default
nginx -t

pkill -x php-fpm8.4 2>/dev/null || true
php-fpm8.4 -D
pkill -x nginx 2>/dev/null || true
nginx

echo "✅ [${SERVER}] Worker aktif di http://${SERVER}:${PORT} (IP ditolak 444)"
cd /root; exec bash
