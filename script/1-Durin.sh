#!/bin/bash
# ==========================================================
# Durin – Router, NAT, DHCP Relay (Soal 1–3)
# ==========================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo ">>> [Durin] Install tools"
apt-get update -y
apt-get install -y --no-install-recommends isc-dhcp-relay iptables iproute2

echo ">>> [Durin] Enable IPv4 forwarding (immediate + persistent)"
echo 1 > /proc/sys/net/ipv4/ip_forward
mkdir -p /etc/sysctl.d
cat >/etc/sysctl.d/99-ipforward.conf <<EOF
net.ipv4.ip_forward=1
EOF
sysctl -p /etc/sysctl.d/99-ipforward.conf

echo ">>> [Durin] NAT for internal subnets (1–5) via eth0"
# idempotent: flush table POSTROUTING lalu set ulang
iptables -t nat -F POSTROUTING || true
iptables -t nat -A POSTROUTING -s 192.231.1.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.231.2.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.231.3.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.231.4.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.231.5.0/24 -o eth0 -j MASQUERADE

# Forward rules permissive (aman jika default policy ACCEPT; harmless kalau dobel)
iptables -C FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
for IF in eth1 eth2 eth3 eth4 eth5; do
  iptables -C FORWARD -i "$IF" -o eth0 -j ACCEPT 2>/dev/null || \
  iptables -A FORWARD -i "$IF" -o eth0 -j ACCEPT
  iptables -C FORWARD -i eth0 -o "$IF" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
  iptables -A FORWARD -i eth0 -o "$IF" -m state --state RELATED,ESTABLISHED -j ACCEPT
done

echo ">>> [Durin] Configure DHCP Relay → Aldarion (192.231.4.2)"
mkdir -p /etc/default
cat > /etc/default/isc-dhcp-relay <<'EOF'
SERVERS="192.231.4.2"
INTERFACES="eth1 eth2 eth3 eth4 eth5"
OPTIONS=""
EOF

# Hentikan relay lama (kalau ada), lalu jalankan foreground/quiet di background
pkill -x dhcrelay 2>/dev/null || true
# Pakai -i per-interface agar eksplisit; -4 untuk IPv4 only; -q quiet; --no-pid untuk container
dhcrelay -4 -q --no-pid -i eth1 -i eth2 -i eth3 -i eth4 -i eth5 192.231.4.2 &

echo ">>> [Durin] Quick checks"
sysctl net.ipv4.ip_forward
iptables -t nat -L POSTROUTING -v -n
pgrep -af '^dhcrelay' || echo "WARN: dhcrelay not running?"

echo ">>> [Durin] Ready."
