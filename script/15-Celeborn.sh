#!/bin/bash


set -e

LISTEN_PORT=8005
SERVER_NAME="celeborn.k40.com"
HOSTNAME="Celeborn"

echo ">>> [${HOSTNAME}] (Soal 15) Install Apache Utils (untuk htpasswd)"
apt-get update -y
apt-get install -y apache2-utils

echo ">>> [${HOSTNAME}] (Soal 14) Buat file password Basic Auth"
htpasswd -cb /etc/nginx/.htpasswd noldor silvan

echo ">>> [${HOSTNAME}] (Soal 15) Update index.php untuk tampilkan IP"
echo "<?php \$hostname = gethostname(); \$ip = \$_SERVER['HTTP_X_REAL_IP'] ?? \$_SERVER['REMOTE_ADDR']; echo \"Taman \$hostname (Visitor IP: \$ip)\"; ?>" > /var/www/html/index.php

echo ">>> [${HOSTNAME}] (Soal 13, 14, 15) Konfigurasi ulang Nginx"
cat > /etc/nginx/sites-available/default <<EOF

server {
    listen $LISTEN_PORT default_server;
    server_name _;
    return 444; 
}


server {
    listen $LISTEN_PORT;
    server_name $SERVER_NAME;

    root /var/www/html;
    index index.php;

    # (Soal 14) Basic Auth
    auth_basic "Taman Terlarang Peri";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        
        # (Soal 15) Tambah header X-Real-IP ke PHP
        fastcgi_param X-Real-IP \$remote_addr;
    }
}
EOF

echo ">>> [${HOSTNAME}] Restart services"
nginx -t
pkill php-fpm8.4 2>/dev/null || true; php-fpm8.4 -D
pkill nginx 2>/dev/null || true; nginx

echo "✅ ${HOSTNAME} (Soal 12-15) aktif di http://${SERVER_NAME}:${LISTEN_PORT}/"