import requests
import json
import os
from datetime import datetime, timezone
from elasticsearch import Elasticsearch, exceptions

URL = "https://raw.githubusercontent.com/ivukotic/v4A/refs/heads/cvmfs/configurations/configurations.json"

es_user = os.getenv("ES_USER")
es_password = os.getenv("ES_PASSWORD")
no_ES = False
if not es_user or not es_password:
    print("to store data ES_USER and ES_PASSWORD environment variables must be set.")
    no_ES = True

def load_endpoints(url: str = URL) -> list[dict]:
    """Download configurations.json and return flattened endpoint definitions."""
    resp = requests.get(url, timeout=15)
    resp.raise_for_status()
    data = json.loads(resp.text)

    if not isinstance(data, dict):
        raise ValueError("Expected configurations.json top-level JSON object.")

    sites = data.get("sites", [])
    if not isinstance(sites, list):
        raise ValueError("Expected 'sites' to be a JSON array.")

    root_defaults = {k: v for k, v in data.items() if k != "sites"}

    def merge(parent: dict, child: dict) -> dict:
        out = dict(parent)
        for key, value in child.items():
            if isinstance(value, dict) and isinstance(out.get(key), dict):
                nested = dict(out[key])
                nested.update(value)
                out[key] = nested
            else:
                out[key] = value
        return out

    endpoints: list[dict] = []
    for site in sites:
        if not isinstance(site, dict):
            continue

        site_cfg = merge(root_defaults, site)
        site_name = site_cfg.get("name", "UNKNOWN")
        instances = site.get("instances", [])

        if not instances:
            endpoint = dict(site_cfg)
            endpoint["site"] = site_name
            endpoint["instance"] = endpoint.get("instance", "GLOBAL")
            endpoints.append(endpoint)
            continue

        for instance in instances:
            if not isinstance(instance, dict):
                continue
            endpoint = merge(site_cfg, instance)
            endpoint["site"] = site_name
            endpoint["instance"] = endpoint.get("name", "GLOBAL")
            endpoints.append(endpoint)

    return endpoints

# function that returns an elasticsearch client
# login credentials are read from the environment variables ES_USER and ES_PASSWORD
def get_es_client():
    es = Elasticsearch("https://atlas-kibana.mwt2.org:9200", basic_auth=(es_user, es_password))
    return es


# function to test individual endpoints
def test_endpoint(endpoint) -> bool:
    try:
        full_path='http://'+endpoint['url']+':'+endpoint['port']+'/cvmfs/atlas.cern.ch/.cvmfspublished'
        # print(full_path)
        response = requests.get(full_path, timeout=10)
        return response.status_code
    except requests.RequestException as e:
        print(f"Error testing endpoint {endpoint['url']}: {e}")
        return 0


if __name__ == "__main__":
    endpoints = load_endpoints()
    if not no_ES:
        es = get_es_client()
    print(f"Loaded {len(endpoints)} endpoint definitions")

    # loop over endpoints and test ones that have active: true
    for endpoint in endpoints:
        if endpoint.get('active', False) and endpoint.get('local', False)==False:
            endpoint['port']= str(endpoint.get('port',6081))  # Ensure port is a string
            status = test_endpoint(endpoint)
            document={
                "address": endpoint['url'],
                "status": status,
                "@timestamp": datetime.now(timezone.utc),
                "label": f"{endpoint['site']} {endpoint['instance']}\n{endpoint['responsible']['email']}",
                "kind": "cvmfs"
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
