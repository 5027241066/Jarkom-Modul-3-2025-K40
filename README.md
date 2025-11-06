# Jarkom-Modul-3-2025-K40
## Anggota Kelompok

| No | Nama                   | NRP         |
|----|------------------------|-------------|
| 1  | Ahmad Yafi Ar Rizq | 5027241066  |
| 2  | Mohammad Abyan Ranuaji     | 5027241106  |

## Soal 1
Topology sebagai berikut:

<img width="939" height="803" alt="Screenshot 2025-10-30 095000" src="https://github.com/user-attachments/assets/1f9ea0c8-85d7-4bb9-a0af-7d934ec1859f" />

Kemudian set `nameserver 192.168.122.1` pada network config seperti berikut

<img width="633" height="227" alt="image" src="https://github.com/user-attachments/assets/0e28931b-1369-44ee-ba83-3047ce8eb740" />

## Soal 2
Sesuai Soal 2, Aldarion dikonfigurasi sebagai DHCP Server (isc-dhcp-server) untuk membagikan alamat IP secara dinamis. Konfigurasi di /etc/dhcp/dhcpd.conf diatur untuk melayani beberapa subnet yang di-relay oleh Durin:

Jaringan Manusia (192.231.1.0/24): Diberikan range IP 192.231.1.6 - 192.231.1.34 dan 192.231.1.68 - 192.231.1.94 .
Jaringan Peri (192.231.2.0/24): Diberikan range IP 192.231.2.35 - 192.231.2.67 dan 192.231.2.96 - 192.231.2.121.
Khamul (192.231.3.0/24): Diberikan alamat IP tetap 192.231.3.95.

Script 2-Aldarion.sh digunakan untuk konfigurasi ini:
```
#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> [Aldarion] Install DHCP server"
apt-get update -y
apt-get install -y --no-install-recommends isc-dhcp-server

echo ">>> [Aldarion] Bind DHCP to eth0 (server di 192.231.4.2/24)"
mkdir -p /etc/dhcp
cat > /etc/default/isc-dhcp-server <<'EOF'
INTERFACESv4="eth0"
EOF

echo ">>> [Aldarion] Ensure leases file exists"
mkdir -p /var/lib/dhcp
touch /var/lib/dhcp/dhcpd.leases

echo ">>> [Aldarion] Decree (dhcpd.conf)"
cat > /etc/dhcp/dhcpd.conf <<'EOF'
authoritative;

option domain-name-servers 192.231.5.2, 192.231.3.3, 192.231.3.4;

default-lease-time 600;
max-lease-time 7200;

subnet 192.231.1.0 netmask 255.255.255.0 {
    option routers 192.231.1.1;
    range 192.231.1.6 192.231.1.34;
    range 192.231.1.68 192.231.1.94;
}

subnet 192.231.2.0 netmask 255.255.255.0 {
    option routers 192.231.2.1;
    range 192.231.2.35 192.231.2.67;
    range 192.231.2.96 192.231.2.121;
}

subnet 192.231.3.0 netmask 255.255.255.0 {
    option routers 192.231.3.1;

    host khamul {
        hardware ethernet 02:42:ee:78:cc:00;   # MAC tetap (update jika berubah)
        fixed-address 192.231.3.95;
    }
}

subnet 192.231.4.0 netmask 255.255.255.0 {
    option routers 192.231.4.1;
}

subnet 192.231.5.0 netmask 255.255.255.0 {
    option routers 192.231.5.1;
}
EOF

echo ">>> [Aldarion] Validate config"
dhcpd -t -cf /etc/dhcp/dhcpd.conf

# ... (sisanya menjalankan service) ...
```

## Soal 3
Sesuai Soal 3 , Minastir dikonfigurasi sebagai DNS Forwarder. Tujuannya adalah agar semua client di jaringan internal hanya perlu bertanya ke Minastir. Minastir kemudian akan:

Meneruskan query eksternal (seperti google.com) ke DNS internet (192.168.122.1, 8.8.8.8).
Meneruskan query internal (untuk k40.com dan reverse zone 3.231.192.in-addr.arpa) ke server DNS Master/Slave (Erendis & Amdir).

Script 3-Minastir.sh digunakan untuk menginstal bind9 dan mengatur named.conf.options serta named.conf.local:
```
#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> [Minastir] Install BIND9"
apt-get update -y
apt-get install -y --no-install-recommends bind9 bind9utils dnsutils || apt-get install -y bind9 bind9utils dnsutils

echo ">>> [Minastir] Konfigurasi global forwarder"
cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    allow-query     { any; };
    allow-recursion { any; };
    forwarders {
        192.168.122.1;   // NAT GNS3
        8.8.8.8;         // Google DNS fallback
    };
    forward only;
    dnssec-validation no;
    auth-nxdomain no;
    listen-on    { any; };
    listen-on-v6 { any; };
};
EOF

echo ">>> [Minastir] Konfigurasi conditional forwarders (k40.com + reverse)"
cat > /etc/bind/named.conf.local <<'EOF'
zone "k40.com" {
    type forward;
    forward only;
    forwarders { 192.231.3.3; 192.231.3.4; };
};

zone "3.231.192.in-addr.arpa" {
    type forward;
    forward only;
    forwarders { 192.231.3.3; 192.231.3.4; };
};
EOF

# ... (sisanya menjalankan service) ...
```

