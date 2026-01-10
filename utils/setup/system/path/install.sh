#!/bin/bash

if [ -z "$INSTALLER_DIR" ]; then
    echo "Error: INSTALLER_DIR is not set. Please run this script from the main installer" >&2
    exit 1
fi

set -eE
source $INSTALLER_DIR/.env

echo "Setting up CFD environment variables and aliases in /etc/profile.d/cfd-env.sh"

cat > /etc/profile.d/cfd-env.sh << EOF
# CFD Environment Variables and aliases

alias cfd='source $UTILS/menu.env && python3 $UTILS/cfdMenu.py'
alias useHelyx='source $REPO_PATH/cfd/tools/Engys/HELYXcore-4.4.1/platforms/activeBuild.shrc'

alias paraview='$REPO_PATH/cfd/tools/Paraview/ParaView-5.11.2-MPI-Linux-Python3.9-x86_64/bin/paraview'
alias useOpenFOAM='source $REPO_PATH/cfd/tools/openFOAM/OpenFOAM-v2506/etc/bashrc'

export PATH=$PATH:$REPO_PATH/cfd/tools/basilisk/src

EOF