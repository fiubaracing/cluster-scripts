@echo off
echo "************************"
echo "*    Fluent to Foam    *"
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


echo "FLUENT_SCALE: %FLUENT_SCALE%"
echo "FLUENT_FILE: %FLUENT_FILE%"
echo "FLUENT_CASE: %FLUENT_CASE%"

set COMMAND=fluent3DMeshToFoam -scale "%FLUENT_SCALE%" -noFunctionObjects -case "%FLUENT_CASE%" "%FLUENT_FILE%"

set ERROR_HANDLER=call echo %%^^errorlevel%% ^>errorcode.txt

(%COMMAND% & %%ERROR_HANDLER%%) 2>&1 | wtee -a "%LOG%"

set /p ERR=<errorcode.txt
del errorcode.txt

IF %ERR% NEQ 0 exit %ERR%


