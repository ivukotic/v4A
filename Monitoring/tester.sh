#!/usr/bin/env bash
#
# Reads endpoints.txt (one URL per line), curls each URL once,
# and writes a JSON object mapping URL → HTTP status code.

set -euo pipefail

INPUT="configurations/endpoints.txt"   # text file with URLs, one per line


result_string="{"

# Loop over every non-empty, non-comment line
while IFS= read -r url || [[ -n $url ]]; do
  [[ -z "$url" || "$url" =~ ^# ]] && continue   # skip blanks / comments

  # Quiet curl: suppress body, just capture status (000 if network fails)
  status=$(curl -L -s -o /dev/null -w '%{http_code}' "$url" || echo "000")

result_string+="\"${url}\": \"${status}\","

done < "$INPUT"

# Remove trailing comma and close JSON object
result_string="${result_string%,}}"

curl -s -X POST \
     -H "Content-Type: text/plain" \
     --data-binary "$result_string" \
     "http://v4a-testing.atlas-ml.org:5957"