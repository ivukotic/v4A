# v4CVMFS

Varnish for CVMFS

[![DockerPush](https://github.com/ivukotic/v4A/actions/workflows/DockerPush.yml/badge.svg?branch=cvmfs)](https://github.com/ivukotic/v4A/actions/workflows/DockerPush.yml)

Varnish is a reverse http proxy. It is meant to cache accesses to one application/server. For this purpose it is sufficient to use RAM for caching.
Even a single core and 24 GB of RAM will work well and have a very high cache hit rate, but if you can, optimal would be 4 cores and 64GB RAM. Caching CVMFS accesses always benefit from more RAM. Make sure ulimit -n on the node is set to at least 100000.
Varnish for CVMFS should listen on port 6081.
If your Varnish will serve only local nodes, there is no need to open any ports for access from outside. If your instance will be added to the CloudFlare DNS loadbalancer, port 6081 TCP should be accessible from outside.

## Setting it up

### On a K8s cluster

This is the easiest way to set it up. Simply download [this](kube/cvmfs_deployment.yaml) yaml file, change the three values \<SITENAME\>, \<INSTANCE\>, and \<NODE\> and do:

```bash
kubectl create ns varnish
kubectl create -f cvmfs_deployment.yaml
```

The default monitoring (in Kibana at UC) will be included.

### In Docker

Go to docker directory and edit [docker-compose file](docker/docker-compose.yaml), change the two values \<SITENAME\> and \<INSTANCE\> and do:

```bash
docker compose start
```

### With Apptainer

For nodes without a Docker daemon (e.g. grid/HTC worker nodes), the same image can be run via
[Apptainer](https://apptainer.org/). See [Apptainer/README.md](Apptainer/README.md) for a
step-by-step setup (`install.sh`, a systemd unit, and an editable env file).

### On an VM, bare metal

Preferred version is 8.0. Instructions on how to install it are [here](https://vinyl-cache.org/releases/index.html).
To start it execute these commands:

```bash
export SITE=<SITE>
export INSTANCE=<SITE>
export VARNISH_TRANSIENT_MEM=1G
export VARNISH_MEM=32G
wget https://raw.githubusercontent.com/ivukotic/v4A/refs/heads/cvmfs/runme.sh
source runme.sh
```

To configure monitoring on bare metal just run [monitor.sh](Monitoring/monitor.sh).

Ideally you want both of these (server and monitoring script), to be run in systemd. If you want that everything you need is in [VM directory](VM). The only things you want to change are [here](VM/etc/sysconfig/cvmfs-varnish).

## Configuring it for CVMFS traffic caching

At startup, [runme.sh](runme.sh) script will load appropriate configuration as defined in a [configurations file](configurations/configurations.json). If your site is in Europe or need a special configuration, let Ilija Vukotic <mailto:ivukotic@uchicago.edu> know your \<SITENAME\> and \<INSTANCE\> and he can do it for you. Alternatively, create a PR and he'll review/accept it.

To test origin do:

```bash
curl -XGET "http://cvmfs-s1goc.opensciencegrid.org:8000/cvmfs/oasis.opensciencegrid.org/.cvmfspublished"
```

To test varnish do:

```bash
curl -XGET "http://v4cvmfs.mwt2.org:6081/cvmfs/oasis.opensciencegrid.org/.cvmfspublished"
curl -XGET "http://v4cvmfs.mwt2.org:6081/cvmfs/atlas-nightlies.cern.ch/.cvmfspublished"
```

To configure your site to use it set this in all .local files

```sh
CVMFS_HTTP_PROXY='DIRECT'
CVMFS_SERVER_URL='http://v4cvmfs.atlas-ml.org:6081/cvmfs/@fqrn@'
```

## Monitoring

This [dashboard](https://atlas-kibana.mwt2.org:5601/s/varnish/app/r/s/gol0t) gives most important data: requests rate, cached hit and miss rates, amount of data delivered and uptime.

## Instances

### NRP

| **Deployed at** | **CF Pool** | **Site** | **Instance** | **Address** |
| --------------- | ----------- | -------- | ------------ | ----------- |
| [NRP](https://github.com/maniaclab/NRP) | us-central | Starlight | Starlight-1 | <http://starlight.varnish.atlas-ml.org:6081> |
| [UC-AF](https://github.com/maniaclab/flux_apps) | us-central | MWT2 | cvmfs-uc | <http://v4cvmfs.mwt2.org:6081> |
| NRP | us-east-aglt2 | AGLT2/UM | cvmfs-02 | <http://sl-um-esw.slateci.io:6081> |
| NRP | us-east-aglt2 | MSU | msu-cvmfs | <http://msu-nrp.aglt2.org:6081> |
| NRP | us-east | NET2 | frontier-uc-01 | <http://gpu-13.nrp.mghpcc.org:6081> |

## CloudFlare

We have a CloudFlare DNS loadbalancer.
All CVMFS Varnish instances are reachable at <http://varnish.hl-lhc.net:6081>.
Health is checked by trying to access: /cvmfs/atlas.cern.ch/.cvmfspublished
