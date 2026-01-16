#!/bin/bash
echo "****************************"
echo "*    Formula Calculator    *"
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


echo "FIELD: $FIELD"
echo "EXPRESSION: $EXPRESSION"
echo "TIME_STEP: $TIME_STEP"

if [[ "$NP" -lt "2" ]]; then
funkySetFields -noCacheVariables -case "$CASE" -field $FIELD -create -expression $EXPRESSION $TIME_STEP $REGION 2>&1 | tee -a "$LOG"
else
$MPICOMMAND funkySetFields -noCacheVariables -case "$CASE" -field $FIELD -create -expression $EXPRESSION $TIME_STEP $REGION -parallel 2>&1 | tee -a "$LOG"
fi


