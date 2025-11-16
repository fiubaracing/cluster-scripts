runHelyx() {
        if [ $# -ne 4 ]; then
                # Print an error message to standard error (>&2)
                echo "Usage: runHelyx <JOB_NAME> <NODES> <TASKS> <TASKS_PER_NODE>" >&2
                echo "Error: This script requires exactly 4 arguments." >&2
  
                # Exit with a non-zero status
                return
        fi

        /home/admin/scripts/slurm/helyx/create_scripts.sh $@
}