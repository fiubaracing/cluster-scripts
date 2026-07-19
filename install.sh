#!/bin/bash

source .env

set -eE

THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [[ "$THIS_SCRIPT_DIR" == "$REPO_PATH"* ]]; then
    echo "Target directory is the script directory or inside it: $REPO_PATH"
    echo "Skipping move operation."
else 
    mkdir -p $REPO_PATH

    mv -f "$THIS_SCRIPT_DIR/" "$REPO_PATH/"
    THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
fi

UTILS="$THIS_SCRIPT_DIR/utils"
INSTALLER_DIR=$THIS_SCRIPT_DIR

# Ensure git considers this directory safe to enable git pulls
git config --global --add safe.directory $INSTALLER_DIR
bash $UTILS/update-menu.sh

cp .env /home/admin/variables.config && bash install_script.sh

# Install SLURM configurations
if [ -n "${RESEND_API_KEY}" ] && [ -n "${RESEND_VERIFIED_DOMAIN}" ]; then
    bash $UTILS/setup/slurm/email/install.sh
fi
bash $UTILS/setup/slurm/power/install.sh
# Install IPMI configurations
bash $UTILS/setup/ipmi/install.sh
# Install system configurations
bash $UTILS/setup/system/cloudflared/install.sh
bash $UTILS/setup/system/path/install.sh
bash $UTILS/setup/system/disk/install.sh