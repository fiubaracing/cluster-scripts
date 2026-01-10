#!/bin/bash

if [ -z "$INSTALLER_DIR" ]; then
    echo "Error: INSTALLER_DIR is not set. Please run this script from the main installer" >&2
    exit 1
fi

set -eE
source $INSTALLER_DIR/.env

local HEAD_NODE_NUMBER=2

if [ -n $(nmcli -g ipv4.addresses con show $IPMI_INTERFACE | grep -q "$IPMI_IPADDR.$HEAD_NODE_NUMBER")]; then
    nmcli con mod $IPMI_INTERFACE +ipv4.addresses "$IPMI_IPADDR.$HEAD_NODE_NUMBER/${IPMI_NETMASK[0]}"
fi

# Get node numbers without compute-2 because it's reserved for the head node
node_numbers=$(seq 1 $num_computes | grep -vx $HEAD_NODE_NUMBER)
# Set IPMI credentials for compute nodes
for i in $(seq 1 $num_computes); do
    wwsh object modify \
        -s IPMI_IPADDR=${IPMI_IPADDR}${c_name[$i-1]} \
        -s IPMI_NETMASK=${IPMI_NETMASK[1]} \
        -s IPMI_PROTO=\'$IPMI_PROTO\' \
        -s IPMI_PASSWORD=\'$IPMI_PASSWORD\' \
        -s IPMI_USERNAME=\'$IPMI_USERNAME\' \
        ${c_name[$i-1]} --yes
done
