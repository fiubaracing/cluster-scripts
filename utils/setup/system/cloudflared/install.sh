#!/bin/bash

if [ -z "$INSTALLER_DIR" ]; then
    echo "Error: INSTALLER_DIR is not set. Please run this script from the main installer" >&2
    exit 1
fi

set -eE
source $INSTALLER_DIR/.env

dnf install podman-docker -y
systemctl start podman
systemctl enable podman

systemctl start podman-restart.service
systemctl enable podman-restart.service

docker run --restart always --network host -d docker.io/cloudflare/cloudflared:latest tunnel --no-autoupdate run --protocol http2 --token $CLOUDFLARED_TUNNEL_TOKEN   