#1 Config variables

if [ ! -f /home/admin/variables.config ]; then
    echo "Config file not found!"
    exit
fi

source /home/admin/variables.config


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

# TODO 
# WAIT ROCKY 10 IMAGE TO BE IN DOCKERHUB
# INSTEAD IF MIGRATION TO ROCKY 10 IS NEEDED
# USE CENTOS 10 IMAGE

# Build initial chroot image
wwmkchroot -v rocky-9 $CHROOT

# Enable OpenHPC and EPEL repos inside chroot
dnf -y --installroot $CHROOT install epel-release
cp -p /etc/yum.repos.d/OpenHPC*.repo $CHROOT/etc/yum.repos.d

#3.8.2 Add OpenHPC components

# Install compute node base meta-package
dnf -y --installroot=$CHROOT install ohpc-base-compute
cp -p /etc/resolv.conf $CHROOT/etc/resolv.conf

# copy credential files into $CHROOT to ensure consistent uid/gids for slurm/munge at
# install. Note that these will be synchronized with future updates via the provisioning system.
cp /etc/passwd /etc/group $CHROOT/etc

# Add Slurm client support meta-package and enable munge and slurmd
dnf -y --installroot=$CHROOT install ohpc-slurm-client
chroot $CHROOT systemctl enable munge
chroot $CHROOT systemctl enable slurmd

# Register Slurm server with computes (using "configless" option)
echo SLURMD_OPTIONS="--conf-server ${sms_ip}" > $CHROOT/etc/sysconfig/slurmd

# Add Network Time Protocol (NTP) support
dnf -y --installroot=$CHROOT install chrony
# Identify master host as local NTP server
echo "server ${sms_ip} iburst" >> $CHROOT/etc/chrony.conf

# Add kernel drivers (matching kernel version on SMS node)
dnf -y --installroot=$CHROOT install kernel-`uname -r`

# Include modules user environment
dnf -y --installroot=$CHROOT install lmod-ohpc

# 3.8.3 Customize system configuration

# Initialize warewulf database and ssh_keys
wwinit database
wwinit ssh_keys

# Add NFS client mounts of /home and /opt/ohpc/pub to base image
echo "${sms_ip}:/home /home nfs nfsvers=4,nodev,nosuid 0 0" >> $CHROOT/etc/fstab
echo "${sms_ip}:/opt/ohpc/pub /opt/ohpc/pub nfs nfsvers=4,nodev 0 0" >> $CHROOT/etc/fstab

# Export /home and OpenHPC public packages from master server
echo "/home *(rw,no_subtree_check,fsid=10,no_root_squash)" >> /etc/exports
echo "/opt/ohpc/pub *(ro,no_subtree_check,fsid=11)" >> /etc/exports

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
perl -pi -e "s/^\*\.info/\\#\*\.info/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^authpriv/\\#authpriv/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^mail/\\#mail/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^cron/\\#cron/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^uucp/\\#uucp/" $CHROOT/etc/rsyslog.conf

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

wwsh file import /etc/passwd
wwsh file import /etc/group
wwsh file import /etc/shadow

wwsh file import /etc/munge/munge.key

#3.9 Finalizing provisioning configuration

#3.9.1 Assemble bootstrap image

# Build bootstrap image
wwbootstrap `uname -r`

#3.9.2 Assemble Virtual Node File System (VNFS) image
wwvnfs --chroot $CHROOT

#3.9.3 Register nodes for provisioning

# Set provisioning interface as the default networking device
echo "GATEWAYDEV=${eth_provision}" > /tmp/network.$$
wwsh -y file import /tmp/network.$$ --name network
wwsh -y file set network --path /etc/sysconfig/network --mode=0644 --uid=0

# Add nodes to Warewulf data store
for ((i=0; i<$num_computes; i++)) ; do
    wwsh -y node new ${c_name[i]} --ipaddr=${c_ip[i]} --hwaddr=${c_mac[i]} -D ${eth_provision}
done

# Additional step required if desiring to use predictable network interface
# naming schemes (e.g. en4s0f0). Skip if using eth# style names.
export kargs="${kargs} net.ifnames=1,biosdevname=1"
wwsh -y provision set --postnetdown=1 "${compute_regex}"

# Define provisioning image for hosts
wwsh -y provision set "${compute_regex}" --vnfs=rocky9.6 --bootstrap=`uname -r` \
--files=dynamic_hosts,passwd,group,shadow,munge.key,network

# Restart dhcp / update PXE
systemctl restart dhcpd
wwsh pxe update

#4 Install OpenHPC Development Components

#4.1 Development Tools

# Install autotools meta-package
dnf -y install ohpc-autotools

dnf -y install EasyBuild-ohpc
dnf -y install hwloc-ohpc
dnf -y install spack-ohpc
dnf -y install valgrind-ohpc

#4.2 Compliers

dnf -y install gnu13-compilers-ohpc

#4.3 MPI Stacks
dnf -y install openmpi5-pmix-gnu13-ohpc mpich-ofi-gnu13-ohpc

#4.4 Performance Tools

# Install perf-tools meta-package
dnf -y install ohpc-gnu13-perf-tools

#4.5 Setup default development environment

dnf -y install lmod-defaults-gnu13-openmpi5-ohpc

#4.6 3rd Party Libraries and Tools

# Install 3rd party libraries/tools meta-packages built with GNU toolchain
dnf -y install ohpc-gnu13-serial-libs
dnf -y install ohpc-gnu13-io-libs
dnf -y install ohpc-gnu13-python-libs
dnf -y install ohpc-gnu13-runtimes

# Install parallel lib meta-packages for all available MPI toolchains
dnf -y install ohpc-gnu13-mpich-parallel-libs
dnf -y install ohpc-gnu13-openmpi5-parallel-libs

#5 Resource Manager Startup

# Start munge and slurm controller on master host
systemctl enable munge
systemctl enable slurmctld
systemctl start munge
systemctl start slurmctld
