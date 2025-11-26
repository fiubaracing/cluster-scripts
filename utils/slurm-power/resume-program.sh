#!/bin/bash
# /etc/slurm/resume_program.sh

# 1. Expand the hostlist (e.g., "c[1-2]" -> "c1 c2")
HOSTS=$(scontrol show hostnames $1)

# 2. Loop through hosts and turn them on
for host in $HOSTS; do
    # Log the action (optional but recommended)
    logger -t slurm_resume "Powering ON node: $host"
    
    # Run Warewulf command via sudo
    sudo /usr/bin/wwsh ipmi poweron $host
done

exit 0