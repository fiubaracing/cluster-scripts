#!/bin/bash

#------------------------------------------------------------------------------
# SLURM Directives
# DO NOT EDIT THESE SETTINGS
#------------------------------------------------------------------------------

# Job name
#SBATCH --job-name="V1"       

# Number of nodes
#SBATCH --nodes=2                    

# Total number of MPI ranks (nodes * cores/node)
#SBATCH --ntasks=32                  

# Cores per node
#SBATCH --ntasks-per-node=16          

# Standard output log
#SBATCH --output=pipeline/V1.out      

# Standard error log
#SBATCH --error=pipeline/V1.err       

# Email notifications (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-type=ALL

# Email address
#SBATCH --mail-user=jcampoy@fi.uba.ar

#------------------------------------------------------------------------------
# Environment Setup
#------------------------------------------------------------------------------
echo "Job started on $(date)"
echo "Running on nodes: $SLURM_JOB_NODELIST using $SLURM_NTASKS tasks"
set -e

LOCAL_STORAGE_PATH="/tmp/shm"

# Create a unique directory for this job on the local storage
LOCAL_CASE_DIR="$LOCAL_STORAGE_PATH/job_$SLURM_JOB_ID"
WDIR=$SLURM_SUBMIT_DIR
cd $WDIR
source /opt/ohpc/pub/apps/cfd/tools/Engys/HELYXcore-4.4.1/platforms/activeBuild.shrc
SECONDS=0

#------------------------------------------------------------------------------
#  Retrieve logs to master node
#------------------------------------------------------------------------------
retrieve_logs_to_master() {
    # Only the slurm task selected master node retrieves logs
    if [ "$SLURM_NODEID" -eq 0 ]; then
        echo "[Node $SLURM_NODEID] Retrieving logs to master node..."
        rsync -a $LOCAL_CASE_DIR/postProcessing $WDIR/
        rsync -a $LOCAL_CASE_DIR/log.* $WDIR/
        echo "[Node $SLURM_NODEID] Logs retrieval complete."
    fi
}

#------------------------------------------------------------------------------
#  Cleanup local temp directories on all nodes
#------------------------------------------------------------------------------
remove_local_case_dir() {
    echo "[Node $SLURM_NODEID] Cleaning up local case directory..."
    srun -N $SLURM_NNODES rm -rf $LOCAL_CASE_DIR
    echo "[Node $SLURM_NODEID] Local case directory removed."
}

#------------------------------------------------------------------------------
# Gather metrics
#------------------------------------------------------------------------------
gather_metrics() {
    echo "Job ended on $(date)"
    TOTAL_RUNTIME=$SECONDS

    hours=$(( TOTAL_RUNTIME / 3600 ))
    minutes=$(( (TOTAL_RUNTIME % 3600) / 60 ))
    seconds=$(( TOTAL_RUNTIME % 60 ))

    # For padded HH:MM:SS format, use printf
    printf "Runtime duration: %02dh %02dm %02ds\n" $hours $minutes $seconds
}

on_exit() {
    retrieve_logs_to_master
    remove_local_case_dir
    gather_metrics
}

trap on_exit EXIT

#------------------------------------------------------------------------------
# HELYX simulation commands
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Feel free to edit these commands as needed
# Only include parallelizable workload
#
# Ctrl + X, Y, Enter. To exit and save
#------------------------------------------------------------------------------

echo "Running mesh"
helyxRun cartesian2DMesh

echo "Running quality check"
helyxRun checkMesh -constant

echo "Running setup"
helyxRun caseSetup

echo "Decomposing case"
helyxRun decomposePar -force -noFunctionObjects

echo "Running solver"

#------------------------------------------------------------------------------
# Pre-solve: Copy split tasks to local node directories
#------------------------------------------------------------------------------
echo "Copy split in nodes $(date)"
srun --ntasks $SLURM_NNODES bash $WDIR/pipeline/copy_tasks.sh $WDIR $LOCAL_CASE_DIR
echo "Finished copy task splits $(date)"

cd $LOCAL_CASE_DIR

#------------------------------------------------------------------------------
# Run helyxSolve
#------------------------------------------------------------------------------
echo "Running helyxSolve $(date)"
helyxRun helyxSolve -parallel

#------------------------------------------------------------------------------
# Post-solve: Send results back to master node
#------------------------------------------------------------------------------
echo "Finished helyxSolve $(date)"

echo "Send results to master $(date)"
echo "Staging-Out results to $SHARED_CASE_DIR..."
srun --ntasks=$SLURM_NNODES bash $WDIR/pipeline/send_results.sh $WDIR $LOCAL_CASE_DIR
echo "Finished send results to master $(date)"

cd $WDIR

echo "Reconstructing geometry"
helyxRun -serial reconstructParMesh -constant

echo "Reconstructing fields"
helyxRun -serial reconstructPar -withZero

#------------------------------------------------------------------------------
# Create dummy file for ParaView visualisation
#------------------------------------------------------------------------------
touch $JOB_NAME.foam
echo "Finished Reconstruct $(date)"
