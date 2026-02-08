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

#3 Install OpenHPC Components
#3.1 Enable OpenHPC repository for local use

dnf install -y http://repos.openhpc.community/OpenHPC/4/EL_10/x86_64/ohpc-release-4-1.el10.x86_64.rpm

dnf install -y dnf-plugins-core
dnf config-manager --set-enabled crb

#3.3 Add provisioning services on master node

# Install base meta-packages
dnf -y install ohpc-base
dnf -y install warewulf-ohpc
dnf -y install hwloc-ohpc

systemctl enable chronyd.service
if ! grep -qF ${ntp_server} /etc/chrony.conf; then
    echo "local stratum 10" >> /etc/chrony.conf
    echo "server ${ntp_server}" >> /etc/chrony.conf
    echo "allow all" >> /etc/chrony.conf
fi
systemctl restart chronyd

#3.4 Add resource management services on master node

# Install slurm server meta-package
dnf -y install ohpc-slurm-server

# Use ohpc-provided file for starting SLURM configuration
cp /etc/slurm/slurm.conf.ohpc /etc/slurm/slurm.conf
# Setup default cgroups file
cp /etc/slurm/cgroup.conf.example /etc/slurm/cgroup.conf


# Identify resource manager hostname on master host
sed -i -E "s|^[[:space:]]*?[[:space:]]*SlurmctldHost=.*|SlurmctldHost=${sms_name}|" /etc/slurm/slurm.conf
hostnamectl set-hostname ${sms_name}

# Configuración de Topologia, CPUs, Memoria
sed -i -E "s|^[[:space:]]*?[[:space:]]*NodeName=.*|NodeName=${compute_prefix}[1-${num_computes}] RealMemory=${real_memory} Sockets=${sockets} CoresPerSocket=${cores_per_socket} ThreadsPerCore=${threads_per_core} State=UNKNOWN|" /etc/slurm/slurm.conf

# Configuración de los nombres de los nodos de cómputo
sed -i -E "s|^[[:space:]]*?[[:space:]]*PartitionName=.*|PartitionName=normal Nodes=${compute_prefix}[1-${num_computes}] Default=YES MaxTime=INFINITE State=UP Oversubscribe=NO|" /etc/slurm/slurm.conf
#3.7 Complete basic warewulf setup for master node

# Configure Warewulf provisioning to use desired internal interface
sed -i -E "s|^[[:space:]]*?[[:space:]]*ipaddr:.*|ipaddr: ${sms_ip}|" /etc/warewulf/warewulf.conf
sed -i -E "s|^[[:space:]]*?[[:space:]]*netmask:.*|netmask: ${internal_netmask}|" /etc/warewulf/warewulf.conf
sed -i -E "s|^[[:space:]]*?[[:space:]]*network:.*|network: ${internal_ip}|" /etc/warewulf/warewulf.conf
# dhcp config
sed -i -E "s|^[[:space:]]*?[[:space:]]*range start:.*|    range start: ${sms_dhcp_start}|" /etc/warewulf/warewulf.conf
sed -i -E "s|^[[:space:]]*?[[:space:]]*range end:.*|    range end: ${sms_dhcp_end}|" /etc/warewulf/warewulf.conf
# Enable internal interface for provisioning
ip link set dev ${sms_eth_internal} up
ip address add ${sms_ip}/${internal_netmask} broadcast + dev ${sms_eth_internal}

dnf -y install httpd 
dnf -y install dnsmasq

# Restart/enable relevant services to support provisioning
systemctl enable --now httpd
# 2. Enable dnsmasq (Handles DHCP + TFTP)
systemctl enable --now dnsmasq

#3.8 Define compute image for provisioning

#3.8.1 build initial BOS image

# Build initial chroot image
wwctl container import docker://rockylinux/rockylinux:10.1-minimal --force rocky-10.1
CHROOT=$(wwctl container show rocky-10.1)

# Enable OpenHPC and EPEL repos inside chroot
wwctl container exec rocky-10.1 /bin/bash <<EOF
microdnf -y install dnf
dnf -y install epel-release
EOF

