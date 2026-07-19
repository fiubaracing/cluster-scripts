#!/bin/bash

if [ -z "$INSTALLER_DIR" ]; then
    echo "Error: INSTALLER_DIR is not set. Please run this script from the main installer" >&2
    exit 1
fi

set -eE
source $INSTALLER_DIR/.env

HEAD_NODE_NUMBER=2

if [ -n $(nmcli -g ipv4.addresses con show $IPMI_INTERFACE | grep -q "$IPMI_IPADDR.$HEAD_NODE_NUMBER")]; then
    nmcli con mod "$IPMI_INTERFACE" +ipv4.addresses "$IPMI_IPADDR.$HEAD_NODE_NUMBER/${IPMI_NETMASK[0]}"
fi

# Set IPMI credentials for compute nodes
for i in "${!c_name[@]}"; do
    node_name="${c_name[$i]}"
    node_number="${node_name#${compute_prefix}}"

    if [ "$node_number" = "$HEAD_NODE_NUMBER" ]; then
        continue
    fi

    wwctl node set "$node_name" \
        --ipmiaddr="${IPMI_IPADDR}${node_number}" \
        --ipminetmask="${IPMI_NETMASK[1]}" \
        --ipmiinterface="$IPMI_PROTO" \
        --ipmipass="$IPMI_PASSWORD" \
        --ipmiuser="$IPMI_USERNAME" \
        -y
done
