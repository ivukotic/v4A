#!/bin/bash

# Check that SERVER env variable is set
if [ -z "$SERVER" ]; then
    echo "ERROR: The environment variable SERVER is not set."
    exit 1
fi

# Check that urls.txt exists
if [ ! -f urls.txt ]; then
    echo "ERROR: urls.txt not found."
    exit 1
fi

# Process first 10k lines, replace SERVER, and write output
head -n 10000 urls.txt | sed "s/SERVER/$SERVER/g" > urls_10k.txt

echo "Prepared urls_10k.txt with SERVER=$SERVER"

./siege -H "X-frontier-id: 123" -f urls_10k.txt --no-parser --concurrent=100 --quiet -b --time=30m -j

echo "Siege test completed."