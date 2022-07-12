FROM varnish:fresh-alpine

# COPY default.vcl /etc/varnish/
COPY sender.sh /etc/varnish/