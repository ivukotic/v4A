# https://wiki.squid-cache.org/Features/Snmp

snmpwalk -m /usr/share/squid/mib.txt -v2c -Cc -c snmp_community localhost:3401 .1.3.6.1.4.1.3495.1.1
