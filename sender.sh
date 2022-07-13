#!/bin/sh

data=$(varnishstat -j)

jsn=$(echo $data | jq --arg INST "$INSTANCE" '. += { instance: $INST }')

curl --request POST -L -k \
  --url http://varnish.atlas-ml.org:80/ \
  --header 'content-type: application/json' \
  --data "$jsn"

echo "ok"