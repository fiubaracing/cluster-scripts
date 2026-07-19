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
export INSTALLER_DIR=$THIS_SCRIPT_DIR

mkdir -p $INSTALLER_DIR/logs

# Ensure git considers this directory safe to enable git pulls
git config --global --add safe.directory $INSTALLER_DIR
bash $UTILS/update-menu.sh

cp .env /home/admin/variables.config
echo "Installing cluster main configuration"
bash install_script.sh 2>&1 $INSTALLER_DIR/logs/install.log

# Install SLURM configurations
if [ -n "${RESEND_API_KEY}" ] && [ -n "${RESEND_VERIFIED_DOMAIN}" ]; then
    echo "Installing SLURM email notification script"
    bash $UTILS/setup/slurm/email/install.sh 2>&1 $INSTALLER_DIR/logs/slurm_email_install.log
fi

echo "Installing SLURM power management scripts"
bash $UTILS/setup/slurm/power/install.sh 2>&1 $INSTALLER_DIR/logs/slurm_power_install.log

# Install IPMI configurations
echo "Installing IPMI configurations"
bash $UTILS/setup/ipmi/install.sh 2>&1 $INSTALLER_DIR/logs/ipmi_install.log

# Install system configurations
echo "Installing system configurations"

echo "Installing cloudflared"
bash $UTILS/setup/system/cloudflared/install.sh 2>&1 $INSTALLER_DIR/logs/cloudflared_install.log

echo "Installing path configurations"
bash $UTILS/setup/system/path/install.sh 2>&1 $INSTALLER_DIR/logs/path_install.log

echo "Installing disk configurations"
bash $UTILS/setup/system/disk/install.sh 2>&1 $INSTALLER_DIR/logs/disk_install.log