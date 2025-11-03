#!/bin/bash

set -e
apt-get update -y
apt-get install -y apache2-utils

echo ">>> [Miriel] Pastikan DNS mengarah ke Minastir"
echo "nameserver 192.231.5.2" > /etc/resolv.conf

echo "--- (Soal 19) Tes Rate Limit Pharazon (-c 50) ---"

ab -n 100 -c 50 -A noldor:silvan http://pharazon.k40.com/
echo "--- Tes Pharazon Selesai ---"
echo "Lihat 'Failed requests' di atas. Jika > 0, rate limit bekerja!"
echo "Cek log di Pharazon: grep 'limiting requests' /var/log/nginx/error.log"

sleep 5

echo "--- (Soal 19) Tes Rate Limit Elros (-c 50) ---"
ab -n 100 -c 50 http://elros.k40.com/api/airing/
echo "--- Tes Elros Selesai ---"