#!/bin/bash
# /etc/slurm/resume-program-manual.sh

scontrol update NodeName="$1" state=POWER_UP

# # 1. Expand the hostlist (e.g., "c[1-2]" -> "c1 c2")
# HOSTS=$(scontrol show hostnames $1)

# # 2. Loop through hosts and turn them on
# for host in $HOSTS; do
#     # Log the action (optional but recommended)
#     logger -t slurm_resume "Powering ON node: $host"
    
#     # Run Warewulf command via sudo
#     sudo /usr/bin/wwctl power on "$host"
# done

# echo "Waiting for nodes to power on in background..."

# (
#     for i in {1..12}; do
#         ALL_UP=true
#         for host in $HOSTS; do
#             if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" exit; then
#                 ALL_UP=false
#                 break
#             fi
#         done

#         if [ "$ALL_UP" = true ]; then
#             logger -t slurm_resume "All nodes $1 are up."
#             break
#         else
#             logger -t slurm_resume "Waiting for nodes to come up... (Attempt $i/12)"
#             sleep 60
#         fi
#     done

#     logger -t slurm_resume "Setting Slurm node(s) $NODE to RESUME"

#     for host in $HOSTS; do
#         sudo scontrol update NodeName="$host" state=RESUME
#     done
# ) >/dev/null 2>&1 &


# exit 0