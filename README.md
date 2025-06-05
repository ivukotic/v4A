# v4A

Varnish for ATLAS

[![DockerPush](https://github.com/ivukotic/v4A/actions/workflows/DockerPush.yml/badge.svg?branch=frontier)](https://github.com/ivukotic/v4A/actions/workflows/DockerPush.yml)

Varnish is a reverse http proxy. It is meant to cache accesses to one application/server. For this purpose it is sufficient to use RAM for caching.
Even a single core and 3 GB of RAM will work well and have a very high cache hit rate, but if you can, optimal would be 4 cores and 32GB RAM.
Varnish for Frontier should be listening on port 6082.
If your Varnish will serve only local nodes, there is no need to open any ports for access from outside. If your instance will be added to the CloudFlare DNS loadbalancer, port 6082 TCP should be accessible from outside.

## Setting it up

### On a K8s cluster

This is the easiest way to set it up. Simply download [this](kube/k8s_deployment.yaml) yaml file, change the values \<SITENAME\>, \<INSTANCE\>, and \<NODE\> and do:

```bash
kubectl create ns varnish
kubectl create -f k8s_deployment.yaml
```

This deployment will autoconfigure.

### On an OpenShift cluster

Download [this](kube/open_shift_deployment.yaml) yaml file, change the values \<SITENAME\>, \<INSTANCE\> and do:

```bash
kubectl create ns varnish
kubectl create -f open_shift_deployment.yaml
```

This will create appropriate deployment and service.

### In Docker

Simply go to docker directory and edit [docker-compose file](docker/docker-compose.yaml), change the two values \<SITENAME\> and \<INSTANCE\>  and do:

```bash
docker compose start
```

### On an VM, bare metal

Any version you pick will work fine since we need only the basic functionality. Instructions on how to install it are [here](https://varnish-cache.org/docs/trunk/installation/index.html).
To start it execute these commands:

```bash
export SITE=<SITE>
export INSTANCE=<SITE>
export VARNISH_TRANSIENT_MEM=1G
export VARNISH_MEM=12G
wget https://raw.githubusercontent.com/ivukotic/v4A/refs/heads/frontier/runme.sh
source runme.sh
```

To configure monitoring on bare metal just run [monitor.sh](Monitoring/monitor.sh).

Ideally you want both of these (server and monitoring script), to be run in systemd.

## Testing Frontier access caching

If it works correctly command like this should return 200:

```bash
curl -L -o /dev/null -s -w "%{http_code}" -H "Cache-Control: max-age=0" http://<HOSTNAME>:6082/atlr
```

## CRIC settings

Varnish servers that serve Frontier should be mentioned in [CRIC](https://atlas-cric.cern.ch/).
They are a CRIC Service, so you should click here to create a new one.
<img src="Manual/CRIC_create_service.png" alt="create service" style="width:70%;margin: 10px;" />

There are only a few fields you should fill:

| **Parameter**  | **Value**        |
| -------------- | ---------------- |
| Site           | \<SITENAME\>       |
| Service Type   | Varnish            |
| Object State   | Active           |
| Endpoint       | \<ADDRESS:PORT\>   |
| Flavour        | Frontier         |

<img src="Manual/CRIC_varnish_service.png" alt="varnish service" style="width:70%;margin: 10px;" />

To add the created service to your site and change order of priority of caching services, first find your site [here](https://atlas-cric.cern.ch/core/experimentsite/list/). Looking at details you will see something like this:
<img src="Manual/CRIC_squid_configuration.png" alt="squid configuration" style="width:90%;margin: 10px;" />

Clicking "Manage configuration" will allow to add/remove a caching proxy and reoder them. Feel free to add a varnish from a nearby site as a backup with the lowest priority.

## Monitoring

This [dashboard](https://atlas-kibana.mwt2.org:5601/s/varnish/app/r/s/gol0t) gives most important data: requests rate, cached hit and miss rates, amount of data delivered and uptime.

## Instances

| **Deployed at** | **CF Pool** | **Site** | **Instance** | **Address** | **Local** |
| --------------- | ----------- | -------- | ------------ | ----------- | --------- |
| [NRP](https://github.com/maniaclab/NRP) | us-central | Starlight | Starlight-1f | <http://starlight.varnish.atlas-ml.org:6082> | No |
| NRP |            | AGLT2/UM | frontier-01 | <http://sl-um-es2.slateci.io:6082> | No |
| NRP |            | AGLT2/MSU | frontier-01 | <http://msu-nrp.aglt2.org:6082> | No |
| NRP | us-east    | NET2/mghpcc | NET2-2f | <http://gpu-13.nrp.mghpcc.org:6082>  | No |
| NRP |            | OU/oscer | ou-1f | <http://fiona.offn.oscer.ou.edu:6082> | No |
| NRP | us-west    | WT2/ucsc | ucsc-1f | <http://fiona8.ucsc.edu:6082> | No |
| [UC-AF](https://github.com/maniaclab/flux_apps) |          | MWT2 | frontier-uc-01 | <http://v4a.mwt2.org:6082> | No |
| ROMA1 |  | INFN-ROMA1 | v4f-1   | <http://cmsrm-svc-02.roma1.infn.it:6082> | No |
| ROMA1 | it | INFN-ROMA1 | v4f-2   | <http://cmsrm-svc-01.roma1.infn.it:6082> | No |
| PIC | es | PIC | frontier-01 | <http://varnish.pic.es:6082> | No |
| Manchester | uk | UKI-NORTHGRID-MAN-HEP| FRONTIER-MAN | <http://vm39.tier2.hep.manchester.ac.uk:6082> | No |
| LRZ-LMU | | LRZ-LMU | 1 | <http://lcg-lrz-ce3.grid.lrz.de:3128> |  No |
| Wuppertal | | WUPPERTALPROD | buw-frontier-1 | <http://varnish.pleiades.uni-wuppertal.de:6082> | Yes |
| CERN | | CERN | ATLAS-FRONTIER-1 | <http://atlasfrontier-varnish01.cern.ch:6082> | Yes |

## CloudFlare

We have a CloudFlare DNS loadbalancer that makes important Frontier Varnish instances reachable at <http://v4a.hl-lhc.net:6082>. Health checks in CF are trying to access "/atlr" directory once per minute.

## Stress testing

direct to origin:

curl '<http://atlasfrontier1-ai.cern.ch:8000/atlr/Frontier/type=frontier_request:1:DEFAULT&encoding=BLOBzip5&p1=eNp1k8FuwyAMhl8FcZ6mKrcddvDANEgOIPC67cT7v0VpEwpJ2A1-32-LKCQhoWLhvMZstYAk5HaWbysNENFx7yqpCQcLNvuoqjHfRAF4braSmtCYVLSBrXct1MGas4kQTLffs642qRkXyDeMaTdoz1.zXGLbr7yB4gkSL15nDbz6HhRvPGmMdaB112foRFsywB950Cmg6qMdPmXLOmQdDuKbOXfgL0c0o47VtA41g3NIx306fMoOpu9N67D.xvBF.HoRA97SDNdhuue72dN-HUd3usOw6.ikMNEvQgKXr56V9.QNZbaE8l2WY5gul-x4MEmKY-0zY8T6G32K6eMOZZPoOQ>__' -H "X-frontier-id: varnish" -X GET

through Squid:
export http_proxy=<http://uct2-slate.mwt2.org:32200>

siege:
siege -c30 --reps=once  --header='X-frontier-id:siege' -f requests_frontier_origin.txt > /dev/null &  

through Varnish:
curl -X GET <http://v4a.hl-lhc.net:6082/atlr/Frontier/type=frontier_request:1:DEFAULT&encoding=BLOBzip5&p1=eNpdj0EKAjEMRa8SshYZxa2L0Ga02GmGJiKucv9bWLEzFHfvv3wSopw5GBSJ7CkCKWBnPIDRbZM-7K7Qwrv9hu6zhIerkT11Hw.utyJrqGm1JGVvDa619K2eilrqZ4aMMFdZAMkyqQeRLHP2GBSP2Gg9T5O3hYrwF193rrz9eYXT5QOWkUJt>