cp -p /etc/yum.repos.d/OpenHPC*.repo $CHROOT/etc/yum.repos.d
\cp -f -p /etc/pki/rpm-gpg/RPM-GPG-KEY-OpenHPC* $CHROOT/etc/pki/rpm-gpg
#3.8.2 Add OpenHPC components

# Install compute node base meta-package
wwctl container exec rocky-10.1 /bin/bash <<EOF
dnf -y install ohpc-base-compute
EOF
cp -p /etc/resolv.conf $CHROOT/etc/resolv.conf

# copy credential files into $CHROOT to ensure consistent uid/gids for slurm/munge at
# install. Note that these will be synchronized with future updates via the provisioning system.
\cp -f /etc/passwd /etc/group $CHROOT/etc

# Add Slurm client support meta-package and enable munge and slurmd
wwctl container exec rocky-10.1 /bin/bash <<EOF
dnf -y install ohpc-slurm-client
systemctl enable munge
systemctl enable slurmd
EOF

# Register Slurm server with computes (using "configless" option)
echo SLURMD_OPTIONS="--conf-server ${sms_ip}" > $CHROOT/etc/sysconfig/slurmd

# Add Network Time Protocol (NTP) support
wwctl container exec rocky-10.1 /bin/bash <<EOF
dnf -y install chrony
EOF
# Identify master host as local NTP server
echo "server ${sms_ip} iburst" >> $CHROOT/etc/chrony.conf

# Add kernel drivers (matching kernel version on SMS node)
wwctl container exec rocky-10.1 /bin/bash <<EOF
dnf -y install kernel-`uname -r`

# Include modules user environment
dnf -y install lmod-ohpc
EOF
# 3.8.3 Customize system configuration

# Initialize warewulf database and ssh_keys
wwctl configure ssh

# Add NFS client mounts of /home and /opt/ohpc/pub to base image
echo "${sms_ip}:/home /home nfs nfsvers=4,nodev,nosuid 0 0" >> $CHROOT/etc/fstab
echo "${sms_ip}:/opt /opt nfs nfsvers=4,nodev 0 0" >> $CHROOT/etc/fstab

# Finalize NFS config and restart
exportfs -a
systemctl restart nfs-server
systemctl enable nfs-server

#3.8.4 Additional Customization (optional)

#3.8.4.7 Enable forwarding of system logs

# Configure SMS to receive messages and reload rsyslog configuration
echo 'module(load="imudp")' >> /etc/rsyslog.d/ohpc.conf
echo 'input(type="imudp" port="514")' >> /etc/rsyslog.d/ohpc.conf
systemctl restart rsyslog

# Define compute node forwarding destination
echo "*.* @${sms_ip}:514" >> $CHROOT/etc/rsyslog.conf
echo "Target=\"${sms_ip}\" Protocol=\"udp\"" >> $CHROOT/etc/rsyslog.conf

# Disable most local logging on computes. Emergency and boot logs will remain on the compute nodes
sed -i 's/^\*\.info/#*\.info/' $CHROOT/etc/rsyslog.conf
sed -i 's/^authpriv/#authpriv/' $CHROOT/etc/rsyslog.conf
sed -i 's/^mail/#mail/' $CHROOT/etc/rsyslog.conf
sed -i 's/^cron/#cron/' $CHROOT/etc/rsyslog.conf
sed -i 's/^uucp/#uucp/' $CHROOT/etc/rsyslog.conf

#3.8.4.8 Add ClusterShell

# Install ClusterShell
dnf -y install clustershell

# Setup node definitions
cd /etc/clustershell/groups.d
mv local.cfg local.cfg.orig
echo "adm: ${sms_name}" > local.cfg
echo "compute: ${compute_prefix}[1-${num_computes}]" >> local.cfg
echo "all: @adm,@compute" >> local.cfg

#3.8.4.9 Add genders

# Install genders
dnf -y install genders-ohpc

# Generate a sample genders file
echo -e "${sms_name}\tsms" > /etc/genders

