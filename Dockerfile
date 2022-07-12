FROM varnish:fresh-alpine

# COPY default.vcl /etc/varnish/
RUN whoami
USER root
RUN whoami
RUN apk add curl
USER varnish
COPY sender.sh /etc/varnish/