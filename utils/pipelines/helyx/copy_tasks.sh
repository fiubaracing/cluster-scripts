#!/bin/bash
#
# copy_tasks.sh - Stage-in: copy the case to node-local storage.
#
# Run once per node from the batch script:
#   srun -N "$SLURM_NNODES" --ntasks-per-node=1 \
#        bash "$WDIR/pipeline/copy_tasks.sh" "$WDIR" "$LOCAL_CASE_DIR" "$SLURM_NTASKS_PER_NODE"
#
# The third argument must be the job's ranks per node, evaluated in the batch
# script. Inside this srun step SLURM_NTASKS_PER_NODE is 1 (the step's value),
# so it cannot be used here.

if [ $# -ne 3 ]; then
    echo "Usage: $0 <SHARED_CASE_DIR> <LOCAL_CASE_DIR> <RANKS_PER_NODE>" >&2
    echo "Error: This script requires exactly 3 arguments." >&2
    exit 1
fi

set -e -o pipefail

SHARED_CASE_DIR="$1"
LOCAL_CASE_DIR="$2"
RANKS_PER_NODE="$3"
NODE_ID="${SLURM_NODEID:?SLURM_NODEID not set - run this script through srun}"
TAG="[Node $NODE_ID $(hostname -s)]"

if ! [[ "$RANKS_PER_NODE" =~ ^[1-9][0-9]*$ ]]; then
    echo "$TAG Error: RANKS_PER_NODE must be a positive integer, got '$RANKS_PER_NODE'" >&2
    exit 1
fi

# Create the local directory
mkdir -p "$LOCAL_CASE_DIR"
echo "$TAG Created $LOCAL_CASE_DIR"

# --- Copy common directories -------------------------------------------------
# Every node needs these.
common=("$SHARED_CASE_DIR/system" "$SHARED_CASE_DIR/constant")
[ -d "$SHARED_CASE_DIR/0" ] && common+=("$SHARED_CASE_DIR/0")

echo "$TAG Copying common files (${common[*]##*/})..."
rsync -a "${common[@]}" "$LOCAL_CASE_DIR/"

# --- Copy this node's processor directories ----------------------------------
# Assumes block rank placement: node 0 runs ranks 0..N-1, node 1 runs N..2N-1, ...
START_RANK=$(( NODE_ID * RANKS_PER_NODE ))
END_RANK=$(( (NODE_ID + 1) * RANKS_PER_NODE - 1 ))

echo "$TAG Copying processor directories $START_RANK to $END_RANK..."

procs=()
for i in $(seq "$START_RANK" "$END_RANK"); do
    d="$SHARED_CASE_DIR/processor$i"
    if [ ! -d "$d" ]; then
        echo "$TAG Error: $d not found - is the case decomposed into the same number of ranks as the job?" >&2
        exit 1
    fi
    procs+=("$d")
done

rsync -a "${procs[@]}" "$LOCAL_CASE_DIR/"

echo "$TAG Stage-In complete ($(du -sh "$LOCAL_CASE_DIR" | cut -f1) in $LOCAL_CASE_DIR)."