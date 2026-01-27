# Stress testing

Extract urls as csv from kibana frontend. Run rewrite.py to get nice URLs.

Siege a server:

* warm it up slowly so not to stress frontier
./siege -H "X-frontier-id: 123" -f urls_10k.txt --no-parser --concurrent=10 --quiet --time=5m -j
* run for real
./siege -H "X-frontier-id: 123" -f urls_5000.txt --no-parser --concurrent=200 --quiet --time=30m -j
