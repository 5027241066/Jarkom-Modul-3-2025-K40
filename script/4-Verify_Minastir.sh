# Erendis (MASTER):

dig @192.231.3.3 k40.com SOA +short
dig @192.231.3.3 elendil.k40.com +short

# Amdir (SLAVE):

dig @192.231.3.4 k40.com SOA +short
dig @192.231.3.4 elendil.k40.com +short

# Minastir (FORWARDER) — validasi jalur dari “luar”:

dig @192.231.5.2 elendil.k40.com +short
dig @192.231.5.2 pharazon.k40.com +short