#3.8.4.12 Add NHC

# Install NHC on master and compute nodes
dnf -y install nhc-ohpc
dnf -y --installroot=$CHROOT install nhc-ohpc

# Register as SLURM's health check program
echo "HealthCheckProgram=/usr/sbin/nhc" >> /etc/slurm/slurm.conf
echo "HealthCheckInterval=${nhc_healtcheck_interval}" >> /etc/slurm/slurm.conf

#3.8.5 Import files
wwctl overlay mkdir munge /etc/munge
wwctl overlay import munge /etc/passwd
wwctl overlay import munge /etc/group
wwctl overlay import munge /etc/shadow
wwctl overlay import munge /etc/munge/munge.key

# Set file permissions to 400 (Read-only by owner)
wwctl overlay chmod munge /etc/munge/munge.key 0400

# Set ownership to munge user (Check your container for the correct UID/GID)
# Assuming 'munge' is the user, Warewulf often handles names, but UIDs are safer.
MUNGE_UID=$(awk -F: '/^munge:/ {print $3}' /etc/passwd)
MUNGE_GID=$(awk -F: '/^munge:/ {print $4}' /etc/passwd)
wwctl overlay chown munge /etc/munge/munge.key $MUNGE_UID:$MUNGE_GID

wwctl profile set default --image rocky-10.1 -y
wwctl profile set default --runtime-overlays=munge -y
#3.9 Finalizing provisioning configuration

#3.9.1 Assemble bootstrap image

wwctl container build rocky-10.1

#3.9.3 Register nodes for provisioning

# Add nodes to Warewulf data store
for ((i=0; i<$num_computes; i++)) ; do
    wwctl node add "${c_name[i]}" \
        --netdev "${eth_provision}" \
        --ipaddr "${c_ip[i]}" \
        --hwaddr "${c_mac[i]}" \
        --profile default
done

wwctl profile set default --kernelargs "net.ifnames=1 biosdevname=1" -y
wwctl profile set default --runtime-overlays=syncuser,munge -y
mkdir -p /var/lib/tftpboot
wwctl configure --all

#4 Install OpenHPC Development Components

#4.1 Development Tools

# Install autotools meta-package
dnf -y install ohpc-autotools

dnf -y install EasyBuild-ohpc
dnf -y install hwloc-ohpc
dnf -y install spack-ohpc
dnf -y install valgrind-ohpc

#4.2 Compliers

dnf -y install gnu15-compilers-ohpc

#4.3 MPI Stacks
dnf -y install openmpi5-pmix-gnu15-ohpc mpich-ofi-gnu15-ohpc

#4.4 Performance Tools

# Install perf-tools meta-package
dnf -y install ohpc-gnu15-perf-tools

#4.5 Setup default development environment

dnf -y install lmod-defaults-gnu15-openmpi5-ohpc

#4.6 3rd Party Libraries and Tools

# Install 3rd party libraries/tools meta-packages built with GNU toolchain
dnf -y install ohpc-gnu15-serial-libs
dnf -y install ohpc-gnu15-io-libs
dnf -y install ohpc-gnu15-python-libs
dnf -y install ohpc-gnu15-runtimes

# Install parallel lib meta-packages for all available MPI toolchains
dnf -y install ohpc-gnu15-mpich-parallel-libs
dnf -y install ohpc-gnu15-openmpi5-parallel-libs

#5 Resource Manager Startup
mkdir -p /home/slurm
chown slurm:slurm /home/slurm
sed -i -E "s|^[[:space:]]*?[[:space:]]*SlurmctldLogFile=.*|SlurmctldLogFile=/home/slurm/slurmctld.log|" /etc/slurm/slurm.conf
sed -i -E "s|^[[:space:]]*?[[:space:]]*SlurmdLogFile=.*|SlurmdLogFile=/home/slurm/slurmd.log|" /etc/slurm/slurm.conf

# Start munge and slurm controller on master host
systemctl enable munge
systemctl enable slurmctld
systemctl start munge
systemctl start slurmctld
