#!/bin/bash

if [ $# -ne 6 ]; then
  # Print an error message to standard error (>&2)
  echo "Usage: $0 <JOB_NAME> <NODES> <TASKS> <TASKS_PER_NODE> <EMAIL> <TYPE>" >&2
  echo "Error: This script requires exactly 6 arguments." >&2
  
  # Exit with a non-zero status
  exit 1
fi

JOB_NAME=$1
NODES=$2
TASKS=$3
TASKS_PER_NODE=$4
EMAIL=$5
TYPE=$6
SCDIR=$PWD # Script Call Directory

if [ "$TYPE" != "run" ] && [ "$TYPE" != "check" ]; then
    echo "Error: Unsupported TYPE '$TYPE'. Only 'run' or 'check' are supported."
    exit 1
fi

THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
echo "Changing directory to script location: $THIS_SCRIPT_DIR"
cd "$THIS_SCRIPT_DIR"

echo "Creating decomposeParDict"
# N=$(python3 calcN.py $TASKS) Using scotch, no need to calculate N
mkdir -p "$SCDIR/system"
sed "s/{{ TASKS }}/$TASKS/g; s/{{ N }}/$N/" decomposeParDict > "$SCDIR/system/decomposeParDict"

mkdir -p $SCDIR/pipeline

echo "Creating slurm batch job"
echo " - Adding header from template"
sed "s/{{ JOB_NAME }}/$JOB_NAME/g; s/{{ EMAIL }}/$EMAIL/g; s/{{ NODES }}/$NODES/g; s/{{ TASKS }}/$TASKS/g; s/{{ TASKS_PER_NODE }}/$TASKS_PER_NODE/g; s/{{ OUTPUT }}/pipeline\/$JOB_NAME.out/g; s/{{ OERROR }}/pipeline\/$JOB_NAME.err/" job.sbatch.header > $SCDIR/job.sbatch

if [ "$TYPE" == "check" ]; then
    echo " - Adding checkMesh section"
    cat check_mesh.sbatch >> $SCDIR/job.sbatch
    
else
    echo " - Adding run simulation section"
    
    if [ -f "$SCDIR/Allrun" ]; then
        cat $SCDIR/Allrun >> $SCDIR/job.sbatch
    else
        echo " - No Allrun script found. Creating one now."
        cat Allrun > $SCDIR/temp.sbatch
        nano $SCDIR/temp.sbatch
        cat $SCDIR/temp.sbatch >> $SCDIR/job.sbatch
        rm -f $SCDIR/temp.sbatch
    fi

    echo " - Looking for helyxSolve line to insert pre- and post-solve sections"
    SOLVE_LINE=$(grep -m1 'helyxRun.*helyxSolve' "$SCDIR/job.sbatch" | tr -d '\r')

    if [ "$SOLVE_LINE" != "" ]; then
        echo " - helyxSolve found!. Inserting pre-solve and post-solve sections"

        awk -v pre="$(cat job.sbatch.presolve)" -v solve="$SOLVE_LINE" -v post="$(cat job.sbatch.postsolve)" '
            $0 ~ /helyxRun.*helyxSolve/ {
                printf "%s\n%s\n%s\n", pre, solve, post
                next
            }
            { print }
        ' "$SCDIR/job.sbatch" > "$SCDIR/job.sbatch.tmp" && mv "$SCDIR/job.sbatch.tmp" "$SCDIR/job.sbatch"
    fi

    echo " - Adding tail from template"
    cat job.sbatch.tail >> $SCDIR/job.sbatch

    cp copy_tasks.sh send_results.sh $SCDIR/pipeline/
fi

mv $SCDIR/job.sbatch $SCDIR/pipeline/

echo "Changing back to original directory: $SCDIR"
cd $SCDIR

echo "Running job"
sbatch pipeline/job.sbatch
echo "Check pipeline/$JOB_NAME.out and pipeline/$JOB_NAME.err for job output and errors."
