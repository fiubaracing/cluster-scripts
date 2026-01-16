@echo off
echo "***********************"
echo "*    Create Report    *"
echo "***********************"

echo "CASE                  : %CASE%"
echo "LOG                   : %LOG%"
echo "GUI_FOLDER            : %GUI_FOLDER%"
echo "EXT_FOLDER            : %EXT_FOLDER%"
echo "REPORT_ORIENTATION    : %REPORT_ORIENTATION%"
echo "REPORT_COMPARISON_PATH: %REPORT_COMPARISON_PATH%"

set WTEE_EXE="%GUI_FOLDER%\bin\wtee"

call "%GUI_FOLDER%\bin\java-conf.bat"
set JAR_FILE="%GUI_FOLDER%\lib\HELYXTools.jar"
set MAIN_CLASS=eu.engys.report.LaunchReport

set COMMAND=%JAVA_EXE% -Dfile.encoding=UTF-8 -cp %JAR_FILE% %MAIN_CLASS% scripts/reportDocument.py "%CASE%" "%REPORT_ORIENTATION%" "%REPORT_COMPARISON_PATH%"
set ERROR_HANDLER=call echo %%^^errorlevel%% ^>errorcode.txt

(%COMMAND% & %%ERROR_HANDLER%%) 2>&1 | %WTEE_EXE% -a "%LOG%"

set /p ERR=<errorcode.txt
del errorcode.txt

IF %ERR% NEQ 0 exit %ERR%
