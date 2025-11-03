cat > /root/palantir.sh <<'EOF'
#!/bin/bash
# Soal 8 – Palantir = DB server (MariaDB)
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

DB_NAME="laravel"
DB_USER="laravel"
DB_PASS="laravel123"
BIND="0.0.0.0"

echo ">>> [Palantir] Install MariaDB"
apt-get update -y
apt-get install -y mariadb-server mariadb-client

CNF=/etc/mysql/mariadb.conf.d/50-server.cnf
sed -i 's/^\s*bind-address\s*=.*/bind-address = '"$BIND"'/' "$CNF" || \
grep -q '^bind-address' "$CNF" || echo "bind-address = $BIND" >> "$CNF"

echo ">>> [Palantir] Start mysqld (no systemd)"
pkill -x mysqld 2>/dev/null || true
mysqld_safe --datadir=/var/lib/mysql >/var/log/mysqld.safe.log 2>&1 &

for i in {1..30}; do mysqladmin ping >/dev/null 2>&1 && break; sleep 0.5; done

mysql -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'192.231.%' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'192.231.%';
FLUSH PRIVILEGES;
SQL

echo "✅ MariaDB ready on Palantir."
echo "Use in workers' .env:"
echo "DB_HOST=palantir.k40.com"
echo "DB_DATABASE=$DB_NAME"
echo "DB_USERNAME=$DB_USER"
echo "DB_PASSWORD=$DB_PASS"

cd /root
echo ">>> [Palantir] Container active — returning to shell"
exec bash
EOF

chmod +x /root/palantir.sh
bash /root/palantir.sh
