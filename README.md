# v4CVMFS

Varnish for ATLAS

[![DockerPush](https://github.com/ivukotic/v4A/actions/workflows/DockerPush.yml/badge.svg?branch=cvmfs-no-snmp)](https://github.com/ivukotic/v4A/actions/workflows/DockerPush.yml)

Varnish is a reverse http proxy. It is meant to cache accesses to one application/server. For this purpose it is sufficient to use RAM for caching.
Even a single core and 24 GB of RAM will work well and have a very high cache hit rate, but if you can, optimal would be 4 cores and 64GB RAM. Caching CVMFS accesses always benefit from more RAM.
Varnish for CVMFS should listen on port 6081.

## Setting it up

### On a K8s cluster

This is the easiest way to set it up. Simply download [this](kube/cvmfs_deployment.yaml) yaml file, change the two values \<SITENAME\>, \<INSTANCE\>, and \<NODE\> and do:

```bash
kubectl create ns varnish
kubectl create -f cvmfs_deployment.yaml
```

This will create appropriate configuration config map and deployment. The default monitoring (in Kibana at UC) will be included.

### In Docker

Go to docker directory and edit [docker-compose file](docker/docker-compose.yaml), change the two values \<SITENAME\> and \<INSTANCE\> and do:

```bash
docker compose start
```

### On an VM, bare metal

Any version you pick will work fine since we need only the basic functionality. Instructions on how to install it are [here](https://varnish-cache.org/docs/trunk/installation/index.html).
To start it you run this command

```bash
varnishd -a :6081 -f /path/to/your.vcl -s malloc,64G
```

here:

* -a :6081: This binds Varnish to listen on port 6081.
* -f /path/to/your.vcl: Specifies the VCL file (your.vcl) to use. Replace /path/to/your.vcl with the actual path to your VCL file.
* -s malloc,6G: Configures the cache storage to use memory (malloc) and allocates 6GB of RAM for caching.

## Configuring it for CVMFS traffic caching

This is a [configuration](default.vcl) that you will need. It defines 4 backends (Fermilab, two at BNL, and CERN).If the repo can't be found at the first backend, it will try the next one. If none of them have the file, request will fail. This configuration is optimal for MWT2 and AGLT2, sites on US East coast would probably want to swap order of Fermilab and BNL. Sites in Europe will probably want order: CERN, BNL, Fermilab).

to test it do:

```sh
setupATLAS
asetup 20.20.6.3,here
export FRONTIER_SERVER=(serverurl=http://v4a.atlas-ml.org:6081/atlr)
db-fnget
```

To test origin do:

```bash
curl -XGET "http://cvmfs-s1goc.opensciencegrid.org:8000/cvmfs/oasis.opensciencegrid.org/.cvmfspublished"
```

through Squid:

```bash
export http_proxy=http://uct2-slate.mwt2.org:32200
```

To test through varnish do:

```bash
curl -XGET "http://v4cvmfs.mwt2.org:6081/cvmfs/oasis.opensciencegrid.org/.cvmfspublished"
curl -XGET "http://v4cvmfs.mwt2.org:6081/cvmfs/atlas-nightlies.cern.ch/.cvmfspublished"
```

## Monitoring

This [dashboard](https://atlas-kibana.mwt2.org:5601/s/varnish/app/r/s/gol0t) gives most important data: requests rate, cached hit and miss rates, amount of data delivered and uptime.

## Instances

### NRP

configurations are in <https://github.com/maniaclab/NRP>.

| **Kind** | **Instance** | **Address** | **Node selector** |
| --------- | --- | --------------- | ------------- |
|   CVMFS | Starlight-1 | <http://starlight.varnish.atlas-ml.org:6081> | dtn108.sl.startap.net |
|   CVMFS | aglt2-1 | <http://sl-um-es3.slateci.io:6081> | sl-um-es3.slateci.io |
|   CVMFS | msu-1 | <http://msu-nrp.aglt2.org:6081> | msu-nrp.aglt2.org |
|   CVMFS | net2-1 | <http://storage-01.nrp.mghpcc.org:6081> | storage-01.nrp.mghpcc.org |

### UC AF

configurations are in <https://github.com/maniaclab/flux_apps>.

| **Instance** | **Address** | **Host** | **Node Label** |
| ------------ | --------------- | ---- | ------ |
|  cvmfs-uc          | <http://v4cvmfs.mwt2.org:6081> | c034.af.uchicago.edu | cvmfs-slate |

## CloudFlare

We have a CloudFlare DNS loadbalancer.
All CVMFS Varnish instances are reachable at <http://varnish.hl-lhc.net:6081>.
Health is checked by trying to access: /cvmfs/atlas.cern.ch/.cvmfspublished
