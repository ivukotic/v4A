#!/bin/sh

data=$(varnishstat -j -X "VBE.boot.*.happy" -X "WAITER*" -X "LCK*" -X "MEM*" -X "SMA*" -X "MGT*")
# the following line will simplify output but requires change in the logstash collector
# fdata=$(echo $data | jq '.counters |= with_entries(.value = .value["value"])')
fdata=$(echo $data | jq 'del(.counters[].description, .counters[].flag, .counters[].format)')
jsn=$(echo $fdata | jq --arg INST "$INSTANCE" --arg SITE "$SITE" '. += { kind: "frontier", instance: $INST, site: $SITE }')

timeout 2 curl --request POST -L -k \
  --url 'http://varnish.atlas-ml.org:80/' \
  --header 'content-type: application/json' \
  --data "$jsn"

acc=$(ss -tpr | grep -v Address | awk '{print $5}' | awk -F: '{print $1}' | cut -f2- -d'.' | sort | uniq -c )
cnt=$(echo "$acc" | awk '{print "{ \"client\" : \"" $2 "\", \"connections\":" $1 "}"}' | jq -s '.')
ajs=$(echo "{\"kind\":\"frontier\",\"instance\":\"$INSTANCE\",\"site\":\"$SITE\"}" | jq | jq --argjson CNT "$cnt" '. +={ cnt: $CNT }')

timeout 2 curl --request POST -L -k \
  --url 'http://varnish.atlas-ml.org:80/' \
  --header 'content-type: application/json' \
  --data "$ajs"
exit 0