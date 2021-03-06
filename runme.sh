echo "Starting Varnish on port $VARNISH_PORT with $VARNISH_MEM memory"

if [ -n $MONITOR_SNMP ]
then
  if [ $MONITOR_SNMP == "true" ]
  then
    # service snmpd start
    /usr/sbin/snmpd -LS 5 d -Lf /var/log/snmpd.log -p /var/run/snmpd.PID -a -d -V
  fi
fi

chsh -s /bin/bash varnish
su varnish -c '/usr/sbin/varnishd -F -f /etc/varnish/default.vcl -a http=:$VARNISH_PORT,HTTP -a proxy=:8443,PROXY -p feature=+http2 -s malloc,$VARNISH_MEM'