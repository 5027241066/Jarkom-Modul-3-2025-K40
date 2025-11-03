#!/bin/bash
# ==========================================================
# Amdir – DNS SLAVE (Soal 5, k40.com + reverse 3.231.192.in-addr.arpa)
# - Menerima AXFR dari Erendis (192.231.3.3)
# ==========================================================
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
