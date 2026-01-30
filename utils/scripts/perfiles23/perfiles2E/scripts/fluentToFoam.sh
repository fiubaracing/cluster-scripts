#!/bin/bash
echo "************************"
echo "*    Fluent to Foam    *"
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


echo "FLUENT_SCALE: $FLUENT_SCALE"
echo "FLUENT_FILE: $FLUENT_FILE"
echo "FLUENT_CASE: $FLUENT_CASE"

fluent3DMeshToFoam -scale "$FLUENT_SCALE" -noFunctionObjects -case "$FLUENT_CASE" "$FLUENT_FILE" 2>&1 | tee -a "$LOG"

