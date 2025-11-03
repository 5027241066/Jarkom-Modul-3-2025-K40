#!/bin/bash
# ==============================================
# Erendis – DNS Master for k40.com (Soal #4)
# ns1 = 192.231.3.3, ns2 (slave) = 192.231.3.4
# Records (sesuai soal #4): Palantir, Elros, Pharazon,
# Elendil, Isildur, Anarion, Galadriel, Celeborn, Oropher
# ==============================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> [Erendis] Install bind9"
apt-get update -y
apt-get install -y --no-install-recommends bind9 bind9-utils dnsutils || \
apt-get install -y --no-install-recommends bind9 bind9utils dnsutils

mkdir -p /etc/bind/zones
chown -R bind:bind /etc/bind

# Opsi global minimal (authoritative; recursion tidak diperlukan di master)
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

# Zona utama k40.com (MASTER)
cat > /etc/bind/zones/db.k40.com <<'EOF'
$TTL 604800
@   IN  SOA ns1.k40.com. root.k40.com. (
        2025110101 ; serial (YYYYMMDDnn)
        3600       ; refresh
        900        ; retry
        1209600    ; expire
        300 )      ; minimum

    IN  NS  ns1.k40.com.
    IN  NS  ns2.k40.com.

; Name servers
ns1 IN  A   192.231.3.3
ns2 IN  A   192.231.3.4

; ===== A records sesuai Soal #4 =====
palantir   IN A 192.231.4.3
elros      IN A 192.231.1.7
pharazon   IN A 192.231.2.7
elendil    IN A 192.231.1.2
isildur    IN A 192.231.1.3
anarion    IN A 192.231.1.4
galadriel  IN A 192.231.2.2
celeborn   IN A 192.231.2.3
oropher    IN A 192.231.2.4
EOF

# Deklarasi zona + transfer ke Amdir (slave)
cat > /etc/bind/named.conf.local <<'EOF'
zone "k40.com" {
    type master;
    file "/etc/bind/zones/db.k40.com";
    allow-transfer { 192.231.3.4; };
    also-notify    { 192.231.3.4; };
    notify yes;
};
EOF

echo ">>> [Erendis] Validate config & zone"
named-checkconf
named-checkzone k40.com /etc/bind/zones/db.k40.com

echo ">>> [Erendis] Start named (no systemd)"
pkill -x named 2>/dev/null || true
mkdir -p /run/named && chown bind:bind /run/named
named -4 -u bind -c /etc/bind/named.conf -g &

sleep 1
(ss -ltnup 2>/dev/null || netstat -tulpn 2>/dev/null) | grep -w ':53' || echo "WARN: Port 53 belum terlihat"

echo "✅ Erendis (MASTER) ready."
echo "Cek: dig @192.231.3.3 k40.com SOA +short"
