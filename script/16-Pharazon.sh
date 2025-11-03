#!/bin/bash


set -e

NODE_IP="192.231.1.3"
GATEWAY_IP="192.231.1.1"
SERVER_NAME="pharazon.k40.com"

echo ">>> [Pharazon] Setup IP Statis ($NODE_IP)"
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

echo ">>> [Pharazon] Install Nginx"
apt-get install -y nginx

echo ">>> [Pharazon] (Soal 16) Konfigurasi Reverse Proxy"
cat > /etc/nginx/sites-available/default <<EOF
# (Soal 16) Definisikan upstream worker PHP
upstream Kesatria_Lorien {
    server 192.231.2.3:8004; # Galadriel
    server 192.231.2.5:8005; # Celeborn
    server 192.231.2.6:8006; # Oropher
}

server {
    listen 80;
    server_name $SERVER_NAME;

    location / {
        proxy_pass http://Kesatria_Lorien;

        # (Soal 16) Meneruskan info Basic Auth
        proxy_set_header Authorization \$http_authorization;
        proxy_pass_request_headers on;
        
        # (Soal 15) Meneruskan IP Asli Client
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

echo ">>> [Pharazon] Restart Nginx"
nginx -t
pkill nginx 2>/dev/null || true; nginx

echo "✅ Pharazon (Soal 16) aktif. Siap menerima tes di http://${SERVER_NAME}/"