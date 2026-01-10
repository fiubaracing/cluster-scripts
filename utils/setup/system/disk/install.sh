#!/bin/bash

if [ -z "$INSTALLER_DIR" ]; then
    echo "Error: INSTALLER_DIR is not set. Please run this script from the main installer" >&2
    exit 1
fi

set -eE
source $INSTALLER_DIR/.env

if [ -z "${CFD_DATA_MOUNT_DIR}" ] || [ -z "${CFD_DATA_LVM}" ] || [ -z "${CFD_DATA_LVM_NAME}" ]; then
    echo "Error: CFD_DATA_MOUNT_DIR, CFD_DATA_LVM, and CFD_DATA_LVM_NAME environment variables must be set in .env." >&2
    exit 1
fi

NUMBER_OF_DISKS=$(lsblk -d --noheadings | grep disk | wc -l)

if [ "$NUMBER_OF_DISKS" -lt 3 ]; then
    echo "Not enough disks to setup CFD storage logical volume. Skipping..."
    exit 1
fi

# Scan for lvm physical volumes and volume groups
vgimportdevices -a
pvscan
vgscan
vgchange -ay $CFD_DATA_LVM_NAME
mkdir -p $CFD_DATA_MOUNT_DIR

# Set lvm mount
local CFD_DATA_FILE_SYSTEM='xfs'
local CFD_DATA_MOUNT_OPTIONS='defaults,nofail,noatime,nodiratime,logbsize=256k,allocsize=64m'
cat >> /etc/fstab << EOF
$CFD_DATA_LVM $CFD_DATA_MOUNT_DIR   $CFD_DATA_FILE_SYSTEM    $CFD_DATA_MOUNT_OPTIONS  0  0
EOF
mount -a

# Set NFS export
mkdir ${CHROOT}${CFD_DATA_MOUNT_DIR}
local CFD_DATA_FILE_SYSTEM='nfs'
local CFD_DATA_MOUNT_OPTIONS='defaults,_netdev,noatime,nodiratime,hard,rsize=1048576,wsize=1048576,bg'
cat >> $CHROOT/etc/fstab << EOF
$sms_ip:$CFD_DATA_MOUNT_DIR  $CFD_DATA_MOUNT_DIR    $CFD_DATA_FILE_SYSTEM    $CFD_DATA_MOUNT_OPTIONS  0 0
EOF

local CFD_DATA_EXPORT_OPTIONS='rw,no_root_squash,async,no_subtree_check'
cat >> /etc/exports << EOF
$CFD_DATA_MOUNT_DIR *($CFD_DATA_EXPORT_OPTIONS)
EOF

exportfs -ra
systemctl restart nfs-server