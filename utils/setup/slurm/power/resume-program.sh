#!/bin/bash
# /etc/slurm/resume_program.sh <hostlist>
#
# Slurm ResumeProgram: power on nodes through Warewulf/IPMI.
# Runs as SlurmUser on the slurmctld host, without a terminal and with a
# minimal PATH, so every command uses its absolute path and sudo runs
# non-interactively (-n). Failures are logged to syslog (journalctl -t slurm_resume).

set -u

WWCTL=/usr/bin/wwctl
SCONTROL=/usr/bin/scontrol
SUDO=/usr/bin/sudo
TAG=slurm_resume

# If a node Slurm wants to resume is already powered on, power-cycle it so
# that slurmd restarts and registers again. Otherwise slurmctld can keep the
# node in POWERING_UP ("idle#") until ResumeTimeout and then mark it DOWN.
CYCLE_IF_ON=yes

log() { /usr/bin/logger -t "$TAG" -- "$*"; }

if [ $# -lt 1 ] || [ -z "$1" ]; then
    log "called without a hostlist"
    exit 1
fi

mapfile -t HOSTS < <("$SCONTROL" show hostnames "$1")
log "resume requested for: ${HOSTS[*]}"

resume_one() {
    local host=$1 status action out rc

    status=$("$SUDO" -n "$WWCTL" power status "$host" 2>&1)
    if [ "$CYCLE_IF_ON" = yes ] && grep -qi 'power is on' <<<"$status"; then
        action=cycle
        log "$host is already powered on; power cycling so slurmd re-registers"
    else
        action=on
    fi

    out=$("$SUDO" -n "$WWCTL" power "$action" "$host" 2>&1)
    rc=$?
    if [ $rc -eq 0 ]; then
        log "$host: power $action OK"
    else
        log "$host: power $action FAILED (rc=$rc): $(tr '\n' ' ' <<<"$out")"
        return 1
    fi
}

# Run the IPMI calls in parallel; each one can take several seconds.
pids=()
for host in "${HOSTS[@]}"; do
    resume_one "$host" &
    pids+=($!)
done

rc=0
for pid in "${pids[@]}"; do
    wait "$pid" || rc=1
done
exit $rc