#!/bin/bash
#
# send_results.sh - Stage-out: copy results from node-local storage back to
# the shared case directory.
#
# Run once per node from the batch script:
#   srun -N "$SLURM_NNODES" --ntasks-per-node=1 \
#        bash "$WDIR/pipeline/send_results.sh" "$WDIR" "$LOCAL_CASE_DIR"
#
# Every node copies back only its own processor* directories, so nodes never
# write the same files on the shared filesystem at the same time.
# Node 0 (where rank 0 and the batch script run) also copies the root-level
# solver output: logs, postProcessing, etc. The input directories
# system/, constant/ and 0/ are never copied back; they were not modified.

if [ $# -ne 2 ]; then
    echo "Usage: $0 <SHARED_CASE_DIR> <LOCAL_CASE_DIR>" >&2
    echo "Error: This script requires exactly 2 arguments." >&2
    exit 1
fi

set -e -o pipefail

SHARED_CASE_DIR="$1"
LOCAL_CASE_DIR="$2"
NODE_ID="${SLURM_NODEID:?SLURM_NODEID not set - run this script through srun}"
TAG="[Node $NODE_ID $(hostname -s)]"

# -rlt: recursive, symlinks, times. Skips permissions/owner/group (-p -o -g),
# which cause "Operation not permitted" errors on shared filesystems.
RSYNC_OPTS=(-rlt)

echo "$TAG Staging-Out from $LOCAL_CASE_DIR to $SHARED_CASE_DIR"

if [ ! -d "$LOCAL_CASE_DIR" ]; then
    echo "$TAG ERROR: Local directory $LOCAL_CASE_DIR does not exist. Skipping stage-out." >&2
    exit 1
fi
if [ ! -d "$SHARED_CASE_DIR" ]; then
    echo "$TAG ERROR: Shared directory $SHARED_CASE_DIR does not exist." >&2
    exit 1
fi

# --- This node's processor directories ---------------------------------------
shopt -s nullglob
procs=("$LOCAL_CASE_DIR"/processor*)
shopt -u nullglob

if [ ${#procs[@]} -eq 0 ]; then
    echo "$TAG ERROR: no processor* directories found in $LOCAL_CASE_DIR" >&2
    exit 1
fi

echo "$TAG Copying ${#procs[@]} processor directories: ${procs[*]##*/}"
rsync "${RSYNC_OPTS[@]}" "${procs[@]}" "$SHARED_CASE_DIR/"

# --- Root-level solver output (node 0 only) ----------------------------------
if [ "$NODE_ID" -eq 0 ]; then
    echo "$TAG Copying root-level output (logs, postProcessing, ...)"
    rsync "${RSYNC_OPTS[@]}" \
        --exclude='/system/' --exclude='/constant/' --exclude='/0/' \
        --exclude='/processor*/' \
        "$LOCAL_CASE_DIR/" "$SHARED_CASE_DIR/"
fi

echo "$TAG Stage-Out complete."