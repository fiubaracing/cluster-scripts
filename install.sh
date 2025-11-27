#!/bin/bash

source .env

set -e

THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET_DIR=/opt/ohpc/pub/apps/
mkdir -p $TARGET_DIR

mv -f "$THIS_SCRIPT_DIR/" "$TARGET_DIR/"
THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

UTILS="$THIS_SCRIPT_DIR/utils/"

# bash $UTILS/slurm-email/install.sh
# bash $UTILS/slurm-power/install.sh

chmod +x $UTILS/update-menu.sh
chmod +x $UTILS/pipelines/helyx/create_scripts.sh
chmod +x $UTILS/pipelines/helyx/send_results.sh
chmod +x $UTILS/pipelines/helyx/copy_tasks.sh

cat >> /etc/profile.d/cfd-env.sh << EOF
# CFD Environment Variables and aliases

alias cfd='source $UTILS/menu.env && python3 $UTILS/cfdMenu.py'
alias useHelyx='source /home/admin/Engys/HELYXcore-4.4.1/platforms/activeBuild.shrc'

alias paraview='/home/admin/Documents/Paraview/ParaView-5.11.2-MPI-Linux-Python3.9-x86_64/bin/paraview'
alias useOpenFOAM='source /opt/ohpc/pub/apps/openFOAM/OpenFOAM-v2506/etc/bashrc'

export BASILISK=/opt/ohpc/pub/apps/basilisk/src
export PATH=$PATH:$BASILISK

EOF