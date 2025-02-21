# v4A

Varnish for ATLAS

[![DockerPush](https://github.com/ivukotic/v4A/actions/workflows/DockerPush.yml/badge.svg?branch=main)](https://github.com/ivukotic/v4A/actions/workflows/DockerPush.yml)

Varnish is a reverse http proxy. It is meant to cache accesses to one application/server. For this purpose it is sufficient to use RAM for caching.
Even a single core and 3 GB of RAM will work well and have a very high cache hit rate, but if you can, optimal would be 4 cores and 32GB RAM. Caching CVMFS accesses will benefit from even more RAM.

## Setting it up

### On a K8s cluster

This is the easiest way to set it up. Simply download [this](kube/full_deployment.yaml) yaml file, change the two values \<SITENAME\> and \<NODE\> and do:

```
kubectl create ns varnish
kubectl create -f full_deployment.yaml
```

## Configuring it for Frontier access caching

This is a [configuration](default.vcl) that you will need. It is very simple and it just loads cache misses from the two ATLAS Frontier servers.

## Configuring it for CVMFS traffic caching

to test it do:

```sh
setupATLAS
asetup 20.20.6.3,here
export FRONTIER_SERVER=(serverurl=http://v4a.atlas-ml.org:6081/atlr)
db-fnget
```
