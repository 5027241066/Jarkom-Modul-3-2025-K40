#!/bin/bash
# ==========================================================
# Aldarion – DHCP Server (Soal 2)
# ==========================================================
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

# DNS order: Minastir (Forwarder), Erendis (Master), Amdir (Slave)
option domain-name-servers 192.231.5.2, 192.231.3.3, 192.231.3.4;

# Lease time dasar (Soal #6 akan menyesuaikan per-keluarga nanti)
default-lease-time 600;
max-lease-time 7200;

# Humans – 192.231.1.0/24   (Soal #2)
subnet 192.231.1.0 netmask 255.255.255.0 {
    option routers 192.231.1.1;
    range 192.231.1.6 192.231.1.34;
    range 192.231.1.68 192.231.1.94;
}

# Elves – 192.231.2.0/24   (Soal #2)
subnet 192.231.2.0 netmask 255.255.255.0 {
    option routers 192.231.2.1;
    range 192.231.2.35 192.231.2.67;
    range 192.231.2.96 192.231.2.121;
}

# Dwarves – 192.231.3.0/24 (Khamul fixed)   (Soal #2)
subnet 192.231.3.0 netmask 255.255.255.0 {
    option routers 192.231.3.1;

    host khamul {
        hardware ethernet 02:42:ee:78:cc:00;   # MAC tetap (update jika berubah)
        fixed-address 192.231.3.95;
    }
}

# Link lokal server/relay agar dhcpd mengakui interface dan membalas via Durin
subnet 192.231.4.0 netmask 255.255.255.0 {
    option routers 192.231.4.1;
}

# (Bila diperlukan oleh topologi) deklarasi jaringan Minastir
subnet 192.231.5.0 netmask 255.255.255.0 {
    option routers 192.231.5.1;
}
EOF

echo ">>> [Aldarion] Validate config"
dhcpd -t -cf /etc/dhcp/dhcpd.conf

# Opsional tapi berguna: pastikan jalur balik lewat Durin
ip route replace default via 192.231.4.1 || true

echo ">>> [Aldarion] Start DHCP server (works without systemd)"
pkill dhcpd 2>/dev/null || true

# coba lewat service jika tersedia
if command -v service >/dev/null 2>&1 && service --status-all 2>/dev/null | grep -q dhcp; then
    service isc-dhcp-server stop 2>/dev/null || true
    service isc-dhcp-server start 2>/dev/null || true
fi

# fallback manual (tanpa systemd)
sleep 0.5
if ! pgrep -x dhcpd >/dev/null 2>&1; then
    echo ">>> launching dhcpd manually..."
    dhcpd -4 -cf /etc/dhcp/dhcpd.conf -lf /var/lib/dhcp/dhcpd.leases -pf /run/dhcpd.pid -q --no-pid eth0 &
    sleep 1
fi

# verifikasi hasil
if pgrep -x dhcpd >/dev/null 2>&1; then
    echo ">>> dhcpd running OK ($(pgrep -x dhcpd))"
else
    echo "ERROR: dhcpd failed to start. Check syntax or interface mapping!"
fi

echo ">>> [Aldarion] Ready."

