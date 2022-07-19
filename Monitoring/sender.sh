#!/bin/sh

data=$(varnishstat -j)

jsn=$(echo $data | jq --arg INST "$INSTANCE" --arg SITE "$SITE" '. += { instance: $INST, site: $SITE }')

curl --request POST -L -k 
  --max-time 2 \
  --url http://varnish.atlas-ml.org:80/ \
  --header 'content-type: application/json' \
  --data "$jsn"

echo "ok"