## Soal 4
Sesuai Soal 4 , Erendis diatur sebagai DNS Master dan Amdir sebagai DNS Slave.

Di Erendis (Master): Script 4-Erendis.sh menginstal bind9 dan mengkonfigurasinya sebagai server authoritative (recursion no). File zona db.k40.com dibuat dengan record SOA, NS, dan A records untuk semua host yang diminta  (Palantir, Elros, Pharazon, Elendil, Isildur, Anarion, Galadriel, Celeborn, Oropher). named.conf.local juga diatur untuk mengizinkan transfer (allow-transfer) ke Amdir.
```
#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> [Erendis] Install bind9"
apt-get update -y
apt-get install -y --no-install-recommends bind9 bind9-utils dnsutils

cat >/etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    allow-query { any; };
    recursion no;
    dnssec-validation no;
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

cat > /etc/bind/zones/db.k40.com <<'EOF'
$TTL 604800
@   IN  SOA ns1.k40.com. root.k40.com. (
        2025110101 ; serial (YYYYMMDDnn)
        3600       ; refresh
        900        ; retry
        1209600    ; expire
        300 )      ; minimum

    IN  NS  ns1.k40.com.
    IN  NS  ns2.k40.com.

ns1 IN  A   192.231.3.3
ns2 IN  A   192.231.3.4

palantir   IN A 192.231.4.3
elros      IN A 192.231.1.7
pharazon   IN A 192.231.2.7
elendil    IN A 192.231.1.2
isildur    IN A 192.231.1.3
anarion    IN A 192.231.1.4
galadriel  IN A 192.231.2.2
celeborn   IN A 192.231.2.3
oropher    IN A 192.231.2.4
EOF

cat > /etc/bind/named.conf.local <<'EOF'
zone "k40.com" {
    type master;
    file "/etc/bind/zones/db.k40.com";
    allow-transfer { 192.231.3.4; };
    also-notify    { 192.231.3.4; };
    notify yes;
};
EOF
# ... (sisanya menjalankan service) ...
```
Di Amdir (Slave): Script 4-Amdir.sh menginstal bind9 dan mengkonfigurasinya sebagai type slave, menunjuk ke masters { 192.231.3.3; }.
```
#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> [Amdir] Install bind9"
# ... (sisanya) ...

cat >/etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    allow-query { any; };
    recursion no;
    dnssec-validation no;
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

cat > /etc/bind/named.conf.local <<'EOF'
zone "k40.com" {
    type slave;
    masters { 192.231.3.3; };
    file "/var/lib/bind/db.k40.com";
    notify no;
};
EOF
# ... (sisanya menjalankan service) ...
```
Hasil verifikasi (menggunakan 4-Verify_Minastir.sh) menunjukkan bahwa Erendis dan Amdir memiliki SOA serial yang sama, membuktikan transfer berhasil. <img width="960" alt="image" src="[placeholder_hasil_dig_SOA_master_slave]">

## Soal 5

Melanjutkan konfigurasi DNS dari Soal 4, Soal 5 menambahkan beberapa record baru di Erendis (Master). Ini termasuk:
Alias www.k40.com sebagai CNAME ke apex domain.
Dua TXT record rahasia: "Cincin Sauron" di elros.k40.com dan "Aliansi Terakhir" di pharazon.k40.com.
Membuat reverse zone baru (3.231.192.in-addr.arpa) untuk menambahkan PTR record agar IP 192.231.3.3 (ns1) dan 192.231.3.4 (ns2) dapat di-resolve kembali ke hostname mereka.
Amdir (Slave) juga diperbarui untuk menyalin reverse zone baru ini dari Erendis.

