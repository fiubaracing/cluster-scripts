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

echo "[Node $SLURM_NODEID] Staging-Out from $LOCAL_CASE_DIR to $SHARED_CASE_DIR"

# Check if source directory exists (it should!)
if [ ! -d "$LOCAL_CASE_DIR" ]; then
    echo "[Node $SLURM_NODEID] ERROR: Local directory $LOCAL_CASE_DIR does not exist. Skipping stage-out."
    exit 1
fi

# Use rsync -rltz (recursive, links, times, compressed)
# This avoids the "-a" flags for permissions (-p), group (-g), and owner (-o)
# which cause "Operation not permitted" errors on shared filesystems.
rsync -rltz $LOCAL_CASE_DIR/ $SHARED_CASE_DIR/

echo "[Node $SLURM_NODEID] Stage-Out complete."