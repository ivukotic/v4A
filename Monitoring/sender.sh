#!/bin/sh
ver="v2025-11-20"
data=$(varnishstat -j -X "VBE.*.happy" -X "WAITER*" -X "LCK*" -X "MEM*" -X "SMA.*c_*" -X "MGT*")
fdata=$(echo "$data" | jq '.counters |= with_entries(.value = .value["value"])')
fdatb=$(echo "$fdata" | jq '.counters as $c | del(.counters) + $c')
jsn=$(echo "$fdatb" | jq --arg INST "$INSTANCE" --arg SITE "$SITE" --arg VER "$ver" '. += { kind: "frontier", instance: $INST, site: $SITE, ver: $VER }')

timeout 2 curl --request POST -s -q -L -k \
  --url 'http://varnish.atlas-ml.org:80/' \
  --header 'content-type: application/json' \
  --data "$jsn"

acc=$(ss -tpH | awk '{print $5}' | awk -F ':' '{ if ($1 ~ /^\[/) { n = NF - 1;  s = $1; for (i = 2; i <= n; i++) s = s ":" $i; print s } else { print $1 } }' | sort | uniq -c )
cnt=$(echo "$acc" | awk '{print "{ \"ip\" : \"" $2 "\", \"connections\":" $1 "}"}' | jq -s '.')
ajs=$(echo "{\"kind\":\"frontier\",\"instance\":\"$INSTANCE\",\"site\":\"$SITE\"}" | jq | jq --argjson CNT "$cnt" '. +={ cnt: $CNT }')

timeout 2 curl --request POST -s -q -L -k \
  --url 'http://varnish-accesses.atlas-ml.org:80/' \
  --header 'content-type: application/json' \
  --data "$ajs"
exit 0