# Running v4A (Frontier) under Apptainer

This runs the same [ivukotic/v4a](https://hub.docker.com/r/ivukotic/v4a) image used by the
[Docker](../docker/docker-compose.yaml) and [K8s](../kube/k8s_deployment.yaml) setups, but via
[Apptainer](https://apptainer.org/) instead — useful on worker nodes where there's no Docker
daemon available. No Docker changes are required; Apptainer converts the published image directly.

## Prerequisites

- Apptainer installed on the host ([install docs](https://apptainer.org/docs/admin/main/installation.html)).
- Outbound HTTPS access to Docker Hub (to pull the image) and to `raw.githubusercontent.com`
  (the running container fetches its Varnish config from there at startup).
- `ulimit -n` allowed up to 131072 for the service (handled automatically via `LimitNOFILE` in the
  systemd unit below).
- If this instance will be reachable from outside the node, open `VARNISH_PORT` (default 6082) in
  the host firewall. Apptainer shares the host network namespace, so there's no port-mapping step —
  whatever `VARNISH_PORT` is set to is the port Varnish binds directly on the host.

## Install

```bash
cd Apptainer
sudo ./install.sh
```

This pulls the image to `/opt/v4a-apptainer/v4a.sif` and installs:

- `/usr/local/bin/frontier-varnish-apptainer.sh` - the start script
- `/usr/local/bin/frontier-varnish-monitor-apptainer.sh` - the monitoring loop (posts stats to Kibana)
- `/etc/sysconfig/frontier-varnish-apptainer` - your config (only written if it doesn't already exist)
- `/etc/systemd/system/frontier-varnish-apptainer.service` - the systemd unit for the proxy
- `/etc/systemd/system/frontier-varnish-monitor-apptainer.service` - the systemd unit for monitoring

## Configure

Edit `/etc/sysconfig/frontier-varnish-apptainer` and set at minimum:

```sh
SITE=<your site name>
INSTANCE=<your instance name>
```

If your site/instance isn't yet in [configurations/configurations.json](../configurations/configurations.json),
email Ilija Vukotic <ivukotic@uchicago.edu> or open a PR - same as the other deployment methods.

Adjust `VARNISH_MEM`, `VARNISH_TRANSIENT_MEM`, and `VARNISH_PORT` if the defaults (8G / 500M / 6082)
don't fit the node. `URL_ML` / `URL_ML_ACCESS` are the Kibana ingest endpoints - leave them as-is
unless you've been told to point somewhere else.

## Start

Both units matter - the proxy and its monitoring feed:

```bash
sudo systemctl enable --now frontier-varnish-apptainer frontier-varnish-monitor-apptainer
sudo systemctl status frontier-varnish-apptainer frontier-varnish-monitor-apptainer
sudo journalctl -u frontier-varnish-apptainer -u frontier-varnish-monitor-apptainer -f
```

## Verify

```bash
curl -L -o /dev/null -s -w "%{http_code}" -H "X-frontier-id: test" -H "Cache-Control: max-age=0" http://localhost:6082/atlr
```

A `200` means it's serving correctly (swap the port if you changed `VARNISH_PORT`).

## Monitoring

`frontier-varnish-monitor-apptainer.service` runs continuously (mirroring
[VM/usr/local/bin/frontier-varnish-monitor.sh](../VM/usr/local/bin/frontier-varnish-monitor.sh)):
every 2 seconds it reads `varnishstat` from the running instance and posts request/hit/miss rates
and connection counts to the same endpoints the other deployment methods use, feeding the
[Kibana dashboard](https://atlas-kibana.mwt2.org/s/varnish/app/r/s/gol0t). This isn't optional -
without it the instance won't show up in monitoring even though it's happily serving traffic. It
runs `varnishstat`/`jq`/`ss`/`curl` from inside the image via `apptainer exec`, reading the same
VSM as the running `varnishd` through the shared `VARNISH_WORKDIR` bind mount, so nothing extra
needs to be installed on the host.

## Register in CRIC

Same as the other deployment methods - see the ["CRIC settings"](../README.md#cric-settings) section
of the main README. Apptainer doesn't change anything about how the instance is registered.

## Upgrade

```bash
cd Apptainer
sudo ./update.sh
```

Re-pulls the latest image and restarts the service.

## Uninstall

```bash
sudo systemctl disable --now frontier-varnish-apptainer frontier-varnish-monitor-apptainer
sudo rm /etc/systemd/system/frontier-varnish-apptainer.service
sudo rm /etc/systemd/system/frontier-varnish-monitor-apptainer.service
sudo rm /etc/sysconfig/frontier-varnish-apptainer
sudo rm /usr/local/bin/frontier-varnish-apptainer.sh
sudo rm /usr/local/bin/frontier-varnish-monitor-apptainer.sh
sudo rm -rf /opt/v4a-apptainer
sudo systemctl daemon-reload
```

## Troubleshooting

- **Service won't start / exits immediately**: check `journalctl -u frontier-varnish-apptainer -f`.
  Most failures are either a port already in use (`VARNISH_PORT`) or `SITE`/`INSTANCE` not set.
- **"too many open files" / connection errors under load**: confirm `LimitNOFILE=131072` is present
  in the installed unit file and that the host's own limits (`/etc/security/limits.conf`,
  `ulimit -Hn`) allow it.
- **Varnish fails to write its shared-memory log**: the unit bind-mounts
  `/opt/v4a-apptainer/varnish-workdir` onto `/var/lib/varnish` inside the container precisely to
  avoid this (the image itself is read-only under Apptainer). If you moved `VARNISH_WORKDIR` in the
  env file, make sure the directory exists and is writable by whichever user runs the service.
- **No Docker HEALTHCHECK**: the image's `Dockerfile` bakes in a `HEALTHCHECK` that runs
  `sender.sh` - that's a Docker-daemon feature and has no effect when run via Apptainer.
  `frontier-varnish-monitor-apptainer.service` (see [Monitoring](#monitoring) above) replaces both
  the health signal and the stats it sends; `Restart=on-failure` on the proxy unit covers "is the
  process still running."
- **Monitor service shows repeated "Error getting access data"**: usually means `ss` inside the
  image isn't seeing the expected connections, or `jq`/`curl` couldn't reach `URL_ML_ACCESS` - check
  outbound connectivity from the node to that endpoint.
- **Monitor service can't read varnishstat / stats never show up in Kibana**: confirm
  `frontier-varnish-apptainer.service` is actually running and that `VARNISH_WORKDIR` in the env
  file matches between both units (it's the same bind mount both rely on to reach the same VSM).
