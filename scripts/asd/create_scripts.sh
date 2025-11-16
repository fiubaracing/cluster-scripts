if [ $# -ne 4 ]; then
  # Print an error message to standard error (>&2)
  echo "Usage: $0 <JOB_NAME> <NODES> <TASKS> <TASKS_PER_NODE>" >&2
  echo "Error: This script requires exactly 4 arguments." >&2
  
  # Exit with a non-zero status
  exit 1
fi

JOB_NAME=$1
NODES=$2
TASKS=$3
TASKS_PER_NODE=$4
SCRIPT_CALL_DIR=$PWD

cd $HOME/scripts/slurm/helyx

echo "Creating decomposeParDict"
N=$(python3 calcN.py $TASKS)
cat decomposeParDict | sed "s/{{ TASKS }}/$TASKS/g; s/{{ N }}/$N/" > $SCRIPT_CALL_DIR/system/decomposeParDict


echo "Creating slurm batch job"
cat job.sbatch | sed "s/{{ JOB_NAME }}/$JOB_NAME/g; s/{{ NODES }}/$NODES/g; s/{{ TASKS }}/$TASKS/g; s/{{ TASKS_PER_NODE }}/$TASKS_PER_NODE/g; s/{{ OUTPUT }}/slurm-$JOB_NAME.out/g; s/{{ OERROR }}/slurm-$JOB_NAME.err/" > $SCRIPT_CALL_DIR/job.sbatch
ls $SCRIPT_CALL_DIR/Allrun > /dev/null
if [ $? -ne 0 ]; then
        cat Allrun > temp.sbatch
        nano temp.sbatch
        cat temp.sbatch >> $SCRIPT_CALL_DIR/job.sbatch
        rm temp.sbatch
else
        cat $SCRIPT_CALL_DIR/Allrun >> $SCRIPT_CALL_DIR/job.sbatch
fi
cat gather_metrics.sh >> $SCRIPT_CALL_DIR/job.sbatch

echo "Running helyx simulation"
cd $SCRIPT_CALL_DIR
sbatch job.sbatch