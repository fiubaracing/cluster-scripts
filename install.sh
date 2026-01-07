#!/bin/bash

source .env

set -e

THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR=/opt/ohpc/pub/apps

if [[ "$THIS_SCRIPT_DIR" == "$TARGET_DIR"* ]]; then
    echo "Target directory is the script directory or inside it: $TARGET_DIR"
    echo "Skipping move operation."
else 
    mkdir -p $TARGET_DIR

    mv -f "$THIS_SCRIPT_DIR/" "$TARGET_DIR/"
    THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
fi

UTILS="$THIS_SCRIPT_DIR/utils"

if [ -n "${RESEND_API_KEY}" ] && [ -n "${RESEND_VERIFIED_DOMAIN}" ]; then
    bash $UTILS/slurm-email/install.sh
fi

bash $UTILS/slurm-power/install.sh

git config --global --add safe.directory $THIS_SCRIPT_DIR

# Only add the IP if it's not already in the config
nmcli -g ipv4.addresses con show "eno1" | grep -q "10.2.1.2" \
|| nmcli con mod "eno1" +ipv4.addresses "10.2.1.2/24"

echo "Setting up CFD environment variables and aliases in /etc/profile.d/cfd-env.sh"

cat > /etc/profile.d/cfd-env.sh << EOF
# CFD Environment Variables and aliases

alias cfd='source $UTILS/menu.env && python3 $UTILS/cfdMenu.py'
alias useHelyx='source /home/admin/Engys/HELYXcore-4.4.1/platforms/activeBuild.shrc'

alias paraview='/home/admin/Documents/Paraview/ParaView-5.11.2-MPI-Linux-Python3.9-x86_64/bin/paraview'
alias useOpenFOAM='source /opt/ohpc/pub/apps/openFOAM/OpenFOAM-v2506/etc/bashrc'

export BASILISK=/opt/ohpc/pub/apps/basilisk/src
export PATH=$PATH:$BASILISK

EOF