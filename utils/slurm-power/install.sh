cp ./resume-program.sh /etc/slurm/resume_program.sh
cp ./suspend-program.sh /etc/slurm/suspend_program.sh
chmod +x /etc/slurm/resume_program.sh
chmod +x /etc/slurm/suspend_program.sh
chown slurm:slurm /etc/slurm/resume_program.sh /etc/slurm/suspend_program.sh

bash -c 'cat << EOF > /etc/sudoers.d/slurm-wwsh
# Allow slurm user to run wwsh ipmi commands without a password
slurm ALL=(ALL) NOPASSWD: /usr/bin/wwsh ipmi poweron *
slurm ALL=(ALL) NOPASSWD: /usr/bin/wwsh ipmi poweroff *
EOF'
chmod 440 /etc/sudoers.d/slurm-wwsh

# Scripts
sed -i 's|^ResumeProgram=.*|ResumeProgram=/etc/slurm/resume_program.sh|' /etc/slurm/slurm.conf
sed -i 's|^SuspendProgram=.*|SuspendProgram=/etc/slurm/suspend_program.sh|' /etc/slurm/slurm.conf
# The Timeout (How long to wait before turning off)
# 300 seconds = 5 minutes of being IDLE
sed -i 's|^SuspendTimeout=.*|SuspendTimeout=300|' /etc/slurm/slurm.conf
# Timeout (How long Slurm waits for the node to boot)
# If the node doesn't register within this time, Slurm marks it DOWN.
# 600 seconds = 10 minutes (Adjust based on your boot speed)
sed -i 's|^ResumeTimeout=.*|ResumeTimeout=600|' /etc/slurm/slurm.conf

systemctl restart slurmctld