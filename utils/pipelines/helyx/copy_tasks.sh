#!/bin/bash

if [ $# -ne 2 ]; then
  # Print an error message to standard error (>&2)
  echo "Usage: $0 <SHARED_CASE_DIR> <LOCAL_CASE_DIR>" >&2
  echo "Error: This script requires exactly 2 arguments." >&2
  
  # Exit with a non-zero status
  exit 1
fi

set -e

SHARED_CASE_DIR=$1
LOCAL_CASE_DIR=$2

# Create the local directory
mkdir -p $LOCAL_CASE_DIR
echo "[Node $SLURM_NODEID] Created $LOCAL_CASE_DIR"

# --- Copy common directories ---
# Every node needs these. rsync is efficient.
echo "[Node $SLURM_NODEID] Copying common files (system, constant, 0)..."
rsync -a $SHARED_CASE_DIR/system $LOCAL_CASE_DIR/
rsync -a $SHARED_CASE_DIR/constant $LOCAL_CASE_DIR/
if [ -d "$SHARED_CASE_DIR/0" ]; then
    rsync -a $SHARED_CASE_DIR/0 $LOCAL_CASE_DIR/
fi

# --- Calculate and copy processor directories ---
# This is the core logic.
# Each node calculates its own rank range.
START_RANK=$((SLURM_NODEID * SLURM_NTASKS_PER_NODE))
END_RANK=$(( (SLURM_NODEID + 1) * SLURM_NTASKS_PER_NODE - 1 ))

echo "[Node $SLURM_NODEID] Copying processor directories $START_RANK to $END_RANK..."

for i in $(seq $START_RANK $END_RANK); do
    rsync -a $SHARED_CASE_DIR/processor$i $LOCAL_CASE_DIR/
done

echo "[Node $SLURM_NODEID] Stage-In complete."