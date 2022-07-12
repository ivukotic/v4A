FROM varnish:fresh-alpine

# COPY default.vcl /etc/varnish/
USER root
RUN apk add --no-cache --upgrade curl bash
USER varnish
COPY sender.sh /usr/local/bin/