Konfigurasi Erendis (Master)
Script 5-Erendis.sh digunakan untuk memperbarui konfigurasi Master:
```
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

MASTER_IP=192.231.3.3
SLAVE_IP=192.231.3.4
ZDIR=/etc/bind/zones
FWD_ZONE=k40.com
REV_ZONE=3.231.192.in-addr.arpa

echo ">>> [Erendis] Install bind9 (if needed)"
apt-get update -y
apt-get install -y --no-install-recommends bind9 bind9-utils dnsutils || \
apt-get install -y --no-install-recommends bind9 bind9utils dnsutils

mkdir -p "$ZDIR"
chown -R bind:bind /etc/bind /var/cache/bind

echo ">>> [Erendis] named.conf.options (authoritative only)"
cat > /etc/bind/named.conf.options <<'EOF'
options {
  directory "/var/cache/bind";
  allow-query { any; };
  recursion no;
  dnssec-validation no;
  listen-on { any; };
  listen-on-v6 { any; };
};
EOF

echo ">>> [Erendis] Forward zone file ($FWD_ZONE)"
cat > "$ZDIR/db.$FWD_ZONE" <<'EOF'
$TTL 604800
@   IN  SOA ns1.k40.com. root.k40.com. (
        2025110102 ; serial
        3600       ; refresh
        900        ; retry
        1209600    ; expire
        300 )      ; minimum

    IN  NS  ns1.k40.com.
    IN  NS  ns2.k40.com.

ns1 IN  A   192.231.3.3
ns2 IN  A   192.231.3.4

palantir   IN A 192.231.4.3
elros      IN A 192.231.1.7
pharazon   IN A 192.231.2.7
elendil    IN A 192.231.1.2
isildur    IN A 192.231.1.3
anarion    IN A 192.231.1.4
galadriel  IN A 192.231.2.2
celeborn   IN A 192.231.2.3
oropher    IN A 192.231.2.4

www        IN CNAME k40.com.
elros      IN TXT   "Cincin Sauron"
pharazon   IN TXT   "Aliansi Terakhir"
EOF

echo ">>> [Erendis] Reverse zone file ($REV_ZONE)"
cat > "$ZDIR/db.$REV_ZONE" <<'EOF'
$TTL 604800
@   IN  SOA ns1.k40.com. root.k40.com. (
        2025110101 ; serial
        3600       ; refresh
        900        ; retry
        1209600    ; expire
        300 )      ; minimum

    IN  NS  ns1.k40.com.
    IN  NS  ns2.k40.com.

3   IN  PTR ns1.k40.com.
4   IN  PTR ns2.k40.com.
EOF

echo ">>> [Erendis] named.conf.local (2 zones: forward + reverse)"
cat > /etc/bind/named.conf.local <<EOF
zone "$FWD_ZONE" {
  type master;
  file "$ZDIR/db.$FWD_ZONE";
  allow-transfer { $SLAVE_IP; };
  also-notify    { $SLAVE_IP; };
  notify yes;
};

zone "$REV_ZONE" {
  type master;
  file "$ZDIR/db.$REV_ZONE";
  allow-transfer { $SLAVE_IP; };
  also-notify    { $SLAVE_IP; };
  notify yes;
};
EOF

echo ">>> [Erendis] Validate"
named-checkconf
named-checkzone "$FWD_ZONE" "$ZDIR/db.$FWD_ZONE"
named-checkzone "$REV_ZONE" "$ZDIR/db.$REV_ZONE"

echo ">>> [Erendis] Start named (no systemd)"
pkill -x named 2>/dev/null || true
mkdir -p /run/named && chown bind:bind /run/named
named -4 -u bind -c /etc/bind/named.conf -g &

sleep 1
(ss -lun 2>/dev/null || netstat -lun 2>/dev/null) | grep -w ':53' || echo "WARN: UDP 53 belum terlihat"

echo "✅ Erendis MASTER ready (Soal 5)."
echo "Cek:"
echo "  dig @192.231.3.3 k40.com SOA +short"
echo "  dig @192.231.3.3 www.k40.com CNAME +short"
echo "  dig @192.231.3.3 elros.k40.com TXT +short"
echo "  dig @192.231.3.3 -x 192.231.3.3 +short"
echo "  dig @192.231.3.3 -x 192.231.3.4 +short"
```
Konfigurasi Amdir (Slave)
Script 5-Amdir.sh digunakan untuk memperbarui konfigurasi Slave:
```
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

MASTER_IP=192.231.3.3
ZDIR=/var/lib/bind
FWD_ZONE=k40.com
REV_ZONE=3.231.192.in-addr.arpa

echo ">>> [Amdir] Install bind9 (if needed)"
apt-get update -y
apt-get install -y --no-install-recommends bind9 bind9-utils dnsutils || \
apt-get install -y --no-install-recommends bind9 bind9utils dnsutils

mkdir -p "$ZDIR"
chown -R bind:bind /etc/bind "$ZDIR" /var/cache/bind

echo ">>> [Amdir] named.conf.options (authoritative only)"
cat > /etc/bind/named.conf.options <<'EOF'
options {
  directory "/var/cache/bind";
  allow-query { any; };
  recursion no;
  dnssec-validation no;
  listen-on { any; };
  listen-on-v6 { any; };
};
EOF

echo ">>> [Amdir] named.conf.local (slave untuk 2 zones)"
cat > /etc/bind/named.conf.local <<EOF
zone "$FWD_ZONE" {
  type slave;
  masters { $MASTER_IP; };
  file "$ZDIR/db.$FWD_ZONE";
  notify no;
};

zone "$REV_ZONE" {
  type slave;
  masters { $MASTER_IP; };
  file "$ZDIR/db.$REV_ZONE";
  notify no;
};
EOF

echo ">>> [Amdir] Validate"
named-checkconf

echo ">>> [Amdir] Start named (no systemd)"
pkill -x named 2>/dev/null || true
mkdir -p /run/named && chown bind:bind /run/named
named -4 -u bind -c /etc/bind/named.conf -g &

sleep 1
(ss -lun 2>/dev/null || netstat -lun 2>/dev/null) | grep -w ':53' || echo "WARN: UDP 53 belum terlihat"

echo "✅ Amdir SLAVE ready (Soal 5)."
echo "Cek:"
echo "  dig @192.231.3.4 k40.com SOA +short"
echo "  dig @192.231.3.4 www.k40.com CNAME +short"
echo "  dig @192.231.3.4 elros.k40.com TXT +short"
echo "  dig @192.231.3.4 -x 192.231.3.3 +short"
echo "  dig @192.231.3.4 -x 192.231.3.4 +short"
```
Verifikasi dari client (via Minastir) atau langsung ke Erendis/Amdir menunjukkan record baru telah berhasil ditransfer.

