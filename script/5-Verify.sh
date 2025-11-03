# Erendis (MASTER):

dig @192.231.3.3 k40.com SOA +short
dig @192.231.3.3 www.k40.com CNAME +short          # => k40.com.
dig @192.231.3.3 elros.k40.com TXT +short          # => "Cincin Sauron"
dig @192.231.3.3 pharazon.k40.com TXT +short       # => "Aliansi Terakhir"
dig @192.231.3.3 -x 192.231.3.3 +short             # => ns1.k40.com.
dig @192.231.3.3 -x 192.231.3.4 +short             # => ns2.k40.com.


# Amdir (SLAVE):

dig @192.231.3.4 k40.com SOA +short
dig @192.231.3.4 www.k40.com CNAME +short
dig @192.231.3.4 elros.k40.com TXT +short
dig @192.231.3.4 -x 192.231.3.4 +short


# Minastir (FORWARDER) — validasi jalur dari “luar”:

dig @192.231.5.2 www.k40.com CNAME +short          # => k40.com.
dig @192.231.5.2 -x 192.231.3.3 +short             # => ns1.k40.com.
dig @192.231.5.2 elros.k40.com TXT +short
dig @192.231.5.2 pharazon.k40.com TXT +short
