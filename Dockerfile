FROM varnish:9
# FROM varnish:fresh-alpine

ARG BUILD_DATE=unknown

LABEL description="Varnish 9 with reconfiguration and monitoring scripts" \
    maintainer="Ilija Vukotic" \
    build.date="${BUILD_DATE}"

ENV BUILD_DATE=${BUILD_DATE}

USER root

# alpine version
# RUN apk add --no-cache --upgrade curl bash jq

# debian version
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install curl jq procps iproute2 \
    && rm -rf /var/lib/apt/lists/*

# vim 

COPY runme.sh reconfiguration.sh Monitoring/sender.sh /usr/local/bin/

ENV VARNISH_MEM=4000m
ENV VARNISH_TRANSIENT_MEM=2000m
ENV VARNISH_PORT=6082

HEALTHCHECK --interval=10s --timeout=9s --retries=3 --start-period=60s CMD /usr/local/bin/sender.sh

USER varnish

ENTRYPOINT []
CMD [ "/usr/local/bin/runme.sh" ]
