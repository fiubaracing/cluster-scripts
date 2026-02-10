#!/bin/bash

if [ -z "$INSTALLER_DIR" ]; then
    echo "Error: INSTALLER_DIR is not set. Please run this script from the main installer" >&2
    exit 1
fi

set -eE
source $INSTALLER_DIR/.env

CHROOT=${CHROOT:-"/opt/ohpc/admin/images/rocky9.6"}

cat $CHROOT/etc/systemd/system/lvm-setup.service << EOF
[Unit]
Description=LVM Setup Service
After=network.target

[Service]
ExecStart=/usr/local/sbin/create-lvm.sh

[Install]
WantedBy=multi-user.target
EOF

cp $INSTALLER_DIR/utils/setup/system/slaves/lvm/create-lvm.sh $CHROOT/usr/local/sbin/create-lvm.sh
chmod +x $CHROOT/usr/local/sbin/create-lvm.sh


mkdir -p $CHROOT/etc/systemd/system/multi-user.target.wants
ln -sf /etc/systemd/system/lvm-setup.service $CHROOT/etc/systemd/system/multi-user.target.wants/lvm-setup.service


MOUNT_POINT="/mnt/simulations"
mkdir -p "\${CHROOT}\${MOUNT_POINT}"

wwvnfs --chroot $CHROOT rocky9.6