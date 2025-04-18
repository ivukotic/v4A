#!/bin/sh


data=$(varnishstat -j -X "VBE*" -X "WAITER*" -X "LCK*" -X "MEM*" -X "SMA*" -X "MGT*")
# the following line will simplify output but requires change in the logstash collector
# fdata=$(echo $data | jq '.counters |= with_entries(.value = .value["value"])')
fdata=$(echo $data | jq 'del(.counters[].description, .counters[].flag, .counters[].format)')
jsn=$(echo $fdata | jq --arg INST "$INSTANCE" --arg SITE "$SITE" '. += { instance: $INST, site: $SITE }')

timeout 2 curl --request POST -L -k \
  --url 'http://varnish.atlas-ml.org:80/' \
  --header 'content-type: application/json' \
  --data "$jsn"

exit 0