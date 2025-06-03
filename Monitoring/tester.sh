#!/usr/bin/env bash
#
# Reads endpoints.txt (one URL per line), curls each URL once,
# and writes a JSON object mapping URL → HTTP status code.

INPUT="configurations/endpoints.txt"   # text file with URLs, one per line

# Loop over every non-empty, non-comment line
while IFS= read -r url || [[ -n $url ]]; do
    [[ -z "$url" || "$url" =~ ^# ]] && continue   # skip blanks / comments
    echo "Testing $url "
    # Quiet curl: suppress body, just capture status (0 if network fails)
    status=$(timeout 2 curl -L -s -o /dev/null -w '%{http_code}' "http://$url:6082/atlr") || status=0

    result_string="{\"address\":\"${url}\", \"status\": ${status}}"
    echo "Result: $result_string "

    curl -s -X POST \
        -H "Content-Type: text/plain" \
        --data-binary "$result_string" \
        "https://varnish-tests.atlas-ml.org"
    
    echo ""

done < "$INPUT"




echo "Sent results to https://varnish-tests.atlas-ml.org"