@echo off
echo "**********************"
echo "*    Merge Meshes    *"
echo "**********************"

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


echo "MERGE_SOURCE: %MERGE_SOURCE%"
echo "MERGE_SOURCE_REGION: %MERGE_SOURCE_REGION%"
echo "MERGE_TARGET_REGION: %MERGE_TARGET_REGION%"

if %NP% LSS 2 (
set COMMAND=mergeMeshes -overwrite -noFunctionObjects -case "%CASE%" "%CASE%" %MERGE_TARGET_REGION% "%MERGE_SOURCE%" %MERGE_SOURCE_REGION%
) else (
set COMMAND=%MPICOMMAND% mergeMeshes -parallel -overwrite -noFunctionObjects -case "%CASE%" "%CASE%" %MERGE_TARGET_REGION% "%MERGE_SOURCE%" %MERGE_SOURCE_REGION%
)

set ERROR_HANDLER=call echo %%^^errorlevel%% ^>errorcode.txt

(%COMMAND% & %%ERROR_HANDLER%%) 2>&1 | wtee -a "%LOG%"

set /p ERR=<errorcode.txt
del errorcode.txt

IF %ERR% NEQ 0 exit %ERR%


