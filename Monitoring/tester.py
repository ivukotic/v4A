import requests
import json
import os
from datetime import datetime, timezone
from elasticsearch import Elasticsearch, exceptions

URL = "https://raw.githubusercontent.com/ivukotic/v4A/refs/heads/frontier/configurations/configurations.json"

es_user = os.getenv("ES_USER")
es_password = os.getenv("ES_PASSWORD")
no_ES = False
if not es_user or not es_password:
    print("to store data ES_USER and ES_PASSWORD environment variables must be set.")
    no_ES = True

def add_missing_defaults(parent, child):
    for key in ['port', 'type', 'file', 'active', 'local', 'in_CDN', 'responsible']:
        if key not in child:
            child[key] = parent.get(key)

def denormalize_configurations(d):
    for site in d.get('sites', []):
        add_missing_defaults(d, site)
        for instance in site.get('instances', []):
            add_missing_defaults(site, instance)
    return d

def load_configurations():
    resp = requests.get(URL, timeout=15)
    resp.raise_for_status()          # fail fast if the download didn’t work
    data = json.loads(resp.text)     # or: resp.json()
    if not isinstance(data, object):
        raise ValueError("Expected a top-level JSON object, got something else!")
    return denormalize_configurations(data)

# function that returns an elasticsearch client
# login credentials are read from the environment variables ES_USER and ES_PASSWORD
def get_es_client():
    es = Elasticsearch("https://atlas-kibana.mwt2.org:9200", basic_auth=(es_user, es_password))
    return es

headers = {
    "X-frontier-id": "varnish-tester",
    "Cache-Control": "max-age=0"
}

# function to test individual endpoints
def test_endpoint(site) -> bool:
    try:
        response = requests.get(f'http://{site["url"]}:{site["port"]}/atlr', timeout=10, headers=headers)
        return response.status_code
    except requests.RequestException as e:
        print(f"Error testing endpoint {site['url']}: {e}")
        return 0


if __name__ == "__main__":
    cs = load_configurations()
    
    if not no_ES:
        es = get_es_client()
    print(f"Loaded {len(cs['sites'])} endpoint definitions")

    # loop over endpoints and test ones that have active: true
    for site in cs['sites']:
        # print(site)
        if site['type'] != 'frontier':
            print(f"Skipping non-Frontier site {site.get('name')}")
            continue
        if site['active'] and not site['local']:
            status = test_endpoint(site)
            document={
                "address": site['url'],
                "status": status,
                "@timestamp": datetime.now(timezone.utc),
                "label": f"{site['name']} {site['url']}\n{site['responsible']['email']}",
                "kind": "conditions"
            }
            print(document)
            
            try:
                if no_ES:
                    continue
                response = es.index(index="varnish_status", document=document)
                # print("Indexing successful:", response)
            except exceptions.ConnectionError as e:
                print("Connection error:", e)
            except exceptions.RequestError as e:
                print("Request error:", e)
            except exceptions.SerializationError as e:
                print("Serialization error:", e)
            except exceptions.ElasticsearchException as e:
                print("General Elasticsearch error:", e)

    print("All active endpoints have been tested.")
