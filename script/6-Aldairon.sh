#!/bin/bash
# ==========================================================
# Soal 6 – Aldarion (ISC DHCP) : Lease time per keluarga
# Manusia: 1800s, Peri: 600s, Max semua: 3600s
# Prefix: 192.231
# ==========================================================
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

# Manusia – 30 menit
subnet 192.231.1.0 netmask 255.255.255.0 {
  option routers 192.231.1.1;
  default-lease-time 1800;
  range 192.231.1.6 192.231.1.34;
  range 192.231.1.68 192.231.1.94;
}

# Peri – 10 menit
subnet 192.231.2.0 netmask 255.255.255.0 {
  option routers 192.231.2.1;
  default-lease-time 600;
  range 192.231.2.35 192.231.2.67;
  range 192.231.2.96 192.231.2.121;
}

# Dwarf – alamat tetap
subnet 192.231.3.0 netmask 255.255.255.0 {
  option routers 192.231.3.1;
  host khamul {
    hardware ethernet 02:42:13:30:01:00;
    fixed-address 192.231.3.95;
  }
}

# Jaringan non-client
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
