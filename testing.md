# Frontier

test origin:

```bash
curl 'http://atlasfrontier1-ai.cern.ch:8000/atlr/Frontier/type=frontier_request:1:DEFAULT&encoding=BLOBzip5&p1=eNp1k8FuwyAMhl8FcZ6mKrcddvDANEgOIPC67cT7v0VpEwpJ2A1-32-LKCQhoWLhvMZstYAk5HaWbysNENFx7yqpCQcLNvuoqjHfRAF4braSmtCYVLSBrXct1MGas4kQTLffs642qRkXyDeMaTdoz1.zXGLbr7yB4gkSL15nDbz6HhRvPGmMdaB112foRFsywB950Cmg6qMdPmXLOmQdDuKbOXfgL0c0o47VtA41g3NIx306fMoOpu9N67D.xvBF.HoRA97SDNdhuue72dN-HUd3usOw6.ikMNEvQgKXr56V9.QNZbaE8l2WY5gul-x4MEmKY-0zY8T6G32K6eMOZZPoOQ__' -H "X-frontier-id: varnish" -X GET
```

through Squid:

```bash
export http_proxy=http://uct2-slate.mwt2.org:32200
```

through Varnish:

```bash
curl -X GET http://v4a.mwt2.org:6081/atlr/Frontier/type=frontier_request:1:DEFAULT&encoding=BLOBzip5&p1=eNpdj0EKAjEMRa8SshYZxa2L0Ga02GmGJiKucv9bWLEzFHfvv3wSopw5GBSJ7CkCKWBnPIDRbZM-7K7Qwrv9hu6zhIerkT11Hw.utyJrqGm1JGVvDa619K2eilrqZ4aMMFdZAMkyqQeRLHP2GBSP2Gg9T5O3hYrwF193rrz9eYXT5QOWkUJt
```

Stress test using siege:

```bash
siege -c30 --reps=once  --header='X-frontier-id:siege' -f requests_frontier_origin.txt > /dev/null &  
```

# CVMFS

To test origin do:

```bash
curl -XGET "http://cvmfs-s1goc.opensciencegrid.org:8000/cvmfs/oasis.opensciencegrid.org/.cvmfspublished"
```

To test through varnish from uct2-int do:

```bash
curl -XGET "http://v4cvmfs.mwt2.org:6081/cvmfs/oasis.opensciencegrid.org/.cvmfspublished"
curl -XGET "http://v4cvmfs.mwt2.org:6081/cvmfs/atlas-nightlies.cern.ch/.cvmfspublished"
```
