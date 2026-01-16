#!/bin/bash
echo "******************"
echo "*    Topo Set    *"
echo "******************"

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


echo "REGION: $REGION"
echo "TOPO_SET_DICT: $TOPO_SET_DICT"

if [[ "$NP" -lt "2" ]]; then
topoSet $CONSTANT $REGION -dict system/"$TOPO_SET_DICT" -noFunctionObjects -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND topoSet $CONSTANT $REGION -dict system/"$TOPO_SET_DICT" -noFunctionObjects -case "$CASE" -parallel 2>&1 | tee -a "$LOG"
fi


