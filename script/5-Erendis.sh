#!/bin/bash
# ==========================================================
# Erendis – DNS MASTER (Soal 5, k40.com + reverse 3.231.192.in-addr.arpa)
# - Tambah: CNAME www, TXT (Elros/Pharazon), PTR (Erendis/Amdir)
# - AXFR ke Amdir (192.231.3.4)
# ==========================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

MASTER_IP=192.231.3.3
SLAVE_IP=192.231.3.4
ZDIR=/etc/bind/zones
FWD_ZONE=k40.com
REV_ZONE=3.231.192.in-addr.arpa

echo ">>> [Erendis] Install bind9 (if needed)"
apt-get update -y
apt-get install -y --no-install-recommends bind9 bind9-utils dnsutils || \
apt-get install -y --no-install-recommends bind9 bind9utils dnsutils

mkdir -p "$ZDIR"
chown -R bind:bind /etc/bind /var/cache/bind

echo ">>> [Erendis] named.conf.options (authoritative only)"
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

echo ">>> [Erendis] Forward zone file ($FWD_ZONE)"
cat > "$ZDIR/db.$FWD_ZONE" <<'EOF'
$TTL 604800
@   IN  SOA ns1.k40.com. root.k40.com. (
        2025110102 ; serial
        3600       ; refresh
        900        ; retry
        1209600    ; expire
        300 )      ; minimum

    IN  NS  ns1.k40.com.
    IN  NS  ns2.k40.com.

; Nameservers
ns1 IN  A   192.231.3.3
ns2 IN  A   192.231.3.4

; ===== A records (Soal #4) =====
palantir   IN A 192.231.4.3
elros      IN A 192.231.1.7
pharazon   IN A 192.231.2.7
elendil    IN A 192.231.1.2
isildur    IN A 192.231.1.3
anarion    IN A 192.231.1.4
galadriel  IN A 192.231.2.2
celeborn   IN A 192.231.2.3
oropher    IN A 192.231.2.4

; ===== Soal #5 additions =====
www        IN CNAME k40.com.               ; CNAME apex
elros      IN TXT   "Cincin Sauron"        ; TXT #1
pharazon   IN TXT   "Aliansi Terakhir"     ; TXT #2
EOF

echo ">>> [Erendis] Reverse zone file ($REV_ZONE)"
cat > "$ZDIR/db.$REV_ZONE" <<'EOF'
$TTL 604800
@   IN  SOA ns1.k40.com. root.k40.com. (
        2025110101 ; serial
        3600       ; refresh
        900        ; retry
        1209600    ; expire
        300 )      ; minimum

    IN  NS  ns1.k40.com.
    IN  NS  ns2.k40.com.

; PTR (Soal #5) – subnet 192.231.3.0/24
3   IN  PTR ns1.k40.com.   ; 192.231.3.3  -> Erendis
4   IN  PTR ns2.k40.com.   ; 192.231.3.4  -> Amdir
EOF

echo ">>> [Erendis] named.conf.local (2 zones: forward + reverse)"
cat > /etc/bind/named.conf.local <<EOF
zone "$FWD_ZONE" {
  type master;
  file "$ZDIR/db.$FWD_ZONE";
  allow-transfer { $SLAVE_IP; };
  also-notify    { $SLAVE_IP; };
  notify yes;
};

zone "$REV_ZONE" {
  type master;
  file "$ZDIR/db.$REV_ZONE";
  allow-transfer { $SLAVE_IP; };
  also-notify    { $SLAVE_IP; };
  notify yes;
};
EOF

echo ">>> [Erendis] Validate"
named-checkconf
named-checkzone "$FWD_ZONE" "$ZDIR/db.$FWD_ZONE"
named-checkzone "$REV_ZONE" "$ZDIR/db.$REV_ZONE"

echo ">>> [Erendis] Start named (no systemd)"
pkill -x named 2>/dev/null || true
mkdir -p /run/named && chown bind:bind /run/named
named -4 -u bind -c /etc/bind/named.conf -g &

sleep 1
(ss -lun 2>/dev/null || netstat -lun 2>/dev/null) | grep -w ':53' || echo "WARN: UDP 53 belum terlihat"

echo "✅ Erendis MASTER ready (Soal 5)."
echo "Cek:"
echo "  dig @192.231.3.3 k40.com SOA +short"
echo "  dig @192.231.3.3 www.k40.com CNAME +short"
echo "  dig @192.231.3.3 elros.k40.com TXT +short"
echo "  dig @192.231.3.3 -x 192.231.3.3 +short"
echo "  dig @192.231.3.3 -x 192.231.3.4 +short"