## Soal 6
Konfigurasi DHCP Server di Aldarion diperbarui untuk menetapkan waktu peminjaman (lease time) yang spesifik untuk setiap keluarga (subnet) :
- Keluarga Manusia (Subnet 192.231.1.0/24): 30 menit (default-lease-time 1800).
- Keluarga Peri (Subnet 192.231.2.0/24): 10 menit (default-lease-time 600).
- Batas Maksimal (Global): 1 jam (max-lease-time 3600).
Script 6-Aldairon.sh digunakan untuk menimpa konfigurasi DHCP sebelumnya:
```
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> Install DHCP server"
apt-get update -y
apt-get install -y isc-dhcp-server

echo ">>> Ikat DHCP ke interface eth0"
cat >/etc/default/isc-dhcp-server <<'EOF'
INTERFACESv4="eth0"
EOF

echo ">>> Tulis konfigurasi dhcpd.conf"
mkdir -p /etc/dhcp
cat >/etc/dhcp/dhcpd.conf <<'EOF'
authoritative;

option domain-name-servers 192.231.5.2, 192.231.3.3, 192.231.3.4;
max-lease-time 3600;

subnet 192.231.1.0 netmask 255.255.255.0 {
  option routers 192.231.1.1;
  default-lease-time 1800;
  range 192.231.1.6 192.231.1.34;
  range 192.231.1.68 192.231.1.94;
}

subnet 192.231.2.0 netmask 255.255.255.0 {
  option routers 192.231.2.1;
  default-lease-time 600;
  range 192.231.2.35 192.231.2.67;
  range 192.231.2.96 192.231.2.121;
}

subnet 192.231.3.0 netmask 255.255.255.0 {
  option routers 192.231.3.1;
  host khamul {
    hardware ethernet 02:42:13:30:01:00;
    fixed-address 192.231.3.95;
  }
}

subnet 192.231.4.0 netmask 255.255.255.0 { option routers 192.231.4.1; }
subnet 192.231.5.0 netmask 255.255.255.0 { option routers 192.231.5.1; }
EOF

echo ">>> Validasi konfigurasi"
/usr/sbin/dhcpd -t -cf /etc/dhcp/dhcpd.conf

echo ">>> Jalankan DHCP server (manual)"
pkill dhcpd 2>/dev/null || true
mkdir -p /var/lib/dhcp
touch /var/lib/dhcp/dhcpd.leases
dhcpd -4 -q --no-pid -cf /etc/dhcp/dhcpd.conf -lf /var/lib/dhcp/dhcpd.leases eth0 &

sleep 1
pgrep -af dhcpd || echo "⚠️ DHCPD not running?"
echo "✅ Soal 6 selesai: Manusia=1800 s, Peri=600 s, Max=3600 s."
```
Verifikasi pada client Amandil (Manusia) menunjukkan valid_lft 1800sec, sesuai dengan konfigurasi.

## Soal 7
Sesuai Soal 7 , ketiga worker Numenor (Elendil, Isildur, Anarion) disiapkan dengan stack Laravel. Ini melibatkan instalasi Nginx, PHP 8.4 (via repositori Sury), dan Composer.
Script 7-SetupElendil-Isildur-Anarion.sh berikut dijalankan di ketiga node:
```
#!/bin/bash
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
# Repositori yang benar sesuai Soal 20
git clone https://github.com/elshiraphine/laravel-simple-rest-api.git laravel
cd laravel
# 'composer update' diperlukan karena repo menggunakan PHP 8.4
composer update --no-interaction --prefer-dist --no-progress

echo ">>> [Laravel-Worker] Setup .env & app key"
cp .env.example .env
php artisan key:generate --force

grep -q '^DB_CONNECTION=' .env && sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env || echo 'DB_CONNECTION=mysql' >> .env
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
```
## Soal 8
Sesuai Soal 8 , worker dikonfigurasi untuk terhubung ke database Palantir.
1. Konfigurasi Palantir (Master Database)
Di node Palantir, MariaDB diinstal dan dikonfigurasi untuk menerima koneksi dari worker. Database laravel dan user laravel dibuat.
```
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
```
2. Konfigurasi Worker (Elendil, Isildur, Anarion)
Di ketiga worker, script 8-Worker.sh dijalankan. Script ini:

