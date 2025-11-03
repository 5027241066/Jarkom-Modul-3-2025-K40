#!/bin/bash

set -e

NODE_IP="192.231.2.6"
GATEWAY_IP="192.231.2.1"
LISTEN_PORT=8006
SERVER_NAME="oropher.k40.com"
HOSTNAME="Oropher"

echo ">>> [${HOSTNAME}] Setup IP Statis"
apt-get update -y
apt-get install -y ifupdown

cat > /etc/network/interfaces <<EOF
auto eth0
iface eth0 inet static
    address $NODE_IP
    netmask 255.255.255.0
    gateway $GATEWAY_IP
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF

ip addr flush dev eth0 2>/dev/null || true
ifdown eth0 2>/dev/null || true
ifup eth0

echo ">>> [${HOSTNAME}] (Soal 12) Install Nginx, PHP8.4, Apache Utils"
apt-get install -y nginx curl ca-certificates gnupg lsb-release apt-transport-https apache2-utils


codename=$( . /etc/os-release && echo "$VERSION_CODENAME" )
echo "deb https://packages.sury.org/php/ $codename main" > /etc/apt/sources.list.d/sury-php.list
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/sury.gpg
apt-get update -y
apt-get install -y php8.4-fpm

echo ">>> [${HOSTNAME}] (Soal 12) Buat file index.php"
mkdir -p /var/www/html
echo "<?php echo 'Taman ${HOSTNAME}: ' . gethostname(); ?>" > /var/www/html/index.php

echo ">>> [${HOSTNAME}] (Soal 14) Buat file password Basic Auth"
htpasswd -cb /etc/nginx/.htpasswd noldor silvan

echo ">>> [${HOSTNAME}] (Soal 12, 13, 14) Konfigurasi Nginx"
cat > /etc/nginx/sites-available/default <<EOF
# (Soal 12) Blokir akses IP
server {
    listen $LISTEN_PORT default_server;
    server_name _;
    return 444; 
}


server {
    listen $LISTEN_PORT; # <-- (Soal 13)
    server_name $SERVER_NAME;

    root /var/www/html;
    index index.php;


    auth_basic "Taman Terlarang Peri";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        try_files \$uri \$uri/ =404;
    }


    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
    }
}
EOF

echo ">>> [${HOSTNAME}] Restart services"
nginx -t
pkill php-fpm8.4 2>/dev/null || true
php-fpm8.4 -D
pkill nginx 2>/dev/null || true
nginx

echo "✅ ${HOSTNAME} (Soal 12-14) aktif di http://${SERVER_NAME}:${LISTEN_PORT}/"