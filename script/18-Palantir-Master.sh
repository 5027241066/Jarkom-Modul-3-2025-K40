#!/bin/bash


set -e

NODE_IP="192.231.4.3"
GATEWAY_IP="192.231.4.1"

echo ">>> [Palantir] Setup IP Statis ($NODE_IP)"
apt-get update -y
apt-get install -y ifupdown mariadb-server

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

echo ">>> [Palantir] Konfigurasi MariaDB sebagai Master"

cat > /etc/mysql/mariadb.conf.d/50-server.cnf <<'EOF'
[mysqld]
user = mysql
bind-address = 192.231.4.3
port = 3306
datadir = /var/lib/mysql
socket = /run/mysqld/mysqld.sock
pid-file = /run/mysqld/mysqld.pid
log-error = /var/log/mysql/error.log

# REPLICATION MASTER
server-id = 1
log-bin = /var/log/mysql/mysql-bin.log
EOF

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql

echo ">>> [Palantir] Restart MariaDB"
pkill mariadbd 2>/dev/null || true
sleep 1
mariadbd --defaults-file=/etc/mysql/mariadb.conf.d/50-server.cnf &
sleep 5

echo ">>> [Palantir] Membuat user replikasi"
mysql -u root <<'SQL'
CREATE USER IF NOT EXISTS 'repl_user'@'%' IDENTIFIED BY 'password123';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;
SQL

echo "✅ Palantir (MASTER) siap."
echo "================= TINDAKAN MANUAL WAJIB =================="
echo "Jalankan perintah ini di Palantir:"
echo "mysql -u root -e \"SHOW MASTER STATUS;\""
echo "Catat nilai 'File' (cth: mysql-bin.000001) dan 'Position' (cth: 1234)"
echo "Anda akan membutuhkannya di script Narvi."
echo "=========================================================="