Mengisi file .env dengan kredensial database Palantir.
Mengkonfigurasi Nginx untuk listening di port unik (8001, 8002, 8003).
Memblokir akses via IP (return 444) dan hanya mengizinkan akses via domain.
```
#!/bin/bash

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
```
Script ini dijalankan sebagai berikut:
```
# Di Elendil
export SERVER=elendil.k40.com PORT=8001 && bash 8-Worker.sh

# Di Isildur
export SERVER=isildur.k40.com PORT=8002 && bash 8-Worker.sh

# Di Anarion
export SERVER=anarion.k40.com PORT=8003 && bash 8-Worker.sh
```
Sesuai soal, migrasi dijalankan dari Elendil. File DatabaseSeeder.php di Elendil perlu di-patch untuk memanggil seeder yang benar (AiringTableSeeder):
```
# (Dijalankan di Elendil)
nano /var/www/laravel/database/seeders/DatabaseSeeder.php
Isi file DatabaseSeeder.php diubah menjadi:

PHP

<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run()
    {
        $this->call(AiringsTableSeeder::class);
    }
}
```
Setelah disimpan, migrasi dan seeding dijalankan:
```
# (Dijalankan di Elendil)
cd /var/www/laravel
php artisan migrate --seed
```

## Soal 9
Melakukan verifikasi fungsionalitas setiap worker (Elendil, Isildur, Anarion) dari node client (Amandil). lynx digunakan untuk mengecek halaman utama, dan curl digunakan untuk mengetes endpoint /api/airing guna memastikan koneksi ke database Palantir berjalan.

Pertama, pastikan lynx dan curl terinstal di Amandil:
```
apt-get update
apt-get install -y lynx curl
```
Tes halaman utama dengan lynx (seharusnya menampilkan halaman default Laravel):
```
lynx http://elendil.k40.com:8001
lynx http://isildur.k40.com:8002
lynx http://anarion.k40.com:8003
```
Tes koneksi database dengan curl (seharusnya mengembalikan data JSON):
```
curl http://elendil.k40.com:8001/api/airing
curl http://isildur.k40.com:8002/api/airing
curl http://anarion.k40.com:8003/api/airing
```

<img width="1109" height="188" alt="image" src="https://github.com/user-attachments/assets/21f94e16-9a80-486b-8983-f57891c6e1ab" />

<img width="1027" height="501" alt="image" src="https://github.com/user-attachments/assets/693b3fed-9b09-4d61-8d96-c6c59113d32b" />

## Soal 10
Mengkonfigurasi Elros sebagai reverse proxy (Load Balancer). Dibuat sebuah upstream bernama kesatria_numenor yang berisi ketiga worker Laravel (Elendil, Isildur, Anarion). Nginx diatur agar semua permintaan ke elros.k40.com diteruskan ke upstream tersebut menggunakan Round Robin.

Script berikut (10-Elros.sh) dijalankan di node Elros:

```
#!/bin/bash

set -eo pipefail
export DEBIAN_FRONTEND=noninteractive


echo ">>> [Elros] Setting up static IP (192.231.1.7) and gateway"
ip addr add 192.231.1.7/24 dev eth0 2>/dev/null || true
ip route add default via 192.231.1.1 2>/dev/null || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf
echo "nameserver 192.231.5.2" >> /etc/resolv.conf


echo ">>> [Elros] Install Nginx"
apt-get update -y
apt-get install -y --no-install-recommends nginx

echo ">>> [Elros] Configure Nginx Upstream (kesatria_numenor)"
cat >/etc/nginx/conf.d/upstream_numenor.conf <<'EOF'
upstream kesatria_numenor {

    server 192.231.1.2:8001;
    server 192.231.1.3:8002;
    server 192.231.1.4:8003;
}
EOF

echo ">>> [Elros] Configure Nginx Server Block (elros.k40.com)"
cat >/etc/nginx/sites-available/elros_proxy <<'EOF'
server {
    listen 80;
    server_name elros.k40.com;

    location / {
        proxy_pass http://kesatria_numenor;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo ">>> [Elros] Enable site and restart Nginx"
ln -sf /etc/nginx/sites-available/elros_proxy /etc/nginx/sites-enabled/elros_proxy
rm -f /etc/nginx/sites-enabled/default

nginx -t
pkill -x nginx 2>/dev/null || true
nginx

echo "✅ Elros (Load Balancer) ready."
```
Untuk mengatasi error 502 Bad Gateway (akibat return 444 di worker), server_name di setiap worker (Elendil, Isildur, Anarion) diupdate agar menerima elros.k40.com:

```
# Dijalankan di Elendil, Isildur, dan Anarion
sed -i "s/server_name \(.*\);/server_name \1 elros.k40.com;/" /etc/nginx/sites-available/laravel
nginx -t && nginx -s reload
```
Verifikasi dilakukan dari Amandil dan menunjukkan output JSON yang sukses:

```
# (Dijalankan di Amandil)
curl http://elros.k40.com/api/airing
```

