#!/bin/bash
echo "*******************************"
echo "*    Split Mesh To Regions    *"
echo "*******************************"

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


echo "ZONE_TO_REGION: $ZONE_TO_REGION"

if [[ "$NP" -lt "2" ]]; then
splitMeshRegions -overwrite -zoneToRegionMap "$ZONE_TO_REGION" -case "$CASE" 2>&1 | tee -a "$LOG"
else
$MPICOMMAND splitMeshRegions -parallel -overwrite -zoneToRegionMap "$ZONE_TO_REGION" -case "$CASE" 2>&1 | tee -a "$LOG"
fi


