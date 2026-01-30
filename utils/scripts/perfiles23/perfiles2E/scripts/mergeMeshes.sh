#!/bin/bash
echo "**********************"
echo "*    Merge Meshes    *"
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


echo "MERGE_SOURCE: $MERGE_SOURCE"
echo "MERGE_SOURCE_REGION: $MERGE_SOURCE_REGION"
echo "MERGE_TARGET_REGION: $MERGE_TARGET_REGION"

if [[ "$NP" -lt "2" ]]; then
mergeMeshes -overwrite -noFunctionObjects -case "$CASE" "$CASE" $MERGE_TARGET_REGION "$MERGE_SOURCE" $MERGE_SOURCE_REGION 2>&1 | tee -a "$LOG"
else
$MPICOMMAND mergeMeshes -parallel -overwrite -noFunctionObjects -case "$CASE" "$CASE" $MERGE_TARGET_REGION "$MERGE_SOURCE" $MERGE_SOURCE_REGION 2>&1 | tee -a "$LOG"
fi


