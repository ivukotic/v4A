#!/bin/bash
# ExecStart target for frontier-varnish-monitor-apptainer.service.
#
# Mirrors VM/usr/local/bin/frontier-varnish-monitor.sh: reads varnishstat
# from the running instance and posts it to Kibana. There is no Docker
# HEALTHCHECK under Apptainer, so this replaces that mechanism as a
# standalone, systemd-supervised loop instead of an optional extra.
#
# It runs varnishstat/jq/ss/curl *inside* the image (via apptainer exec)
# rather than requiring them on the host. It reaches the same VSM as the
# running varnishd by bind-mounting the same VARNISH_WORKDIR, and sees the
# same network connections because Apptainer shares the host's network and
# UTS namespaces by default (no --net/--hostname flags are used anywhere
# in this kit).
set -euo pipefail

: "${SITE:?SITE must be set (see /etc/sysconfig/frontier-varnish-apptainer)}"
: "${INSTANCE:?INSTANCE must be set (see /etc/sysconfig/frontier-varnish-apptainer)}"
: "${IMAGE:=/opt/v4a-apptainer/v4a.sif}"
: "${VARNISH_WORKDIR:=/opt/v4a-apptainer/varnish-workdir}"
: "${URL_ML:=http://varnish.atlas-ml.org:80/}"
: "${URL_ML_ACCESS:=http://varnish-accesses.atlas-ml.org:80/}"

read -r -d '' MONITOR_BODY <<'SCRIPT' || true
while true; do
  data=$(varnishstat -j -X "VBE.boot.*.happy" -X "WAITER*" -X "LCK*" -X "MEM*" -X "SMA.*c_*" -X "MGT*")
  fdata=$(echo "$data" | jq '.counters |= with_entries(.value = .value["value"])')
  fdatb=$(echo "$fdata" | jq '.counters as $c | del(.counters) + $c')
  jsn=$(echo "$fdatb" | jq --arg INST "$INSTANCE" --arg SITE "$SITE" '. += { kind: "frontier", instance: $INST, site: $SITE }')

  timeout 2 curl --request POST -s -q -L -k -o /dev/null \
    --url "$URL_ML" \
    --header 'content-type: application/json' \
    --data "$jsn"

  {
    acc=$(ss -tpH | awk '{print $5}' | awk -F ':' '{ if ($1 ~ /^\[/) { n = NF - 1; s = $1; for (i = 2; i <= n; i++) s = s ":" $i; print s } else { print $1 } }' | sort | uniq -c )
    cnt=$(echo "$acc" | awk '{print "{ \"ip\" : \"" $2 "\", \"connections\":" $1 "}"}' | jq -s '.')
    ajs=$(echo "{\"kind\":\"frontier\",\"instance\":\"$INSTANCE\",\"site\":\"$SITE\"}" | jq | jq --argjson CNT "$cnt" '. +={ cnt: $CNT }')
  } && {
    timeout 2 curl --request POST -s -q -L -k -o /dev/null \
      --url "$URL_ML_ACCESS" \
      --header 'content-type: application/json' \
      --data "$ajs"
  } || {
    echo "Error getting access data"
  }

  sleep 2
done
SCRIPT

exec apptainer exec \
  --bind "${VARNISH_WORKDIR}:/var/lib/varnish" \
  --env SITE="$SITE" \
  --env INSTANCE="$INSTANCE" \
  --env URL_ML="$URL_ML" \
  --env URL_ML_ACCESS="$URL_ML_ACCESS" \
  "$IMAGE" \
  bash -c "$MONITOR_BODY"
