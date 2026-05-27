FROM varnish:9

ARG BUILD_DATE=unknown

LABEL description="Varnish 9 with reconfiguration and monitoring scripts" \
    maintainer="Ilija Vukotic" \
    build.date="${BUILD_DATE}"

ENV BUILD_DATE=${BUILD_DATE}

USER root

# debian version
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install curl jq procps iproute2 \
    && rm -rf /var/lib/apt/lists/*

# vim 

COPY runme.sh reconfiguration.sh Monitoring/sender.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/runme.sh /usr/local/bin/reconfiguration.sh /usr/local/bin/sender.sh

ENV VARNISH_MEM=6000m
ENV VARNISH_TRANSIENT_MEM=200m
ENV VARNISH_PORT=6081

USER varnish

ENTRYPOINT []
CMD [ "/usr/local/bin/runme.sh" ]
