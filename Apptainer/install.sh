#!/bin/bash
# One-shot setup: pulls the v4cvmfs image and installs the systemd service.
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

INSTALL_DIR=/opt/v4cvmfs-apptainer
IMAGE_PATH="$INSTALL_DIR/v4cvmfs.sif"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$INSTALL_DIR" "$INSTALL_DIR/varnish-workdir"

echo "Pulling ivukotic/v4cvmfs image..."
apptainer pull --force "$IMAGE_PATH" docker://ivukotic/v4cvmfs:latest

install -m 755 "$SCRIPT_DIR/start-varnish.sh" /usr/local/bin/cvmfs-varnish-apptainer.sh

mkdir -p /etc/sysconfig
if [ ! -f /etc/sysconfig/cvmfs-varnish-apptainer ]; then
  install -m 644 "$SCRIPT_DIR/cvmfs-varnish-apptainer.env" /etc/sysconfig/cvmfs-varnish-apptainer
  echo "Wrote /etc/sysconfig/cvmfs-varnish-apptainer - edit SITE and INSTANCE before starting."
else
  echo "/etc/sysconfig/cvmfs-varnish-apptainer already exists, leaving it untouched."
fi

install -m 644 "$SCRIPT_DIR/cvmfs-varnish-apptainer.service" /etc/systemd/system/cvmfs-varnish-apptainer.service

systemctl daemon-reload

cat <<EOF

Install complete.

Next steps:
  1. Edit /etc/sysconfig/cvmfs-varnish-apptainer and set SITE and INSTANCE
     (and adjust VARNISH_MEM/VARNISH_PORT if needed).
  2. Start it:
       systemctl enable --now cvmfs-varnish-apptainer
  3. Check it's running:
       systemctl status cvmfs-varnish-apptainer
       journalctl -u cvmfs-varnish-apptainer -f
EOF
