echo "Starting Varnish on port $VARNISH_PORT with $VARNISH_MEM memory"
service snmpd start
su varnish -c '/usr/sbin/varnishd -F -f /etc/varnish/default.vcl -a http=:$VARNISH_PORT,HTTP -a proxy=:8443,PROXY -p feature=+http2 -s malloc,$VARNISH_MEM'

