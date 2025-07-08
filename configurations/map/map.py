
# pip install requests folium

import requests
import socket
import folium
from urllib.parse import urlparse
import time

# Load endpoint data
url = "https://raw.githubusercontent.com/ivukotic/v4A/refs/heads/frontier/configurations/endpoints.json"
response = requests.get(url)
endpoints = response.json()

# Grouping buckets
groups = {
    'in_CDN': [],
    'local': [],
    'standard': []
}

# Extract IPs and group
ip_lookup = []
ip_to_entry = {}

for e in endpoints:
    group_key = 'standard'
    if e.get('in_CDN'):
        group_key = 'in_CDN'
    elif e.get('local'):
        group_key = 'local'

    try:
        host = e['url']
        ip = socket.gethostbyname(host)
        e['ip'] = ip
        ip_lookup.append(ip)
        ip_to_entry[ip] = (e, group_key)
    except Exception as err:
        print(f"DNS error for {e['url']}: {err}")

# Batch GeoIP lookup (ip-api allows 100 per batch)
geo_url = "http://ip-api.com/batch"
geo_results = []

for i in range(0, len(ip_lookup), 100):
    chunk = ip_lookup[i:i+100]
    try:
        r = requests.post(geo_url, json=[{"query": ip} for ip in chunk])
        geo_results.extend(r.json())
        time.sleep(1)  # avoid rate limit
    except Exception as err:
        print(f"GeoIP batch failed: {err}")

# Map results back
for result in geo_results:
    ip = result.get('query')
    if result.get('status') == 'success':
        e, group = ip_to_entry[ip]
        e['lat'] = result['lat']
        e['lon'] = result['lon']
        e['city'] = result.get('city', '')
        e['country'] = result.get('country', '')
        groups[group].append(e)

# Build the map
m = folium.Map(location=[20, 0], zoom_start=2)
colors = {
    'in_CDN': 'red',
    'local': 'green',
    'standard': 'blue'
}

for group_name, entries in groups.items():
    for e in entries:
        folium.Marker(
            location=[e['lat'], e['lon']],
            popup=f"{e['url']}<BR>{group_name.upper()}<BR>{e.get('city')}, {e.get('country')}",
            icon=folium.Icon(color=colors[group_name])
        ).add_to(m)

m.save("endpoint_map.html")
print("✅ Map saved to endpoint_map.html")
