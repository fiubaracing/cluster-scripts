#!/bin/bash
# /etc/slurm/suspend_program.sh <hostlist>
#
# Slurm SuspendProgram: power off idle nodes through Warewulf/IPMI.
# Runs as SlurmUser on the slurmctld host, without a terminal and with a
# minimal PATH, so every command uses its absolute path and sudo runs
# non-interactively (-n). Failures are logged to syslog (journalctl -t slurm_suspend).
#
# Nodes are stateless (Warewulf), so a hard power off loses nothing; the
# local scratch volume is reused at the next boot.

set -u

WWCTL=/usr/bin/wwctl
SCONTROL=/usr/bin/scontrol
SUDO=/usr/bin/sudo
TAG=slurm_suspend

log() { /usr/bin/logger -t "$TAG" -- "$*"; }

if [ $# -lt 1 ] || [ -z "$1" ]; then
    log "called without a hostlist"
    exit 1
fi

mapfile -t HOSTS < <("$SCONTROL" show hostnames "$1")
log "suspend requested for: ${HOSTS[*]}"

suspend_one() {
    local host=$1 out rc

    out=$("$SUDO" -n "$WWCTL" power off "$host" 2>&1)
    rc=$?
    if [ $rc -eq 0 ]; then
        log "$host: power off OK"
    else
        log "$host: power off FAILED (rc=$rc): $(tr '\n' ' ' <<<"$out")"
        return 1
    fi
}

# Run the IPMI calls in parallel; each one can take several seconds.
pids=()
for host in "${HOSTS[@]}"; do
    suspend_one "$host" &
    pids+=($!)
done

rc=0
for pid in "${pids[@]}"; do
    wait "$pid" || rc=1
done
exit $rc