apt-get install snmpd snmp libsnmp-dev -y

/etc/init.d/snmpd stop 
/usr/sbin/snmpd -LS 5 d -Lf /var/log/snmpd.log -p /var/run/snmpd.PID -a -d -V
tail -f /var/log/snmpd.log

snmpwalk -m /usr/share/snmp/mibs/squid/SQUID-MIB.txt -v2c -Cc -c snmp_community localhost:3401 
snmpwalk  -v2c -Cc -c snmp_community localhost:3401 .1.3.6.1.4.1.3495.1.1
snmpwalk  -v2c -Cc -c snmp_community localhost:3401 .1.3.6.1.4.1.3495


snmpwalk -m /usr/share/snmp/mibs/squid/SQUID-MIB.txt -v2c -Cc -c snmp_community tcp:localhost:161 .1.3.6.1.4.1.3495.1.1.1.0

squid OIDS 1.3.6.1.4.1.3495
special 1.3.6.1.4.1.8072.1.3.2.2.1

snmpd_sender.py
PING
set
.1.2.2.3.3.3
asdf
get
1.3.6.1.4.1.3495.1.5.2.2.10