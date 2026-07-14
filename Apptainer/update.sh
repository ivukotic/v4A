#!/bin/bash
# Re-pulls the latest v4cvmfs image and restarts the service.
# Run as root: sudo ./update.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this as root (sudo ./update.sh)." >&2
  exit 1
fi

IMAGE_PATH=/opt/v4cvmfs-apptainer/v4cvmfs.sif

apptainer pull --force "$IMAGE_PATH" docker://ivukotic/v4cvmfs:latest
systemctl restart cvmfs-varnish-apptainer
echo "Updated and restarted cvmfs-varnish-apptainer."
