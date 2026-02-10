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

chroot $CHROOT systemctl enable lvm-setup.service

MOUNT_POINT="/mnt/simulations"
VG_NAME="vg_simulations"
LV_NAME="cfd_lv"

cat $CHROOT/etc/fstab << EOF
# LVM Logical Volume for simulations
/dev/mapper/$VG_NAME-$LV_NAME $MOUNT_POINT ext4 defaults 0 0
EOF

wwvnfs --chroot $CHROOT rocky9.6