<img width="1114" height="191" alt="image" src="https://github.com/user-attachments/assets/c7926eb7-5f19-44dd-aae9-03db71ea0b35" />

## Soal 12
Para Penguasa Peri (Galadriel, Celeborn, Oropher) dikonfigurasi sebagai worker PHP. Langkah ini mencakup instalasi Nginx dan PHP-FPM di setiap node. File index.php sederhana dibuat di /var/www/html untuk menampilkan hostname unik setiap node. Konfigurasi Nginx juga diatur untuk memblokir akses langsung via IP (return 444) dan hanya mengizinkan akses via hostname (domain) yang sesuai .

Script generik berikut (12-PHP-Worker.sh) disiapkan. Perhatikan bahwa script ini belum mengkonfigurasi FPM (itu di Soal 13) atau port unik.
```
#!/bin/bash
# (Dijalankan di setiap worker PHP, cth. Galadriel)


ip addr add [IP_WORKER]/24 dev eth0 2>/dev/null || true
ip route add default via 192.231.2.1 2>/dev/null || true
echo "nameserver 192.231.5.2" > /etc/resolv.conf

apt-get update
apt-get install -y nginx php8.4-fpm

mkdir -p /var/www/html
echo "<h1>Hello from <?php echo gethostname(); ?></h1>" > /var/www/html/index.php
chown -R www-data:www-data /var/www/html


cat > /etc/nginx/sites-available/php-worker <<EOF

server {
    listen 80 default_server;
    return 444;
}

server {
    listen 80;
    server_name $SERVER_DOMAIN; # Cth: galadriel.k40.com
    root /var/www/html;
    index index.php;
}
EOF

ln -sf /etc/nginx/sites-available/php-worker /etc/nginx/sites-enabled/php-worker
rm -f /etc/nginx/sites-enabled/default

pkill -x php-fpm8.4 2>/dev/null || true; php-fpm8.4 -D
pkill -x nginx 2>/dev/null || true; nginx
```

Tes di amandil:
```
lynx http://galadriel.k40.com
lynx http://192.231.2.2
```

<img width="770" height="304" alt="image" src="https://github.com/user-attachments/assets/cfeac882-dd60-4b75-bc42-a4fa6968e665" />

## Soal 13
Konfigurasi Nginx dari Soal 12 diperbarui agar setiap worker PHP mendengarkan di port unik: Galadriel (8004), Celeborn (8005), dan Oropher (8006). Selain itu, blok location ~ \.php$ ditambahkan untuk memastikan permintaan file .php diteruskan dengan benar ke socket PHP-FPM .

File /etc/nginx/sites-available/php-worker di setiap worker diperbarui:
```
Nginx

server {
    listen [PORT] default_server;
    return 444;
}

server {
    listen [PORT];
    server_name [SERVER_DOMAIN]; # Cth: galadriel.k40.com

    root /var/www/html;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```
Script gabungan dijalankan di setiap worker untuk menerapkan perubahan:
```
# Di Galadriel
export SERVER_DOMAIN=galadriel.k40.com PORT=8004 && bash /root/13-PHP-Worker.sh

# Di Celeborn
export SERVER_DOMAIN=celeborn.k40.com PORT=8005 && bash /root/13-PHP-Worker.sh

# Di Oropher
export SERVER_DOMAIN=oropher.k40.com PORT=8006 && bash /root/13-PHP-Worker.sh
```
Verifikasi dari Amandil menggunakan lynx ke port baru:
```
lynx http://galadriel.k40.com:8004
lynx http://celeborn.k40.com:8005
lynx http://oropher.k40.com:8006

lynx http://192.231.2.2:8004

```
<img width="1076" height="389" alt="image" src="https://github.com/user-attachments/assets/38b1d21b-719d-4578-b9d7-515f362b0514" />

## Soal 14
Untuk meningkatkan keamanan, Basic HTTP Authentication diterapkan di setiap worker PHP. Ini mengharuskan pengguna memasukkan username (noldor) dan password (silvan) sebelum mengakses taman digital Peri.

Pertama, apache2-utils diinstal untuk membuat file .htpasswd. File ini harus dibuat di setiap worker (Galadriel, Celeborn, dan Oropher):
```
# (Dijalankan di ketiga worker PHP)
apt-get install -y apache2-utils

mkdir -p /etc/nginx/secrets
htpasswd -cb /etc/nginx/secrets/.htpasswd noldor silvan

chown www-data /etc/nginx/secrets/.htpasswd
chmod 640 /etc/nginx/secrets/.htpasswd
Selanjutnya, file /etc/nginx/sites-available/php-worker di setiap worker diupdate untuk mengaktifkan autentikasi:

Nginx

server {
    listen [PORT];
    server_name [SERVER_DOMAIN];

    auth_basic "Restricted Content";
    auth_basic_user_file /etc/nginx/secrets/.htpasswd;

    root /var/www/html;
    index index.php;

}
```
Verifikasi dari Amandil. Akses tanpa kredensial gagal (401), sedangkan akses dengan kredensial berhasil (200 OK):
```
# (Dijalankan di Amandil)
curl http://galadriel.k40.com:8004
curl --user "noldor:silvan" http://galadriel.k40.com:8004
```

