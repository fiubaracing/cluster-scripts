#!/bin/bash

#==================================================================
# SLURM Directives
# DO NOT EDIT THESE SETTINGS
#==================================================================
#SBATCH --job-name="{{ JOB_NAME }}"       # Job name
#SBATCH --nodes={{ NODES }}                    # Number of nodes
#SBATCH --ntasks={{ TASKS }}                  # Total number of MPI ranks (nodes * cores/node)
#SBATCH --ntasks-per-node={{ TASKS_PER_NODE }}          # Cores per node
#SBATCH --output={{ OUTPUT }}      # Standard output log
#SBATCH --error={{ OERROR }}       # Standard error log

#==================================================================
# Environment Setup
#==================================================================
echo "Job started on $(date)"
echo "Running on nodes: $SLURM_JOB_NODELIST using $SLURM_NTASKS tasks"
set -e

cd $SLURM_SUBMIT_DIR
source /home/admin/Engys/HELYXcore-4.4.1/platforms/activeBuild.shrc
SECONDS=0

#==================================================================
# HELYX simulation commands
#==================================================================
