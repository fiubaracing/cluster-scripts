#!/bin/bash

#1 Config variables
if [ ! -f /home/admin/variables.config ]; then
    echo "Config file not found!"
    exit
fi

source /home/admin/variables.config
set -e

#2 Install Base Operating System (BOS)
if ! grep -qF ${sms_name} /etc/hosts; then
    echo ${sms_ip} ${sms_name} >> /etc/hosts
fi

systemctl disable firewalld
systemctl stop firewalld

#3 Install OpenHPC 3 Components (Native x86-64-v2 Support)
dnf -y install epel-release
dnf install -y http://repos.openhpc.community/OpenHPC/3/EL_9/x86_64/ohpc-release-3-1.el9.x86_64.rpm
dnf install -y dnf-plugins-core
dnf config-manager --set-enabled crb

#3.3 Add provisioning services on master node
# Note: warewulf-ohpc in OHPC 3 is Warewulf 4!
dnf -y install ohpc-base
dnf -y install warewulf-ohpc
dnf -y install hwloc-ohpc dhcp-server tftp-server nfs-utils

systemctl enable chronyd.service
if ! grep -qF ${ntp_server} /etc/chrony.conf; then
    echo "local stratum 10" >> /etc/chrony.conf
    echo "server ${ntp_server}" >> /etc/chrony.conf
    echo "allow all" >> /etc/chrony.conf
fi
systemctl restart chronyd

#3.4 Add resource management services on master node
dnf -y install ohpc-slurm-server
cp /etc/slurm/slurm.conf.ohpc /etc/slurm/slurm.conf
cp /etc/slurm/cgroup.conf.example /etc/slurm/cgroup.conf

# Identify resource manager hostname on master host
sed -i -E "s|^[[:space:]]*?[[:space:]]*SlurmctldHost=.*|SlurmctldHost=${sms_name}|" /etc/slurm/slurm.conf
hostnamectl set-hostname ${sms_name}

node_string=$(IFS=,; echo "${c_name[*]}")

# Configure Topology, CPUs, Memory, and Node Names
sed -i -E "s|^[[:space:]]*?[[:space:]]*NodeName=.*|NodeName=${node_string} RealMemory=${real_memory} Sockets=${sockets} CoresPerSocket=${cores_per_socket} ThreadsPerCore=${threads_per_core} State=UNKNOWN|" /etc/slurm/slurm.conf
sed -i -E "s|^[[:space:]]*?[[:space:]]*PartitionName=.*|PartitionName=normal Nodes=${node_string} Default=YES MaxTime=INFINITE State=UP Oversubscribe=NO|" /etc/slurm/slurm.conf

# Configure Warewulf provisioning (Warewulf 4.7 structure)
sed -i -E "s/^ipaddr:.*/ipaddr: ${sms_ip}/" /etc/warewulf/warewulf.conf
sed -i -E "s/^netmask:.*/netmask: ${internal_netmask}/" /etc/warewulf/warewulf.conf
sed -i -E "s/^network:.*/network: ${internal_ip}/" /etc/warewulf/warewulf.conf

# Preserve indentation for nested DHCP range settings
sed -i -E "s/^([[:space:]]+)range start:.*/\1range start: ${sms_dhcp_start}/" /etc/warewulf/warewulf.conf
sed -i -E "s/^([[:space:]]+)range end:.*/\1range end: ${sms_dhcp_end}/" /etc/warewulf/warewulf.conf

if ! nmcli connection show "${sms_eth_internal}" > /dev/null 2>&1; then
    nmcli connection add type ethernet ifname "${sms_eth_internal}" con-name "${sms_eth_internal}" ipv4.addresses "${sms_ip}/${internal_netmask_cidr}" ipv4.method manual
else
    nmcli connection modify "${sms_eth_internal}" ipv4.addresses "${sms_ip}/${internal_netmask_cidr}" ipv4.method manual
fi
nmcli connection up "${sms_eth_internal}"

systemctl enable --now warewulfd

#3.8 Define compute image for provisioning (Warewulf 4 Method)
wwctl container import docker://rockylinux:9 --force rocky-9
CHROOT=$(wwctl container show rocky-9)

# Configure standard OHPC 3 packages inside the Warewulf 4 container
wwctl container exec rocky-9 /bin/bash <<EOF
dnf -y install epel-release
dnf -y install dnf-plugins-core
dnf config-manager --set-enabled crb
dnf -y install http://repos.openhpc.community/OpenHPC/3/EL_9/x86_64/ohpc-release-3-1.el9.x86_64.rpm
dnf -y install ohpc-base-compute ohpc-slurm-client chrony kernel lmod-ohpc
systemctl enable munge
systemctl enable slurmd
EOF

cp -p /etc/resolv.conf $CHROOT/etc/resolv.conf
\cp -f /etc/passwd /etc/group $CHROOT/etc

# Register Slurm server with computes (using "configless" option)
mkdir -p $CHROOT/etc/sysconfig
echo SLURMD_OPTIONS="--conf-server ${sms_ip}" > $CHROOT/etc/sysconfig/slurmd
echo "server ${sms_ip} iburst" >> $CHROOT/etc/chrony.conf

