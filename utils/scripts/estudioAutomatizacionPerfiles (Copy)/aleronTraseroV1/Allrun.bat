@echo off
echo "***************************"
echo "*    Running Simulation   *"
echo "***************************"

echo "Running blockMesh..."
call blockMesh > log.blockMesh 2>&1

echo "Running helyxHexMesh..."
call helyxHexMesh -overwrite > log.helyxHexMesh 2>&1

echo "Running caseSetup..."
call caseSetup -initialiseFields > log.caseSetup 2>&1

echo "Running decomposePar..."
call decomposePar -force > log.decomposePar 2>&1

echo "Done!"
