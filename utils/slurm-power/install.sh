#!/bin/bash

cp ./resume-program.sh /etc/slurm/resume_program.sh
cp ./suspend-program.sh /etc/slurm/suspend_program.sh
chmod +x /etc/slurm/resume_program.sh
chmod +x /etc/slurm/suspend_program.sh
chown slurm:slurm /etc/slurm/resume_program.sh /etc/slurm/suspend_program.sh

VARIABLES=( 
    # Programs to handle node power management
    ("ResumeProgram" "/etc/slurm/resume_program.sh")
    ("SuspendProgram" "/etc/slurm/suspend_program.sh")
    # SuspendTime: how long to wait (in seconds) before powering off an idle node
    # 300 seconds = 5 minutes of being IDLE
    ("SuspendTime" "300")
    # SuspendTimeout: how long to wait (in seconds) for the suspend program to complete
    # In other words, how long to wait for the node to power off
    ("SuspendTimeout" "30")
    # ResumeTimeout (How long Slurm waits for the node to boot)
    # If the node doesn't register within this time, Slurm marks it DOWN.
    # 600 seconds = 10 minutes (Adjust based on your boot speed)
    ("ResumeTimeout" "600")
    # ResumeRate: Number of nodes to resume simultaneously
    # Adjust based on your power infrastructure capacity
    ("ResumeRate" "4")
    # SuspendRate: Number of nodes to suspend simultaneously
    # Adjust based on your power infrastructure capacity
    ("SuspendRate" "4")
)

for VAR in "${VARIABLES[@]}"; do
    KEY=$(echo $VAR | cut -d' ' -f1)
    VALUE=$(echo $VAR | cut -d' ' -f2)

    if grep -qE "^[[:space:]]*#?[[:space:]]*$KEY=" /etc/slurm/slurm.conf; then
        echo "Updating $KEY in /etc/slurm/slurm.conf to $VALUE"
        sed -i -E "s|^[[:space:]]*#?[[:space:]]*$KEY=.*|$KEY=$VALUE|" /etc/slurm/slurm.conf
    else
        echo "Adding $KEY=$VALUE to /etc/slurm/slurm.conf"
        echo "$KEY=$VALUE" >> /etc/slurm/slurm.conf
    fi
done

echo "Restarting slurmctld to apply changes"
scontrol reconfigure
systemctl restart slurmctld

SUDOERS=$(grep -l 'wwsh ipmi' /etc/sudoers.d/* 2>/dev/null)

if [ -n "$SUDOERS" ]; then
    echo "Sudoers file for wwsh ipmi commands already exists: $SUDOERS"
    echo "Skipping creation of new sudoers file."
    exit 0
fi

bash -c 'cat << EOF > /etc/sudoers.d/slurm-wwsh
# Allow slurm user to run wwsh ipmi commands without a password
slurm ALL=(ALL) NOPASSWD: /usr/bin/wwsh ipmi poweron *
slurm ALL=(ALL) NOPASSWD: /usr/bin/wwsh ipmi poweroff *
EOF'
chmod 440 /etc/sudoers.d/slurm-wwsh