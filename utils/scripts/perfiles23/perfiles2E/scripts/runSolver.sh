#!/bin/bash
echo "********************"
echo "*    Run Solver    *"
echo "********************"

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


echo "SOLVER: $SOLVER"

if [[ "$NP" -lt "2" ]]; then
"$SOLVER" -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND "$SOLVER" -parallel -case "$CASE" 2>&1 | tee -a "$LOG"
fi


