#!/bin/bash
# One-shot setup: pulls the v4a image and installs the systemd service.
# Run as root: sudo ./install.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this as root (sudo ./install.sh)." >&2
  exit 1
fi

if ! command -v apptainer >/dev/null 2>&1; then
  echo "apptainer was not found on PATH." >&2
  echo "Install it first: https://apptainer.org/docs/admin/main/installation.html" >&2
  exit 1
fi

INSTALL_DIR=/opt/v4a-apptainer
IMAGE_PATH="$INSTALL_DIR/v4a.sif"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$INSTALL_DIR" "$INSTALL_DIR/varnish-workdir"

echo "Pulling ivukotic/v4a image..."
apptainer pull --force "$IMAGE_PATH" docker://ivukotic/v4a:latest

install -m 755 "$SCRIPT_DIR/start-varnish.sh" /usr/local/bin/frontier-varnish-apptainer.sh
install -m 755 "$SCRIPT_DIR/monitor.sh" /usr/local/bin/frontier-varnish-monitor-apptainer.sh

mkdir -p /etc/sysconfig
if [ ! -f /etc/sysconfig/frontier-varnish-apptainer ]; then
  install -m 644 "$SCRIPT_DIR/frontier-varnish-apptainer.env" /etc/sysconfig/frontier-varnish-apptainer
  echo "Wrote /etc/sysconfig/frontier-varnish-apptainer - edit SITE and INSTANCE before starting."
else
  echo "/etc/sysconfig/frontier-varnish-apptainer already exists, leaving it untouched."
fi

install -m 644 "$SCRIPT_DIR/frontier-varnish-apptainer.service" /etc/systemd/system/frontier-varnish-apptainer.service
install -m 644 "$SCRIPT_DIR/frontier-varnish-monitor-apptainer.service" /etc/systemd/system/frontier-varnish-monitor-apptainer.service

systemctl daemon-reload

cat <<EOF

Install complete.

Next steps:
  1. Edit /etc/sysconfig/frontier-varnish-apptainer and set SITE and INSTANCE
     (and adjust VARNISH_MEM/VARNISH_PORT if needed).
  2. Start both the proxy and its monitoring feed - the monitoring service is
     required, not optional, since it's how this instance shows up in Kibana:
       systemctl enable --now frontier-varnish-apptainer frontier-varnish-monitor-apptainer
  3. Check they're running:
       systemctl status frontier-varnish-apptainer frontier-varnish-monitor-apptainer
       journalctl -u frontier-varnish-apptainer -u frontier-varnish-monitor-apptainer -f
EOF
