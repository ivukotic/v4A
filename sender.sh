#!/bin/sh

data=$(varnishstat -j)

curl --request POST -L -k \
  --url http://varnish.atlas-ml.org:80/ \
  --header 'content-type: application/json' \
  --data "$data"
