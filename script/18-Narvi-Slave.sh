#!/bin/bash


set -e

NODE_IP="192.231.4.4"
GATEWAY_IP="192.231.4.1"

echo ">>> [Narvi] Setup IP Statis ($NODE_IP)"
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

echo ">>> [Narvi] Konfigurasi MariaDB sebagai Slave"
cat > /etc/mysql/mariadb.conf.d/50-server.cnf <<'EOF'
[mysqld]
user = mysql
bind-address = 192.231.4.4
port = 3306
datadir = /var/lib/mysql
socket = /run/mysqld/mysqld.sock
pid-file = /run/mysqld/mysqld.pid
log-error = /var/log/mysql/error.log

# REPLICATION SLAVE
server-id = 2
relay-log = /var/log/mysql/mysql-relay-bin.log
EOF

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql

echo ">>> [Narvi] Restart MariaDB"
pkill mariadbd 2>/dev/null || true
sleep 1
mariadbd --defaults-file=/etc/mysql/mariadb.conf.d/50-server.cnf &
sleep 5

echo "✅ Narvi (SLAVE) siap."
echo "======================== TINDAKAN MANUAL WAJIB ========================="
echo "Gunakan 'File' dan 'Position' dari Palantir."
echo "Jalankan perintah ini di Narvi, GANTI '...' DENGAN NILAI YANG BENAR:"
echo ""
echo "mysql -u root -e \"STOP SLAVE; CHANGE MASTER TO MASTER_HOST='192.231.4.3', MASTER_USER='repl_user', MASTER_PASSWORD='password123', MASTER_LOG_FILE='<FILE_DARI_PALANTIR>', MASTER_LOG_POS=<POSISI_DARI_PALANTIR>; START SLAVE;\""
echo ""
echo "Contoh: MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=1598"
echo "========================================================================"