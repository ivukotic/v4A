import requests
import json

URL = "https://raw.githubusercontent.com/ivukotic/v4A/refs/heads/frontier/configurations/endpoints.json"

def load_endpoints(url: str = URL) -> list[dict]:
    """Download the endpoints file and return it as a Python list."""
    resp = requests.get(url, timeout=15)
    resp.raise_for_status()          # fail fast if the download didn’t work
    data = json.loads(resp.text)     # or: resp.json()

    if not isinstance(data, list):
        raise ValueError("Expected a top-level JSON array, got something else!")
    return data

if __name__ == "__main__":
    endpoints = load_endpoints()
    print(f"Loaded {len(endpoints)} endpoint definitions")
    
