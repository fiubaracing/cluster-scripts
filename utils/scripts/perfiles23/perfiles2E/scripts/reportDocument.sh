#!/bin/bash
echo "*************************"
echo "*    Report Document    *"
echo "*************************"

echo "CASE                  : $CASE"
echo "LOG                   : $LOG"
echo "GUI_FOLDER            : $GUI_FOLDER"
echo "EXT_FOLDER            : $EXT_FOLDER"
echo "REPORT_ORIENTATION    : $REPORT_ORIENTATION"
echo "REPORT_COMPARISON_PATH: $REPORT_COMPARISON_PATH"

source "$CASE/scripts/environment.conf"
echo "PYTHON_COMMAND        : $PYTHON_COMMAND"

source $GUI_FOLDER/bin/java.conf

set -e
set -o pipefail

# Force LANG
LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"
export LANG
export LC_ALL

JAVA_OPT="-cp $GUI_FOLDER/lib/HELYXTools.jar"
JAVA_OPT=$JAVA_OPT" eu.engys.report.LaunchReport"

$JAVA_EXE $JAVA_OPT "$PYTHON_COMMAND" scripts/reportDocument.py "$CASE" "$REPORT_ORIENTATION" "$REPORT_COMPARISON_PATH" | tee -a "$LOG"
