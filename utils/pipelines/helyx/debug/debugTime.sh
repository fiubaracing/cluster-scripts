#!/bin/bash

if [ $# -ne 2 ]; then
  # Print an error message to standard error (>&2)
  echo "Usage: $0 <NODE_ID> <TIME>" >&2
  echo "Error: This script requires exactly 2 arguments." >&2
  
  # Exit with a non-zero status
  exit 1
fi

SIMULATION_DIR="/mnt/simulations"
NODE_ID=$1
TIME_VAL=$2

pdsh -w c[$NODE_ID] "cat $SIMULATION_DIR/*/log.helyxSolve" | awk -v target="$TIME_VAL" '
    # 1. Detect the Separator (######)
    /################/ {
        # If we found our target in the PREVIOUS block, stop reading.
        # This jumps immediately to the END block to print.
        if (found_target) {
            exit
        }
        
        # Otherwise, reset for the new block
        block_content = ""
        found_target = 0
        next
    }

    # 2. Process lines inside the block
    {
        # Clean the line: Remove "c1:" and optional leading space
        clean_line = $0
        sub(/^c1:[ \t]?/, "", clean_line)

        # Append to buffer
        if (block_content == "") {
            block_content = clean_line
        } else {
            block_content = block_content "\n" clean_line
        }

        # Check for the Time value
        if ($0 ~ "Time = " target "$") {
            found_target = 1
        }
    }

    # 3. Print result (Runs via "exit" or end of file)
    END {
        if (found_target) {
            print block_content
        }
    }
'