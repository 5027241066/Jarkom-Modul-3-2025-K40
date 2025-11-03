#!/bin/bash
# ==========================================================
# Soal 7 – Laravel Worker Setup (Tanpa Database)
# Nodes : Elendil (192.231.1.2), Isildur (192.231.1.3), Anarion (192.231.1.4)
# Tujuan: Menampilkan halaman Laravel di Nginx + PHP 8.4
# ==========================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "nameserver 192.231.5.2" > /etc/resolv.conf

echo ">>> [Laravel-Worker] Update & install deps"
apt-get update -y
apt-get install -y curl ca-certificates gnupg lsb-release unzip git apt-transport-https nginx

echo ">>> [Laravel-Worker] Tambah repo PHP 8.4 (Sury)"
codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
echo "deb https://packages.sury.org/php/ $codename main" >/etc/apt/sources.list.d/sury-php.list
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/sury.gpg
apt-get update -y

echo ">>> [Laravel-Worker] Install PHP 8.4 + ekstensi"
apt-get install -y php8.4 php8.4-fpm php8.4-cli php8.4-xml php8.4-mbstring php8.4-curl php8.4-zip php8.4-tokenizer php8.4-fileinfo php8.4-mysql

echo ">>> [Laravel-Worker] Install Composer (jika belum)"
if ! command -v composer >/dev/null 2>&1; then
  curl -sS https://getcomposer.org/installer -o composer-setup.php
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rm composer-setup.php
fi

echo ">>> [Laravel-Worker] Clone & install Laravel"
mkdir -p /var/www
cd /var/www
rm -rf laravel || true
git clone https://github.com/laravel/laravel.git
cd laravel
composer install --no-interaction --prefer-dist --no-progress

echo ">>> [Laravel-Worker] Setup .env & app key"
cp .env.example .env
php artisan key:generate --force

grep -q '^DB_CONNECTION=' .env && sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env || echo 'DB_CONNECTION=mysql' >> .env

# file-based cache/session agar welcome page jalan tanpa DB
grep -q '^CACHE_DRIVER=file' .env || echo 'CACHE_DRIVER=file' >> .env
grep -q '^SESSION_DRIVER=file' .env || echo 'SESSION_DRIVER=file' >> .env
grep -q '^QUEUE_CONNECTION=sync' .env || echo 'QUEUE_CONNECTION=sync' >> .env

echo ">>> [Laravel-Worker] Permission & storage"
mkdir -p storage/logs storage/framework/{cache,sessions,views}
touch storage/logs/laravel.log
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

echo ">>> [Laravel-Worker] Konfigurasi Nginx (port 80)"
cat >/etc/nginx/sites-available/laravel <<'EOF'
server {
    listen 80 default_server;
    root /var/www/laravel/public;
    index index.php index.html;
    server_name _;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/laravel
rm -f /etc/nginx/sites-enabled/default
nginx -t

echo ">>> [Laravel-Worker] Jalankan php-fpm & nginx (daemon)"
pkill -x php-fpm8.4 2>/dev/null || true
php-fpm8.4 -D
pkill -x nginx 2>/dev/null || true
nginx

sleep 2
curl -s http://127.0.0.1/ >/dev/null && echo "✅ Laravel aktif di port 80" || echo "⚠️ Laravel belum merespons"

IP=$(hostname -I | awk '{print $1}')
echo "Buka di:  http://$IP/"

# return to safe shell untuk GNS3
cd /root
echo ">>> [Laravel-Worker] Container aktif — kembali ke shell interaktif"
exec bash
