#!/bin/bash
# Re-pulls the latest v4a image and restarts the service.
# Run as root: sudo ./update.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this as root (sudo ./update.sh)." >&2
  exit 1
fi

IMAGE_PATH=/opt/v4a-apptainer/v4a.sif

apptainer pull --force "$IMAGE_PATH" docker://ivukotic/v4a:latest
systemctl restart frontier-varnish-apptainer frontier-varnish-monitor-apptainer
echo "Updated and restarted frontier-varnish-apptainer and frontier-varnish-monitor-apptainer."
