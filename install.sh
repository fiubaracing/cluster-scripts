#!/bin/bash

source .env

./slurm-email/install.sh
./slurm-power/install.sh

THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR=/opt/ohpc/pub/apps/
MENU_PWD="$TARGET_DIR/utils/"
mkdir -p $TARGET_DIR
mv -f "$THIS_SCRIPT_DIR/" "$TARGET_DIR/"

cat >> /etc/profile.d/cfd-env.sh << EOF
# CFD Environment Variables and aliases

export MENU_PWD=$MENU_PWD
alias cfd='source $MENU_PWD/menu.env && python3 $MENU_PWD/cfdMenu.py'
alias useHelyx='source /home/admin/Engys/HELYXcore-4.4.1/platforms/activeBuild.shrc'

alias paraview='/home/admin/Documents/Paraview/ParaView-5.11.2-MPI-Linux-Python3.9-x86_64/bin/paraview'
alias useOpenFOAM='source /opt/ohpc/pub/apps/openFOAM/OpenFOAM-v2506/etc/bashrc'

export BASILISK=/opt/ohpc/pub/apps/basilisk/src
export PATH=$PATH:$BASILISK

EOF