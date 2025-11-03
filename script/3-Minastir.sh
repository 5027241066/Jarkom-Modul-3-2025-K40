#!/bin/bash
# ==========================================================
# Minastir – DNS Forwarder (Soal 3, FINAL FIX)
# - Forwarder umum: 192.168.122.1, 8.8.8.8
# - Conditional forwarder: 
# ==========================================================
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
# ===== Forwarder untuk domain utama =====
zone "k40.com" {
    type forward;
    forward only;
    forwarders { 192.231.3.3; 192.231.3.4; };
};

# ===== Forwarder untuk reverse lookup (PTR) =====
zone "3.231.192.in-addr.arpa" {
    type forward;
    forward only;
    forwarders { 192.231.3.3; 192.231.3.4; };
};
EOF

echo ">>> [Minastir] Bersihkan cache & restart named"
pkill -x named 2>/dev/null || true
rndc flush 2>/dev/null || true
sleep 1

echo ">>> [Minastir] Jalankan named (tanpa systemd)"
named -4 -u bind -c /etc/bind/named.conf -g &
sleep 2

(ss -lun 2>/dev/null || netstat -lun 2>/dev/null) | grep -w ':53' || echo "WARN: UDP port 53 belum terlihat"

echo "✅ Minastir siap."
echo "Uji cepat:"
echo "  dig @192.231.5.2 google.com +short"
echo "  dig @192.231.5.2 elendil.k40.com +short"
echo "  dig @192.231.5.2 -x 192.231.3.3 +short   # → ns1.k40.com."
echo "  dig @192.231.5.2 -x 192.231.3.4 +short   # → ns2.k40.com."
