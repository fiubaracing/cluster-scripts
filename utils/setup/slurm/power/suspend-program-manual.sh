#!/bin/bash
# /etc/slurm/suspend-program-manual.sh

scontrol update NodeName="$1" state=POWER_DOWN