<img width="734" height="424" alt="image" src="https://github.com/user-attachments/assets/75372624-27d8-4543-9ce5-c6551e1d39b0" />

<img width="1107" height="325" alt="image" src="https://github.com/user-attachments/assets/64bea6b7-2adc-4509-a035-70d09e68049d" />

## Soal 15
Konfigurasi Nginx di setiap worker PHP (Galadriel, Celeborn, Oropher) dimodifikasi untuk menambahkan header X-Real-IP yang akan diteruskan ke PHP. File index.php juga diubah untuk membaca dan menampilkan IP pengunjung .

Script gabungan (mencakup Soal 12-15) berikut dijalankan di ketiga worker. Script ini (1) membuat file .htpasswd (Soal 14), (2) memperbaiki izinnya (dari troubleshooting), (3) mengatur port unik (Soal 13), (4) memblokir IP (Soal 12), dan (5) menambahkan logika X-Real-IP (Soal 15).
```
#!/bin/bash

set -eo pipefail # Opsi -u dihapus untuk menghindari error variabel Nginx
export DEBIAN_FRONTEND=noninteractive

if [ -z "$SERVER_DOMAIN" ] || [ -z "$PORT" ]; then 
    echo "Error: SERVER_DOMAIN dan PORT (e.g., 8004) harus di-set." >&2
    exit 1
fi

echo ">>> [PHP-Worker] Installing Nginx, PHP-FPM, and apache2-utils..."
apt-get update -y
apt-get install -y --no-install-recommends nginx php8.4-fpm apache2-utils

echo ">>> [PHP-Worker] Creating .htpasswd (noldor:silvan)"
mkdir -p /etc/nginx/secrets
htpasswd -cb /etc/nginx/secrets/.htpasswd noldor silvan
chown www-data /etc/nginx/secrets/.htpasswd
chmod 640 /etc/nginx/secrets/.htpasswd

echo ">>> [PHP-Worker] Creating /var/www/html/index.php to show IP"
mkdir -p /var/www/html
echo "<h1>Hello from <?php echo gethostname(); ?> (Port: $PORT)</h1><h2>My visitor IP is: <?php echo isset(\$_SERVER['HTTP_X_REAL_IP']) ? \$_SERVER['HTTP_X_REAL_IP'] : \$_SERVER['REMOTE_ADDR']; ?></h2>" > /var/www/html/index.php
chown -R www-data:www-data /var/www/html

echo ">>> [PHP-Worker] Configuring Nginx (port $PORT + Auth + X-Real-IP)"

cat > /etc/nginx/sites-available/php-worker <<EOF
server {
    listen $PORT default_server;
    return 444; # Blokir IP
}

server {
    listen $PORT;
    server_name $SERVER_DOMAIN;

    auth_basic "Restricted Content";
    auth_basic_user_file /etc/nginx/secrets/.htpasswd;

    root /var/www/html;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        
        fastcgi_param HTTP_X_REAL_IP \$http_x_real_ip;

        include fastcgi_params;
    }
}
EOF

ln -sf /etc/nginx/sites-available/php-worker /etc/nginx/sites-enabled/php-worker
rm -f /etc/nginx/sites-enabled/default

echo ">>> [PHP-Worker] Restarting services..."
nginx -t

pkill -x php-fpm8.4 2>/dev/null || true
php-fpm8.4 -D

pkill -x nginx 2>/dev/null || true
nginx

echo "✅ $SERVER_DOMAIN setup complete on Port $PORT (with Auth & X-Real-IP)."
```
Saat diakses langsung dari Amandil, IP masih kosong. Ini wajar karena X-Real-IP belum di-set (tidak ada proxy) dan REMOTE_ADDR kosong saat menggunakan socket.
```
root@Amandil:~# curl --user "noldor:silvan" http://galadriel.k40.com:8004
```

<img width="1103" height="102" alt="image" src="https://github.com/user-attachments/assets/adb00cc7-66d5-4146-84e4-d9e4817fe0c9" />


## Soal 16
Pharazon dikonfigurasi sebagai reverse proxy (Load Balancer) untuk worker PHP . Dibuat upstream bernama Kesatria_Lorien berisi Galadriel, Celeborn, dan Oropher. Nginx di Pharazon juga diatur untuk (1) meneruskan Basic Authentication (proxy_set_header Authorization) dan (2) mengatur header X-Real-IP (untuk Soal 15) dengan IP asli client ($remote_addr).

