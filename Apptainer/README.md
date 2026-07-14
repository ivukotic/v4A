# Running v4CVMFS under Apptainer

This runs the same [ivukotic/v4cvmfs](https://hub.docker.com/r/ivukotic/v4cvmfs) image used by the
[Docker](../docker/docker-compose.yaml) and [K8s](../kube/cvmfs_deployment.yaml) setups, but via
[Apptainer](https://apptainer.org/) instead — useful on worker nodes where there's no
Docker daemon available. No Docker changes are required; Apptainer converts the published image
directly.

## Prerequisites

- Apptainer installed on the host ([install docs](https://apptainer.org/docs/admin/main/installation.html)).
- Outbound HTTPS access to Docker Hub (to pull the image) and to `raw.githubusercontent.com`
  (the running container fetches its Varnish config from there at startup).
- `ulimit -n` allowed up to 131072 for the service (handled automatically via `LimitNOFILE` in the
  systemd unit below).
- If this instance will be reachable from outside the node, open `VARNISH_PORT` (default 6081) in
  the host firewall. Apptainer shares the host network namespace, so there's no port-mapping step —
  whatever `VARNISH_PORT` is set to is the port Varnish binds directly on the host.

## Install

```bash
cd Apptainer
sudo ./install.sh
```

This pulls the image to `/opt/v4cvmfs-apptainer/v4cvmfs.sif` and installs:

- `/usr/local/bin/cvmfs-varnish-apptainer.sh` - the start script
- `/etc/sysconfig/cvmfs-varnish-apptainer` - your config (only written if it doesn't already exist)
- `/etc/systemd/system/cvmfs-varnish-apptainer.service` - the systemd unit

## Configure

Edit `/etc/sysconfig/cvmfs-varnish-apptainer` and set at minimum:

```sh
SITE=<your site name>
INSTANCE=<your instance name>
```

If your site/instance isn't yet in [configurations/configurations.json](../configurations/configurations.json),
email Ilija Vukotic <ivukotic@uchicago.edu> or open a PR - same as the other deployment methods.

Adjust `VARNISH_MEM`, `VARNISH_TRANSIENT_MEM`, and `VARNISH_PORT` if the defaults (32G / 1G / 6081)
don't fit the node.

## Start

```bash
sudo systemctl enable --now cvmfs-varnish-apptainer
sudo systemctl status cvmfs-varnish-apptainer
sudo journalctl -u cvmfs-varnish-apptainer -f
```

## Verify

```bash
curl -XGET "http://localhost:6081/cvmfs/oasis.opensciencegrid.org/.cvmfspublished"
```

(swap the port if you changed `VARNISH_PORT`)

## Upgrade

```bash
cd Apptainer
sudo ./update.sh
```

Re-pulls the latest image and restarts the service.

## Uninstall

```bash
sudo systemctl disable --now cvmfs-varnish-apptainer
sudo rm /etc/systemd/system/cvmfs-varnish-apptainer.service
sudo rm /etc/sysconfig/cvmfs-varnish-apptainer
sudo rm /usr/local/bin/cvmfs-varnish-apptainer.sh
sudo rm -rf /opt/v4cvmfs-apptainer
sudo systemctl daemon-reload
```

## Troubleshooting

- **Service won't start / exits immediately**: check `journalctl -u cvmfs-varnish-apptainer -f`.
  Most failures are either a port already in use (`VARNISH_PORT`) or `SITE`/`INSTANCE` not set.
- **"too many open files" / connection errors under load**: confirm `LimitNOFILE=131072` is present
  in the installed unit file and that the host's own limits (`/etc/security/limits.conf`,
  `ulimit -Hn`) allow it.
- **Varnish fails to write its shared-memory log**: the unit bind-mounts
  `/opt/v4cvmfs-apptainer/varnish-workdir` onto `/var/lib/varnish` inside the container precisely
  to avoid this (the image itself is read-only under Apptainer). If you moved `VARNISH_WORKDIR` in
  the env file, make sure the directory exists and is writable by whichever user runs the service.
- **Monitoring**: the bare-metal setup in [../VM](../VM) sends stats to Kibana via `varnishstat`.
  That isn't wired up here yet; if you need it, `varnishstat` can be run against the same
  `VARNISH_WORKDIR` bind mount from another `apptainer exec` invocation of the same image.
