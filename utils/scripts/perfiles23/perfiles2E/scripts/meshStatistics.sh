#!/bin/bash
echo "*************************"
echo "*    Mesh Statistics    *"
echo "*************************"

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


if [ -z ${REGIONS+x} ]; then
if [[ "$NP" -lt "2" ]]; then
checkMesh $CONSTANT $ALL_REGIONS -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND checkMesh $CONSTANT $ALL_REGIONS -parallel -case "$CASE" 2>&1 | tee -a "$LOG"
fi
else
if [[ "$NP" -lt "2" ]]; then
checkMesh $CONSTANT $REGIONS "$REGIONS_LIST" -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND checkMesh $CONSTANT $REGIONS "$REGIONS_LIST" -parallel -case "$CASE" 2>&1 | tee -a "$LOG"
fi
fi


