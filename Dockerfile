FROM varnish:fresh-alpine

# COPY default.vcl /etc/varnish/
RUN sender.sh /etc/varnish/