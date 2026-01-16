#!/bin/bash
echo "************************"
echo "*    HELYX Hex Mesh    *"
echo "************************"

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
helyxHexMesh -constant -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND helyxHexMesh -constant -parallel -case "$CASE" 2>&1 | tee -a "$LOG"
fi
else
if [[ "$NP" -lt "2" ]]; then
helyxHexMesh $REGIONS "$REGIONS_LIST" -constant -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND helyxHexMesh $REGIONS "$REGIONS_LIST" -constant -parallel -case "$CASE" 2>&1 | tee -a "$LOG"
fi
fi


