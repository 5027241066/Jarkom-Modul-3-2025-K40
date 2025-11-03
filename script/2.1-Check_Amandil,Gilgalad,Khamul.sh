# 1) IP sementara hanya untuk install paket
ip addr add 192.231.2.200/24 dev eth0
ip route add default via 192.231.2.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf   # atau pakai 192.231.5.2 jika Minastir sudah siap

# 2) Install DHCP client
apt-get update && apt-get install -y isc-dhcp-client

# 3) Lepas IP sementara & minta lease dari Aldarion via Durin
ip addr flush dev eth0
dhclient -v eth0

# 4) Cek hasil
ip a show dev eth0
ip route
cat /etc/resolv.conf


# --------------
ip a