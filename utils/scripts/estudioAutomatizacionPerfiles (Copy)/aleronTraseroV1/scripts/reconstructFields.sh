#!/bin/bash
echo "****************************"
echo "*    Reconstruct Fields    *"
echo "****************************"

echo "CASE                  : $CASE"
echo "NP                    : $NP"
echo "LOG                   : $LOG"
echo "CONSTANT              : $CONSTANT"
echo "ALL_REGIONS           : $ALL_REGIONS"
echo "ENV_LOADER            : $ENV_LOADER"
echo "CORE_FOLDER           : $CORE_FOLDER"
echo "GUI_FOLDER            : $GUI_FOLDER"
echo "EXT_FOLDER            : $EXT_FOLDER"


. "$CASE/scripts/environment.conf"


echo "TIME_STEPS: $TIME_STEPS"

reconstructPar -withZero -noFunctionObjects $TIME_STEPS -case "$CASE" $ALL_REGIONS 2>&1 | tee -a "$LOG"

