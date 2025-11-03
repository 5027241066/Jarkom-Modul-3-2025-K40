#!/bin/bash


set -e

echo ">>> Pastikan Soal 8-10 (Elros & Laravel Workers) sudah selesai!"
sleep 3

echo ">>> Install Apache Bench (ab)"
apt-get update -y
apt-get install -y apache2-utils


echo "nameserver 192.231.5.2" > /etc/resolv.conf

echo "--- Menjalankan Serangan Awal (-n 100 -c 10) ---"
ab -n 100 -c 10 http://elros.k40.com/api/airing/
echo "--- Serangan Awal Selesai ---"

sleep 5

echo "--- Menjalankan Serangan Penuh (-n 2000 -c 100) ---"
ab -n 2000 -c 100 http://elros.k40.com/api/airing/
echo "--- Serangan Penuh Selesai ---"

echo ""
echo "========================================================="
echo "STRATEGI BERTAHAN (Weight):"
echo "1. Buka terminal Elros."
echo "2. Edit file Nginx: nano /etc/nginx/sites-available/default"
echo "3. Ubah blok 'upstream kesatria_numenor' Anda."
echo "4. Tambahkan 'weight=3' ke salah satu worker, contoh:"
echo ""
echo "   upstream kesatria_numenor {"
echo "       server 192.231.1.4:8001 weight=3;"
echo "       server 192.231.1.5:8002;"
echo "       server 192.231.1.6:8003;"
echo "   }"
echo ""
echo "5. Reload Nginx di Elros: nginx -s reload"
echo "6. Jalankan ulang script ini di Miriel."
echo "========================================================="