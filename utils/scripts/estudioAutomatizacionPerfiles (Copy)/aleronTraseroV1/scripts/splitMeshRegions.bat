@echo off
echo "*******************************"
echo "*    Split Mesh To Regions    *"
echo "*******************************"

echo "CASE                  : %CASE%"
echo "NP                    : %NP%"
echo "LOG                   : %LOG%"
echo "CONSTANT              : %CONSTANT%"
echo "ALL_REGIONS           : %ALL_REGIONS%"
echo "ENV_LOADER            : %ENV_LOADER%"
echo "CORE_FOLDER           : %CORE_FOLDER%"
echo "GUI_FOLDER            : %GUI_FOLDER%"
echo "EXT_FOLDER            : %EXT_FOLDER%"


call "%CASE%\scripts\environment.bat"


echo "ZONE_TO_REGION: %ZONE_TO_REGION%"

if %NP% LSS 2 (
set COMMAND=splitMeshRegions -overwrite -zoneToRegionMap "%ZONE_TO_REGION%" -case "%CASE%"
) else (
set COMMAND=%MPICOMMAND% splitMeshRegions -parallel -overwrite -zoneToRegionMap "%ZONE_TO_REGION%" -case "%CASE%"
)

set ERROR_HANDLER=call echo %%^^errorlevel%% ^>errorcode.txt

(%COMMAND% & %%ERROR_HANDLER%%) 2>&1 | wtee -a "%LOG%"

set /p ERR=<errorcode.txt
del errorcode.txt

IF %ERR% NEQ 0 exit %ERR%


