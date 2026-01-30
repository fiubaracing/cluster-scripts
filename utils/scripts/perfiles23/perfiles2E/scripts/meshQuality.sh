#!/bin/bash
echo "**********************"
echo "*    Mesh Quality    *"
echo "**********************"

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


echo "REGIONS: $REGIONS"
echo "REGIONS_LIST: $REGIONS_LIST"

if [ -z ${REGIONS+x} ]; then
if [[ "$NP" -lt "2" ]]; then
checkMesh $CONSTANT -writeAllMetrics -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND checkMesh $CONSTANT -writeAllMetrics -parallel -case "$CASE" 2>&1 | tee -a "$LOG"
fi
else
if [[ "$NP" -lt "2" ]]; then
checkMesh $REGIONS "$REGIONS_LIST" $CONSTANT -writeAllMetrics -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND checkMesh $REGIONS "$REGIONS_LIST" $CONSTANT -writeAllMetrics -parallel -case "$CASE" 2>&1 | tee -a "$LOG"
fi
fi


