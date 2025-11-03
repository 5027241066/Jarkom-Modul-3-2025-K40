#!/bin/bash

sleep 5
echo "Mengecek data di Slave (Narvi)..."
mysql -u root -e "USE test_replikasi; SELECT * FROM bukti;" | grep "ReplikasiBerhasil"

if [ $? -eq 0 ]; then
    echo "✅ BERHASIL: Data dari Palantir ditemukan di Narvi."
else
    echo "❌ GAGAL: Data tidak ditemukan."
    echo "Cek status slave: mysql -u root -e 'SHOW SLAVE STATUS\G'"
fi