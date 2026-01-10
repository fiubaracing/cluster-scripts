#!/bin/bash
# /etc/slurm/suspend_program.sh

HOSTS=$(scontrol show hostnames $1)

for host in $HOSTS; do
    logger -t slurm_suspend "Powering OFF node: $host"
    sudo /usr/bin/wwsh ipmi poweroff $host
done

exit 0