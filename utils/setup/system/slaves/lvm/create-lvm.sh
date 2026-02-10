#!/bin/bash

set -eE

MOUNT_POINT="/mnt/simulations"
VG_NAME="vg_simulations"
LV_NAME="cfd_lv"

# Ensure mount point exists
mkdir -p "$MOUNT_POINT"
chmod 777 "$MOUNT_POINT"

# Function to get available disks (excluding system disks containing / or /boot)
get_available_disks() {
    local candidates=()
    local all_disks
    all_disks=$(lsblk -d -n -o NAME,TYPE | awk '$2 == "disk" {print $1}')

    for dev in $all_disks; do
        # Check if this disk or its partitions are mounted at / or /boot
        if lsblk -n -o MOUNTPOINT "/dev/$dev" | grep -E -q '^/$|^/boot'; then
            # This is a system disk, skip it
            continue
        else
            candidates+=("/dev/$dev")
        fi
    done
    echo "${candidates[@]}"
}

DISKS=($(get_available_disks))
NUM_DISKS=${#DISKS[@]}

echo "Found $NUM_DISKS available disk(s): ${DISKS[*]}"

if [ "$NUM_DISKS" -eq 0 ]; then
    echo "Disks: 0. Action: Mount /tmp/shm into $MOUNT_POINT"
    
    # Create /tmp/shm if it doesn't exist (it should be a directory for bind mount)
    mkdir -p /tmp/shm
    
    if ! mountpoint -q "$MOUNT_POINT"; then
        mount --bind /tmp/shm "$MOUNT_POINT"
        echo "Mounted /tmp/shm to $MOUNT_POINT"
    else
        echo "$MOUNT_POINT is already mounted."
    fi

elif [ "$NUM_DISKS" -eq 1 ]; then
    DISK="${DISKS[0]}"
    echo "Disks: 1 ($DISK). Action: Create LVM and mount to $MOUNT_POINT"

    if mountpoint -q "$MOUNT_POINT"; then
        echo "$MOUNT_POINT is already mounted. Skipping."
    else
        # Remove all existing volume groups
        # The previous data on the disks will be lost
        # This is intended for fresh start setups
        if vgs --noheadings -o vg_name >/dev/null 2>&1; then
            for vg in $(vgs --noheadings -o vg_name); do
            vgremove -y -f "$vg" || true
            done
        fi

        # Initialize Physical Volume
        pvcreate -y "$DISK"
        
        # Create Volume Group
        vgcreate -y "$VG_NAME" "$DISK"
        
        # Create Logical Volume (use 100% free space)
        lvcreate -y -l 100%FREE -n "$LV_NAME" "$VG_NAME"
        
        # Format with XFS
        mkfs.xfs -f "/dev/$VG_NAME/$LV_NAME"
        
        # Mount
        mount "/dev/$VG_NAME/$LV_NAME" "$MOUNT_POINT"
        echo "Mounted /dev/$VG_NAME/$LV_NAME to $MOUNT_POINT"
    fi

elif [ "$NUM_DISKS" -eq 2 ]; then
    DISK1="${DISKS[0]}"
    DISK2="${DISKS[1]}"
    echo "Disks: 2 ($DISK1, $DISK2). Action: Create LVM RAID 0 and mount to $MOUNT_POINT"

    if mountpoint -q "$MOUNT_POINT"; then
        echo "$MOUNT_POINT is already mounted. Skipping."
    else
        # Remove all existing volume groups
        # The previous data on the disks will be lost
        # This is intended for fresh start setups
        if vgs --noheadings -o vg_name >/dev/null 2>&1; then
            for vg in $(vgs --noheadings -o vg_name); do
            vgremove -y -f "$vg" || true
            done
        fi
        # Initialize Physical Volumes
        pvcreate -y "$DISK1" "$DISK2"
        
        # Create Volume Group
        vgcreate -y "$VG_NAME" "$DISK1" "$DISK2"
        
        # Create Logical Volume (RAID 0, stripes across 2 PVs)
        lvcreate -y --type raid0 --stripes 2 -l 100%FREE -n "$LV_NAME" "$VG_NAME"
        
        # Format with XFS
        mkfs.xfs -f "/dev/$VG_NAME/$LV_NAME"
        
        # Mount
        mount "/dev/$VG_NAME/$LV_NAME" "$MOUNT_POINT"
        echo "Mounted /dev/$VG_NAME/$LV_NAME (RAID 0) to $MOUNT_POINT"
    fi

else
    echo "Disks: $NUM_DISKS. No automated action defined for this count."
fi
