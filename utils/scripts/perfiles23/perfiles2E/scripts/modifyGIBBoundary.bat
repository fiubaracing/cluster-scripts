@echo off
echo "*****************************"
echo "*    Modify GIB Boundary    *"
echo "*****************************"

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


echo "GIB_ARGUMENTS: %GIB_ARGUMENTS%"
echo "GIB_VALUES: %GIB_VALUES%"

if %NP% LSS 2 (
set COMMAND=modifyGIBBoundary -constant %GIB_ARGUMENTS% "%GIB_VALUES%" -case "%CASE%"
) else (
set COMMAND=%MPICOMMAND% modifyGIBBoundary -constant %GIB_ARGUMENTS% "%GIB_VALUES%" -parallel -case "%CASE%"
)

set ERROR_HANDLER=call echo %%^^errorlevel%% ^>errorcode.txt

(%COMMAND% & %%ERROR_HANDLER%%) 2>&1 | wtee -a "%LOG%"

set /p ERR=<errorcode.txt
del errorcode.txt

IF %ERR% NEQ 0 exit %ERR%


