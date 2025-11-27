# ----
# checkMesh
# ----

helyxRun -parallel helyxHexMesh
helyxRun reconstructParMesh -constant
rm -rf processor*
helyxRun checkMesh -constant

GREP_OUT=$(grep -i "warning" log.checkMesh)

if [ "$GREP_OUT" != "" ]; then
    echo "Mesh check completed with warnings:"
    echo "$GREP_OUT"
    echo "Please review the log.checkMesh file for details."
else
    echo "Mesh check completed without warnings."
fi