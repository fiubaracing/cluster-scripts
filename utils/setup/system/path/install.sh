#!/bin/bash

if [ -z "$INSTALLER_DIR" ]; then
    echo "Error: INSTALLER_DIR is not set. Please run this script from the main installer" >&2
    exit 1
fi

set -eE
source $INSTALLER_DIR/.env

echo "Setting up CFD environment variables and aliases in /etc/profile.d/cfd-env.sh"

cat > /etc/profile.d/cfd-env.sh << EOF
# CFD Environment Variables and aliases

alias cfd='source $UTILS/menu.env && python3 $UTILS/cfdMenu.py'
alias useHelyx='source $REPO_PATH/cfd/tools/Engys/HELYXcore-4.4.1/platforms/activeBuild.shrc'

alias useOpenFOAM='source $REPO_PATH/cfd/tools/openFOAM/OpenFOAM-v2506/etc/bashrc'

export PATH=$PATH:$REPO_PATH/cfd/tools/basilisk/src
export PATH=$PATH:$REPO_PATH/cfd/tools/Paraview/ParaView-5.11.2-MPI-Linux-Python3.9-x86_64/bin

getTime() {
    NODE_ID=$1
    pdsh -w c[$NODE_ID] "cat /tmp/shm/*/log.helyxSolve" | tac | grep -m 1 "Time"
}

debugTime() {
    NODE_ID=$1
    TIME_VAL=$2

    pdsh -w c[$NODE_ID] "cat /tmp/shm/*/log.helyxSolve" | awk -v target="$TIME_VAL" '
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
}

EOF