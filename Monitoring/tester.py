import requests
import json
import os
from datetime import datetime

URL = "https://raw.githubusercontent.com/ivukotic/v4A/refs/heads/frontier/configurations/endpoints.json"

def load_endpoints(url: str = URL) -> list[dict]:
    """Download the endpoints file and return it as a Python list."""
    resp = requests.get(url, timeout=15)
    resp.raise_for_status()          # fail fast if the download didn’t work
    data = json.loads(resp.text)     # or: resp.json()

    if not isinstance(data, list):
        raise ValueError("Expected a top-level JSON array, got something else!")
    return data

# function that returns an elasticsearch client
# login credentials are read from the environment variables ES_USER and ES_PASSWORD
def get_es_client():
    from elasticsearch import Elasticsearch
    es_user = os.getenv("ES_USER")
    es_password = os.getenv("ES_PASSWORD")
    if not es_user or not es_password:
        raise ValueError("ES_USER and ES_PASSWORD environment variables must be set")
    es = Elasticsearch("https://atlas-kibana.mwt2.org:9200", http_auth=(es_user, es_password))
    return es

# function to test individual endpoints
def test_endpoint(endpoint) -> bool:
    try:
        response = requests.get('http://'+endpoint['url']+':6082/atlr', timeout=10)
        return response.status_code
    except requests.RequestException as e:
        print(f"Error testing endpoint {endpoint['url']}: {e}")
        return 0


if __name__ == "__main__":
    endpoints = load_endpoints()
    es = get_es_client()
    print(f"Loaded {len(endpoints)} endpoint definitions")

    # loop over endpoints and test ones that have active: true
    for endpoint in endpoints:
        if endpoint.get('active', False):
            status = test_endpoint(endpoint)
            document={
                "address": endpoint['url'],
                "status": status,
                "timestamp": datetime.utcnow(),
                "label": f"{endpoint['site']} {endpoint['instance']}\n{endpoint['responsible']['email']}"
            }
            print(document)
            es.index(index="varnish_status", document=document)
    print("All active endpoints have been tested.")
