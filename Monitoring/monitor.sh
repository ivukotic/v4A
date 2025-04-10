#!/bin/sh

# check variables $INSTANCE and $SITE are defined
if [ -z "$INSTANCE" ] || [ -z "$SITE" ]; then
  echo "Error: INSTANCE and SITE variables must be set."
  exit 1
fi

# infinite loop that repeats every 5 seconds
while true; do

    data=$(varnishstat -j)

    jsn=$(echo $data | jq --arg INST "$INSTANCE" --arg SITE "$SITE" '. += { instance: $INST, site: $SITE }')

    timeout 2 curl --request POST -L -k \
    --url http://varnish.atlas-ml.org:80/ \
    --header 'content-type: application/json' \
    --data "$jsn"

    sleep 5
    
done

