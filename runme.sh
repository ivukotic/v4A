echo "Starting Varnish on port $VARNISH_PORT"
echo "Using $VARNISH_MEM memory, and $VARNISH_TRANSIENT_MEM"

/usr/sbin/varnishd -F -f /etc/varnish/default.vcl -a http=:$VARNISH_PORT,HTTP -a proxy=:8443,PROXY -p feature=+http2 -p max_restarts=8 -s malloc,$VARNISH_MEM -s Transient=malloc,$VARNISH_TRANSIENT_MEM
