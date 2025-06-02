#!/usr/bin/env bash
#
# Reads endpoints.txt (one URL per line), curls each URL once,
# and writes a JSON object mapping URL → HTTP status code.

set -euo pipefail

INPUT="configurations/endpoints.txt"   # text file with URLs, one per line
OUTPUT="results.json"   # where to save the JSON (or change to /dev/stdout)

# Loop over every non-empty, non-comment line
while IFS= read -r url || [[ -n $url ]]; do
  [[ -z "$url" || "$url" =~ ^# ]] && continue   # skip blanks / comments

  # Quiet curl: suppress body, just capture status (000 if network fails)
  status=$(curl -L -s -o /dev/null -w '%{http_code}' "$url" || echo "000")

#   # Merge into running JSON map
#   result=$(jq --arg u "$url" --arg s "$status" '.[$u] = ($s | tonumber)' \
#               <<<"$result")
done < "$INPUT"

# Emit the final JSON
# echo "$result" > "$OUTPUT"
# echo "Checked $(jq length <<<"$result") URLs → wrote $OUTPUT"
