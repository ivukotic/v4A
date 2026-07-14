#!/bin/bash
# ExecStart target for frontier-varnish-apptainer.service.
# Runs the v4a image in the foreground under Apptainer so systemd can
# supervise and restart it, the same way it supervises native varnishd
# in the bare-metal (VM/) setup.
set -euo pipefail

: "${SITE:?SITE must be set (see /etc/sysconfig/frontier-varnish-apptainer)}"
: "${INSTANCE:?INSTANCE must be set (see /etc/sysconfig/frontier-varnish-apptainer)}"
: "${VARNISH_PORT:=6082}"
: "${VARNISH_MEM:=8G}"
: "${VARNISH_TRANSIENT_MEM:=500M}"
: "${IMAGE:=/opt/v4a-apptainer/v4a.sif}"
: "${VARNISH_WORKDIR:=/opt/v4a-apptainer/varnish-workdir}"

mkdir -p "$VARNISH_WORKDIR"

# When run under systemd, LimitNOFILE in the unit already raises this;
# when run manually, best-effort raise it here too.
ulimit -n 131072 2>/dev/null || echo "warning: could not raise ulimit -n to 131072 - raise the host's limit for this service"

# /var/lib/varnish is where varnishd keeps its shared-memory log (VSM). The
# Apptainer image is read-only, so that path is bind-mounted to a writable
# directory on the host.
exec apptainer run \
  --bind "${VARNISH_WORKDIR}:/var/lib/varnish" \
  --env SITE="$SITE" \
  --env INSTANCE="$INSTANCE" \
  --env VARNISH_PORT="$VARNISH_PORT" \
  --env VARNISH_MEM="$VARNISH_MEM" \
  --env VARNISH_TRANSIENT_MEM="$VARNISH_TRANSIENT_MEM" \
  "$IMAGE"
