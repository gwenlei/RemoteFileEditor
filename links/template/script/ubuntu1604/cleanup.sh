#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-vagrant}

# Make sure udev does not block our network - http://6.ptmc.org/?p=164
echo "==> Cleaning up udev rules"
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "==> Cleaning up leftover dhcp leases"
# Ubuntu 10.04
if [ -d "/var/lib/dhcp3" ]; then
    rm /var/lib/dhcp3/*
fi
# Ubuntu 12.04 & 14.04
if [ -d "/var/lib/dhcp" ]; then
    rm /var/lib/dhcp/*
fi 

UBUNTU_VERSION=$(lsb_release -sr)
if [[ ${UBUNTU_VERSION} == 16.04 ]]; then
    # from https://github.com/cbednarski/packer-ubuntu/blob/master/scripts-1604/vm_cleanup.sh#L9-L15
    # When booting with Vagrant / VMware the PCI slot is changed from 33 to 32.
    # Instead of eth0 the interface is now called ens33 to mach the PCI slot,
    # so we need to change the networking scripts to enable the correct
    # interface.
    #
    # NOTE: After the machine is rebooted Packer will not be able to reconnect
    # (Vagrant will be able to) so make sure this is done in your final
    # provisioner.
    sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/' /etc/default/grub
    update-grub
    sed -i "s/ens33/ens32/g" /etc/network/interfaces
    sed -i "s/ens33/eth0/g" /etc/network/interfaces
    sed -i "s/ens3/eth0/g" /etc/network/interfaces
fi

# Fix bug, no hvc0, then you won't get tty1 working under vnc
if [[ ${UBUNTU_VERSION} == 12.04 ]]; then
    echo 'start on stopped rc RUNLEVEL=[2345] and (' > /etc/init/hvc0.conf
    echo 'not-container or' >> /etc/init/hvc0.conf
    echo 'container CONTAINER=lxc or' >> /etc/init/hvc0.conf
    echo 'container CONTAINER=lxc-libvirt)' >> /etc/init/hvc0.conf
    echo 'stop on runlevel [!2345]' >> /etc/init/hvc0.conf
    echo 'respawn' >> /etc/init/hvc0.conf
    echo 'exec /sbin/getty -L hvc0 9600 linux' >> /etc/init/hvc0.conf
fi


# Fixed bug, for ubuntu14.04 won't add auto eth0 in building.
#if [[ ${UBUNTU_VERSION} == 14.04 ]]; then
#    # Add eth0 autoconfiguration into /etc/network/interfaces
#    sudo echo "auto eth0">>/etc/network/interfaces
#    sudo echo "iface eth0 inet dhcp">>/etc/network/interfaces
#fi

# Add delay to prevent "vagrant reload" from failing
echo "pre-up sleep 2" >> /etc/network/interfaces

echo "==> Cleaning up tmp"
rm -rf /tmp/*

# Cleanup apt cache
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean
# Remove the proxy configuration
>/etc/apt/apt.conf

echo "==> Installed packages"
dpkg --get-selections | grep -v deinstall

DISK_USAGE_BEFORE_CLEANUP=$(df -h)

# Remove Bash history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/${SSH_USER}/.bash_history

# Clean up log files
find /var/log -type f | while read f; do echo -ne '' > $f; done;

echo "==> Clearing last login information"
>/var/log/lastlog
>/var/log/wtmp
>/var/log/btmp

# Whiteout root
count=$(df --sync -kP / | tail -n1  | awk -F ' ' '{print $4}')
let count--
dd if=/dev/zero of=/tmp/whitespace bs=1024 count=$count
rm /tmp/whitespace

# Whiteout /boot
count=$(df --sync -kP /boot | tail -n1 | awk -F ' ' '{print $4}')
let count--
dd if=/dev/zero of=/boot/whitespace bs=1024 count=$count
rm /boot/whitespace

echo '==> Clear out swap and disable until reboot'
set +e
swapuuid=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
case "$?" in
    2|0) ;;
    *) exit 1 ;;
esac
set -e
if [ "x${swapuuid}" != "x" ]; then
    # Whiteout the swap partition to reduce box size
    # Swap is disabled till reboot
    swappart=$(readlink -f /dev/disk/by-uuid/$swapuuid)
    /sbin/swapoff "${swappart}"
    dd if=/dev/zero of="${swappart}" bs=1M || echo "dd exit code $? is suppressed"
    /sbin/mkswap -U "${swapuuid}" "${swappart}"
fi

# Zero out the free space to save space in the final image
#dd if=/dev/zero of=/EMPTY bs=1M  || echo "dd exit code $? is suppressed"
#rm -f /EMPTY

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quite too early before the large files are deleted
sync

echo "==> Disk usage before cleanup"
echo ${DISK_USAGE_BEFORE_CLEANUP}

echo "==> Disk usage after cleanup"
df -h
