
# pip install requests folium

import json
import os
import socket
import folium
import requests
import time

# Load configuration data
config_path = os.path.join(
    os.path.dirname(__file__), '..', 'configurations.json'
)
with open(config_path) as f:
    config = json.load(f)

sites = config.get("sites", [])

# Grouping buckets
groups = {
    'in_CDN': [],
    'local': [],
    'standard': []
}

# Extract IPs and group (skip inactive sites)
ip_lookup = []
ip_to_entry = {}

for site in sites:
    if not site.get('active', True):
        continue

    group_key = 'standard'
    if site.get('in_CDN'):
        group_key = 'in_CDN'
    elif site.get('local'):
        group_key = 'local'

    try:
        host = site['url']
        ip = socket.gethostbyname(host)
        site['ip'] = ip
        ip_lookup.append(ip)
        ip_to_entry[ip] = (site, group_key)
    except Exception as err:
        print(f"DNS error for {site['url']}: {err}")

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
        site, group = ip_to_entry[ip]
        site['lat'] = result['lat']
        site['lon'] = result['lon']
        site['city'] = result.get('city', '')
        site['country'] = result.get('country', '')
        groups[group].append(site)

# Build the map
m = folium.Map(location=[20, 0], zoom_start=2)

labels = {
    'in_CDN': 'IN CDN',
    'local': 'LOCAL',
    'standard': 'STANDARD',
}

for group_name, entries in groups.items():
    for site in entries:
        popup = folium.Popup(
            f"<b>{site['name']}</b><br>{site['url']}<br>"
            f"{labels[group_name]}<br>"
            f"{site.get('city')}, {site.get('country')}",
            max_width=300
        )
        if group_name == 'in_CDN':
            folium.Marker(
                location=[site['lat'], site['lon']],
                popup=popup,
                tooltip=site['name'],
                icon=folium.DivIcon(
                    html='<div style="font-size:18px; color:darkorange; '
                         'text-shadow: 0 0 3px #000; line-height:1;">★</div>',
                    icon_size=(20, 20),
                    icon_anchor=(10, 10)
                )
            ).add_to(m)
        elif group_name == 'standard':
            folium.CircleMarker(
                location=[site['lat'], site['lon']],
                radius=5,
                color='steelblue',
                fill=True,
                fill_color='steelblue',
                fill_opacity=0.75,
                popup=popup,
                tooltip=site['name']
            ).add_to(m)
        else:  # local
            folium.CircleMarker(
                location=[site['lat'], site['lon']],
                radius=5,
                color='green',
                fill=True,
                fill_color='green',
                fill_opacity=0.65,
                popup=popup,
                tooltip=site['name']
            ).add_to(m)

# Add legend
legend_html = """
<div style="position: fixed; bottom: 30px; left: 30px; z-index: 1000;
     background-color: white; border: 2px solid grey; border-radius: 5px;
     padding: 10px; font-size: 14px; line-height: 1.8;">
  <b>Legend</b><br>
  <span style="color: darkorange; font-size: 16px; margin-right: 6px;
    text-shadow: 0 0 2px #000;">★</span>In CDN<br>
  <i class="fa fa-circle" style="color: steelblue; font-size: 12px;
    margin-right: 6px;"></i>Standard<br>
  <i class="fa fa-circle" style="color: green; font-size: 8px;
    margin-right: 6px;"></i>Local
</div>
"""
m.get_root().html.add_child(folium.Element(legend_html))

m.save("endpoint_map.html")
print("Map saved to endpoint_map.html")
