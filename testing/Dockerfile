FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends siege ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

COPY urls_100k.txt /work/urls_100k.txt
COPY runme.sh /work/runme.sh
RUN ln -s /usr/bin/siege /work/siege