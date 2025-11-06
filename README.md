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

