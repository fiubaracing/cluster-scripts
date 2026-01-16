@echo off
echo "************************"
echo "*    Foam To Fluent    *"
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


set COMMAND=foamMeshToFluent -noFunctionObjects -case "%CASE%"

set ERROR_HANDLER=call echo %%^^errorlevel%% ^>errorcode.txt

(%COMMAND% & %%ERROR_HANDLER%%) 2>&1 | wtee -a "%LOG%"

set /p ERR=<errorcode.txt
del errorcode.txt

IF %ERR% NEQ 0 exit %ERR%


