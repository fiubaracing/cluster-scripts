@echo off
echo "****************************"
echo "*    Formula Calculator    *"
echo "****************************"

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


echo "FIELD: %FIELD%"
echo "EXPRESSION: %EXPRESSION%"
echo "TIME_STEP: %TIME_STEP%"

if %NP% LSS 2 (
set COMMAND=funkySetFields -noCacheVariables -case "%CASE%" -field %FIELD% -create -expression "%EXPRESSION%" %TIME_STEP% %REGION%
) else (
set COMMAND=%MPICOMMAND% funkySetFields -noCacheVariables -case "%CASE%" -field %FIELD% -create -expression "%EXPRESSION%" %TIME_STEP% %REGION% -parallel
)

set ERROR_HANDLER=call echo %%^^errorlevel%% ^>errorcode.txt

(%COMMAND% & %%ERROR_HANDLER%%) 2>&1 | wtee -a "%LOG%"

set /p ERR=<errorcode.txt
del errorcode.txt

IF %ERR% NEQ 0 exit %ERR%


