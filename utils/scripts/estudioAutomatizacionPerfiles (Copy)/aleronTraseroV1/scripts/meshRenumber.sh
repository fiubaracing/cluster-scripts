#!/bin/bash
echo "***********************"
echo "*    Renumber Mesh    *"
echo "***********************"

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


if [[ "$NP" -lt "2" ]]; then
renumberMesh $ALL_REGIONS $CONSTANT -overwrite -noFunctionObjects -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND renumberMesh $ALL_REGIONS $CONSTANT -parallel -overwrite -noFunctionObjects -case "$CASE" 2>&1 | tee -a "$LOG"
fi


