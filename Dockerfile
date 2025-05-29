FROM varnish
# FROM varnish:fresh-alpine

USER root

# alpine version
# RUN apk add --no-cache --upgrade curl bash  jq

# debian version
RUN apt-get update; apt-get -y install curl jq vim python3 procps iproute2

COPY default.vcl /etc/varnish/

COPY runme.sh reconfiguration.sh Monitoring/sender.sh /usr/local/bin/

ENV VARNISH_MEM=6000m
ENV VARNISH_TRANSIENT_MEM=2000m
ENV VARNISH_PORT=6081

HEALTHCHECK --interval=10s --timeout=9s --retries=3 --start-period=60s CMD /usr/local/bin/sender.sh

USER varnish
CMD [ "/usr/local/bin/runme.sh" ]