# Stress testing

Extract urls as csv from kibana frontend. Run rewrite.py to get nice URLs.

Siege a server:

./siege -H "X-frontier-id: 123" -f urls_5000.txt --no-parser --concurrent=200 --quiet --time=5m -j
