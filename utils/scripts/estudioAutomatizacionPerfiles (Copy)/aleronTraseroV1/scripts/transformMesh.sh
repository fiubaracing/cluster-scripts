#!/bin/bash
echo "************************"
echo "*    Transform Mesh    *"
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


echo "REGION: $REGION"
echo "TRANSFORM_ACTION: $TRANSFORM_ACTION"
echo "TRANSFORM_DATA: $TRANSFORM_DATA"

if [[ "$NP" -lt "2" ]]; then
transformPoints $TRANSFORM_ACTION "$TRANSFORM_DATA" $REGION -noFunctionObjects -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND transformPoints -parallel $TRANSFORM_ACTION "$TRANSFORM_DATA" $REGION -noFunctionObjects -case "$CASE" 2>&1 | tee -a "$LOG"
fi


