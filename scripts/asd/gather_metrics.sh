# Create dummy file for ParaView visualisation
touch $JOB_NAME.foam

#------------------------------------------------------------------------------
# Gather metrics
#------------------------------------------------------------------------------
echo "Job ended on $(date)"
TOTAL_RUNTIME=$SECONDS

hours=$(( TOTAL_RUNTIME / 3600 ))
minutes=$(( (TOTAL_RUNTIME % 3600) / 60 ))
seconds=$(( TOTAL_RUNTIME % 60 ))

# For padded HH:MM:SS format, use printf
printf "Runtime duration: %02dh %02dm %02ds\n" $hours $minutes $seconds