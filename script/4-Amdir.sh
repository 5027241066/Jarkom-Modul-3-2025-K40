#!/bin/bash
# ==============================================
# Amdir – DNS Slave for k40.com (Soal #4)
# ns2 = 192.231.3.4, master ns1 = 192.231.3.3
# ==============================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> [Amdir] Install bind9"
apt-get update -y
apt-get install -y --no-install-recommends bind9 bind9-utils dnsutils || \
apt-get install -y --no-install-recommends bind9 bind9utils dnsutils

mkdir -p /var/lib/bind
chown -R bind:bind /var/lib/bind /etc/bind

# Opsi global minimal (slave tidak butuh recursion untuk lab ini)
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

# Zona SLAVE (akan auto-AXFR dari Erendis)
cat > /etc/bind/named.conf.local <<'EOF'
zone "k40.com" {
    type slave;
    masters { 192.231.3.3; };
    file "/var/lib/bind/db.k40.com";
    notify no;
};
EOF

echo ">>> [Amdir] Validate config"
named-checkconf

echo ">>> [Amdir] Start named (no systemd)"
pkill -x named 2>/dev/null || true
mkdir -p /run/named && chown bind:bind /run/named
named -4 -u bind -c /etc/bind/named.conf -g &

sleep 1
(ss -ltnup 2>/dev/null || netstat -tulpn 2>/dev/null) | grep -w ':53' || echo "WARN: Port 53 belum terlihat"

echo "✅ Amdir (SLAVE) ready."
echo "Cek: dig @192.231.3.4 k40.com SOA +short"
