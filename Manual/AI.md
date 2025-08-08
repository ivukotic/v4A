# Conditions data delivery for ATLAS experiment

To process experimental data produced by the High Energy Physics experiment ATLAS, programs need Conditions Data.
The Conditions Data are kept in Oracle database at CERN. Programs that need the access to the Conditions Data are running 24/7 at a number of geographically distributed computing centers (usually refered as "sites").

The Conditions Data is exposed via a "Frontier" - a tomcat servelet running in a kubernetes cluster in CERN's OpenStack. The Frontier is protected by a deployment of 4 Varnish reverse proxies in the same kubernetes namespace. Configuration of these proxies can be found [in the github file](https://raw.githubusercontent.com/ivukotic/v4A/refs/heads/frontier/configurations/cern_frontier_varnish.vcl).
The Varnish proxies are exposed to internet via a loadbalancer serving on: <http://v4f.cern.ch:80>.

In order to reduce bandwidth used and latency of the Condition Data accesses, we have a set of geographically distributed Varnish proxies. Each of them is uniquely identified by its "site" and "instance" combination. All of them are listed in [this json file](https://raw.githubusercontent.com/ivukotic/v4A/refs/heads/frontier/configurations/endpoints.json). Each server is described by following variables:

* url - only a hostname. by default it serves over http and unless specified differently on port 6082.
* site - ATLAS computing site where the server is.
* instance - identifier distingishing servers at the same site
* active - if true it is in an active use
* local - if true, the server is only accessible from a local network (can't be tested from outside the site)
* is_CDN - if true, server is a part of the CloudFlare DNS Loadbalancer serving on "<http://v4f.hl-lhc.net:6082>"
* responsible - Name and email of a person responsible for the server.

All the non-local varnish instances can be tested by issuing a REST GET request for path "/atlr", and with headers "X-frontier-id: test" and "Cache-Control: max-age=0".

## Monitoring

All the varnishes send most of the details usually found in varnihstat reports to an Elasticsearch index at University of Chicago. To get realtime or hystorical data from that index, you can ask the question to an agent running at ...
