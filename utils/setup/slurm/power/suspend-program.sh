#!/bin/bash
# /etc/slurm/suspend_program.sh

HOSTS=$(scontrol show hostnames $1)

for host in $HOSTS; do
    logger -t slurm_suspend "Powering OFF node: $host"
    sudo /usr/bin/wwctl power off "$host"
done

exit 0