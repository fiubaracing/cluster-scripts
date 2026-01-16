@echo off
echo "************************"
echo "*    HELYX Hex Mesh    *"
echo "************************"

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


echo "REGIONS: %REGIONS%"
echo "REGIONS_LIST: %REGIONS_LIST%"

if "%REGIONS%" == "" (
if %NP% LSS 2 (
set COMMAND=helyxHexMesh -constant -case "%CASE%"
) else (
set COMMAND=%MPICOMMAND% helyxHexMesh -constant -parallel -case "%CASE%"
)
) else (
if %NP% LSS 2 (
set COMMAND=helyxHexMesh %REGIONS% "%REGIONS_LIST%" -constant -case "%CASE%"
) else (
set COMMAND=%MPICOMMAND% helyxHexMesh %REGIONS% "%REGIONS_LIST%" -constant -parallel -case "%CASE%"
)
)

set ERROR_HANDLER=call echo %%^^errorlevel%% ^>errorcode.txt

(%COMMAND% & %%ERROR_HANDLER%%) 2>&1 | wtee -a "%LOG%"

set /p ERR=<errorcode.txt
del errorcode.txt

IF %ERR% NEQ 0 exit %ERR%


