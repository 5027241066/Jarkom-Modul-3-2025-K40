#!/bin/bash


set -e

echo ">>> [Miriel] Install Apache Bench (ab)"
apt-get update -y
apt-get install -y apache2-utils

echo "nameserver 192.231.5.2" > /etc/resolv.conf

echo ""
echo "--- (Soal 17) Menjalankan Benchmark 1 (Semua worker UP) ---"
echo "--- (Menggunakan user:noldor pass:silvan) ---"

ab -n 100 -c 10 -A noldor:silvan http://pharazon.k40.com/

echo ""
echo "======================================================================"
echo "          >>> PERSIAPAN SIMULASI GAGAL (SOAL 17) <<<"
echo ""
echo "Buka terminal Galadriel (telnet 10.15.43.32 5449)"
echo "Dan jalankan perintah ini untuk mematikan Nginx:"
echo "pkill nginx"
echo ""
echo "Setelah Nginx di Galadriel MATI, tekan [ENTER] di sini untuk lanjut..."
read
echo "======================================================================"
echo ""

echo "--- (Soal 17) Menjalankan Benchmark 2 (1 worker DOWN) ---"
ab -n 100 -c 10 -A noldor:silvan http://pharazon.k40.com/

echo ""
echo "--- TES SELESAI ---"
echo "Periksa output di atas. Jika 'Failed requests' tetap 0, Pharazon berhasil!"
echo "Jangan lupa nyalakan lagi Nginx di Galadriel: nginx"