# Add NFS mounts to compute container
echo "${sms_ip}:/home /home nfs nfsvers=4,nodev,nosuid 0 0" >> $CHROOT/etc/fstab
echo "${sms_ip}:/opt/ohpc/pub /opt/ohpc/pub nfs nfsvers=4,nodev 0 0" >> $CHROOT/etc/fstab

# Export NFS directories from master
echo "/home *(rw,no_subtree_check,fsid=10,no_root_squash)" >> /etc/exports
echo "/opt/ohpc/pub *(ro,no_subtree_check,fsid=11)" >> /etc/exports
exportfs -a
systemctl restart nfs-server
systemctl enable nfs-server

#3.8.4 Customizations
# Rsyslog
echo 'module(load="imudp")' >> /etc/rsyslog.d/ohpc.conf
echo 'input(type="imudp" port="514")' >> /etc/rsyslog.d/ohpc.conf
systemctl restart rsyslog

echo "*.* @${sms_ip}:514" >> $CHROOT/etc/rsyslog.conf
echo "Target=\"${sms_ip}\" Protocol=\"udp\"" >> $CHROOT/etc/rsyslog.conf
sed -i 's/^\*\.info/#*\.info/' $CHROOT/etc/rsyslog.conf
sed -i 's/^authpriv/#authpriv/' $CHROOT/etc/rsyslog.conf
sed -i 's/^mail/#mail/' $CHROOT/etc/rsyslog.conf
sed -i 's/^cron/#cron/' $CHROOT/etc/rsyslog.conf
sed -i 's/^uucp/#uucp/' $CHROOT/etc/rsyslog.conf

# Clustershell
dnf -y install clustershell
cd /etc/clustershell/groups.d
mv local.cfg local.cfg.orig
echo "adm: ${sms_name}" > local.cfg
echo "compute: ${compute_prefix}[1-${num_computes}]" >> local.cfg
echo "all: @adm,@compute" >> local.cfg

# Genders & NHC
dnf -y install genders-ohpc nhc-ohpc
dnf -y --installroot=$CHROOT install nhc-ohpc
echo -e "${sms_name}\tsms" > /etc/genders
echo "HealthCheckProgram=/usr/sbin/nhc" >> /etc/slurm/slurm.conf
echo "HealthCheckInterval=${nhc_healtcheck_interval}" >> /etc/slurm/slurm.conf

# Bypassing deprecated DSA keys (Warewulf 4)
sed -i '/ssh_host_dsa_key/d' /etc/warewulf/warewulf.conf || true
wwctl configure ssh
mkdir -p /var/lib/tftpboot
wwctl configure --all

# Warewulf 4 Munge Overlay
wwctl overlay create munge
wwctl overlay mkdir munge /etc/munge
wwctl overlay import munge /etc/passwd
wwctl overlay import munge /etc/group
wwctl overlay import munge /etc/shadow
wwctl overlay import munge /etc/munge/munge.key
wwctl overlay chmod munge /etc/munge/munge.key 0400

MUNGE_UID=$(awk -F: '/^munge:/ {print $3}' /etc/passwd)
MUNGE_GID=$(awk -F: '/^munge:/ {print $4}' /etc/passwd)
wwctl overlay chown munge /etc/munge/munge.key $MUNGE_UID:$MUNGE_GID

wwctl profile set default --image rocky-9 -y
wwctl profile set default --runtime-overlays=munge -y

#3.9 Register nodes for Warewulf 4 provisioning
for ((i=0; i<$num_computes; i++)) ; do
    wwctl node add "${c_name[i]}" \
        --netdev "${eth_provision}" \
        --ipaddr "${c_ip[i]}" \
        --hwaddr "${c_mac[i]}" \
        --profile default
done

# Synchronize Warewulf database with system files and compile container
wwctl configure --all
wwctl profile set default --kernelargs "net.ifnames=1 biosdevname=1" -y
wwctl profile set default --runtime-overlays=syncuser,munge -y
wwctl container build rocky-9

#4 Install OpenHPC 3 Development Components (GNU 13 / EL9)
dnf -y install ohpc-autotools EasyBuild-ohpc hwloc-ohpc spack-ohpc valgrind-ohpc
dnf -y install gnu13-compilers-ohpc
dnf -y install openmpi5-pmix-gnu13-ohpc mpich-ofi-gnu13-ohpc
dnf -y install ohpc-gnu13-perf-tools
dnf -y install lmod-defaults-gnu13-openmpi5-ohpc
dnf -y install ohpc-gnu13-serial-libs ohpc-gnu13-io-libs ohpc-gnu13-python-libs ohpc-gnu13-runtimes
dnf -y install ohpc-gnu13-mpich-parallel-libs ohpc-gnu13-openmpi5-parallel-libs

#5 Resource Manager Startup
mkdir -p /home/slurm
chown slurm:slurm /home/slurm
sed -i -E "s|^[[:space:]]*?[[:space:]]*SlurmctldLogFile=.*|SlurmctldLogFile=/home/slurm/slurmctld.log|" /etc/slurm/slurm.conf
sed -i -E "s|^[[:space:]]*?[[:space:]]*SlurmdLogFile=.*|SlurmdLogFile=/home/slurm/slurmd.log|" /etc/slurm/slurm.conf

systemctl enable munge
systemctl enable slurmctld
systemctl start munge
systemctl start slurmctld