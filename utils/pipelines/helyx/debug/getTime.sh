#!/bin/bash

if [ $# -ne 1 ]; then
  # Print an error message to standard error (>&2)
  echo "Usage: $0 <NODE_ID>" >&2
  echo "Error: This script requires exactly 1 argument." >&2
  
  # Exit with a non-zero status
  exit 1
fi

SIMULATION_DIR="/mnt/simulations"
NODE_ID=$1
pdsh -w c[$NODE_ID] "cat $SIMULATION_DIR/*/log.helyxSolve" | tac | grep -m 1 "Time"