Script berikut (16-Pharazon.sh) dijalankan di node Pharazon:
```
#!/bin/bash

set -eo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> [Pharazon] Setting up static IP (192.231.2.7) and gateway"
ip addr add 192.231.2.7/24 dev eth0 2>/dev/null || true
ip route add default via 192.231.2.1 2>/dev/null || true
echo "nameserver 192.231.5.2" > /etc/resolv.conf

echo ">>> [Pharazon] Install Nginx"
apt-get update -y
apt-get install -y --no-install-recommends nginx

echo ">>> [Pharazon] Configure Nginx Upstream (Kesatria_Lorien)"
cat >/etc/nginx/conf.d/upstream_lorien.conf <<'EOF'
upstream Kesatria_Lorien {
    server 192.231.2.2:8004; # Galadriel
    server 192.231.2.3:8005; # Celeborn
    server 192.231.2.4:8006; # Oropher
}
EOF

echo ">>> [Pharazon] Configure Nginx Server Block (pharazon.k40.com)"
cat >/etc/nginx/sites-available/pharazon_proxy <<'EOF'
server {
    listen 80;
    server_name pharazon.k40.com;

    location / {
        proxy_pass http://Kesatria_Lorien;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Authorization $http_authorization;
        proxy_set_header Host $host;
    }
}
EOF

echo ">>> [Pharazon] Enable site and restart Nginx"
ln -sf /etc/nginx/sites-available/pharazon_proxy /etc/nginx/sites-enabled/pharazon_proxy
rm -f /etc/nginx/sites-enabled/default

nginx -t
pkill -x nginx 2>/dev/null || true
nginx

echo "✅ Pharazon (Load Balancer) ready."
```
Untuk memperbaiki error 502 Bad Gateway, server_name di setiap worker PHP (Galadriel, Celeborn, Oropher) diupdate agar menerima pharazon.k40.com:
```
sed -i "s/server_name \(.*\);/server_name \1 pharazon.k40.com;/" /etc/nginx/sites-available/php-worker
nginx -t && nginx -s reload
```
Verifikasi dari Amandil sekarang berhasil DAN menampilkan IP Amandil, membuktikan Soal 15 dan 16 bekerja:
```
curl --user "noldor:silvan" http://pharazon.k40.com
```

Soal 20
Nginx Caching diaktifkan pada Pharazon untuk menyimpan salinan halaman PHP dan mengurangi beban pada worker. Sebuah cache path (lorien_cache) didefinisikan di nginx.conf dan diaktifkan di konfigurasi server block Pharazon. Header X-Cache-Status ditambahkan untuk memverifikasi status cache (HIT/MISS).

Script 20-Pharazon-Cache.sh dijalankan di Pharazon. Script ini menggabungkan konfigurasi Soal 16 dan 20:
```
#!/bin/bash

set -eo pipefail
export DEBIAN_FRONTEND=noninteractive

CONF_NGINX="/etc/nginx/nginx.conf"
CONF_SITE="/etc/nginx/sites-available/pharazon_proxy"
CACHE_DIR="/var/cache/nginx/lorien_cache"


echo ">>> [Pharazon] 1. Defining cache path in nginx.conf"
mkdir -p $CACHE_DIR
chown -R www-data:www-data /var/cache/nginx

if ! grep -q "keys_zone=lorien_cache" $CONF_NGINX; then
    sed -i "/http {/a \    proxy_cache_path $CACHE_DIR levels=1:2 keys_zone=lorien_cache:10m max_size=100m inactive=60m use_temp_path=off;" $CONF_NGINX
fi

echo ">>> [Pharazon] 2. Configure Nginx Server Block (Cache Active)"
cat > $CONF_SITE <<'EOF'
server {
    listen 80;
    server_name pharazon.k40.com;

    location / {
        proxy_cache lorien_cache;
        proxy_cache_valid 200 1m; # Cache respons 200 OK selama 1 menit
        
        add_header X-Cache-Status $upstream_cache_status;

        proxy_pass http://Kesatria_Lorien;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Authorization $http_authorization;
    }
}
EOF

echo "✅ Pharazon (Cache) ready."
```
Verifikasi dilakukan dengan memantau log worker (cth: Galadriel) dan menggunakan curl -I dari Amandil.

Permintaan Pertama: Menghasilkan X-Cache-Status: MISS. Log baru muncul di Galadriel. Permintaan Kedua: Menghasilkan X-Cache-Status: HIT. Log tidak muncul di Galadriel.

Ini membuktikan bahwa permintaan kedua disajikan dari cache Pharazon dan tidak membebani worker PHP.
```
# Permintaan Pertama
root@Amandil:~# curl -I --user "noldor:silvan" http://pharazon.k40.com
HTTP/1.1 200 OK
Server: nginx
Date: Wed, 05 Nov 2025 19:38:44 GMT
Content-Type: text/html; charset=UTF-8
Connection: keep-alive
X-Cache-Status: MISS

# Permintaan Kedua
root@Amandil:~# curl -I --user "noldor:silvan" http://pharazon.k40.com
HTTP/1.1 200 OK
Server: nginx
Date: Wed, 05 Nov 2025 19:38:57 GMT
Content-Type: text/html; charset=UTF-8
Connection: keep-alive
X-Cache-Status: HIT
```

<img width="1105" height="472" alt="image" src="https://github.com/user-attachments/assets/332925f5-2a7e-4e3e-bf4b-d2fa500c8467" />

