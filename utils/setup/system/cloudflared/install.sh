#!/bin/bash
#
# Install the Cloudflare Tunnel connector as a systemd-managed Podman container
# (Quadlet). systemd starts it after the network is online at every boot,
# restarts it whenever it exits, and keeps its logs in the journal:
#
#   systemctl status cloudflared
#   journalctl -u cloudflared -f
#
# The tunnel token is kept in a root-only file instead of the command line,
# so it does not show up in "ps" or "podman inspect".

if [ -z "$INSTALLER_DIR" ]; then
    echo "Error: INSTALLER_DIR is not set. Please run this script from the main installer" >&2
    exit 1
fi

set -eE
source "$INSTALLER_DIR/.env"

if [ -z "${CLOUDFLARED_TUNNEL_TOKEN:-}" ]; then
    echo "Error: CLOUDFLARED_TUNNEL_TOKEN is not set in $INSTALLER_DIR/.env" >&2
    exit 1
fi

# Pin a cloudflared version for reproducible installs, or keep "latest".
CLOUDFLARED_IMAGE="${CLOUDFLARED_IMAGE:-docker.io/cloudflare/cloudflared:latest}"

dnf install -y podman

# --- Remove a container created by the previous installer, if present -------
old=$(podman ps -a --format '{{.ID}} {{.Image}}' | awk '/cloudflare\/cloudflared/ {print $1}')
if [ -n "$old" ]; then
    echo "Removing old cloudflared container(s): $old"
    podman rm -f $old
fi

# --- Token file (cloudflared reads TUNNEL_TOKEN from the environment) -------
install -d -m 0700 /etc/cloudflared
umask 077
printf 'TUNNEL_TOKEN=%s\n' "$CLOUDFLARED_TUNNEL_TOKEN" > /etc/cloudflared/tunnel.env
chmod 0600 /etc/cloudflared/tunnel.env

# --- Quadlet unit -----------------------------------------------------------
install -d -m 0755 /etc/containers/systemd
cat > /etc/containers/systemd/cloudflared.container <<EOF
[Unit]
Description=Cloudflare Tunnel connector
Wants=network-online.target
After=network-online.target

[Container]
Image=${CLOUDFLARED_IMAGE}
ContainerName=cloudflared
Network=host
EnvironmentFile=/etc/cloudflared/tunnel.env
Exec=tunnel --no-autoupdate run --protocol http2

[Service]
Restart=always
RestartSec=10
# The first start may need to pull the image
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 /etc/containers/systemd/cloudflared.container

# Make sure the system waits for the network at boot (NetworkManager setups)
systemctl enable NetworkManager-wait-online.service 2>/dev/null || true

# Quadlet units are generated at daemon-reload; [Install] handles boot start,
# so there is no "systemctl enable" for them.
systemctl daemon-reload
systemctl restart cloudflared.service

sleep 5
systemctl --no-pager status cloudflared.service || true
echo
echo "Logs: journalctl -u cloudflared -f"