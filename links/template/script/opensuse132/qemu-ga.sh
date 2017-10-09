# wget http://download.cloud.com/templates/4.2/bindir/cloud-set-guest-password.in
wget http://192.168.0.82/downloads/cloud-set-guest-password.opensuse
mv cloud-set-guest-password.opensuse /etc/init.d/cloud-set-guest-password
chmod +x /etc/init.d/cloud-set-guest-password
chkconfig --add cloud-set-guest-password
zypper mr -d openSUSE-13.2-0
zypper ar -f -c http://download.opensuse.org/tumbleweed/repo/oss repo-oss
zypper ar -f -c http://download.opensuse.org/tumbleweed/repo/non-oss repo-non-oss
zypper -n in --no-recommends   wget
zypper -n in --no-recommends  whois

zypper -n in --no-recommends   openssh*
zypper -n in --no-recommends   pam 

zypper -n in --no-recommends  acpid

cd /root
wget -c http://192.168.0.82/qemu-guest-agent-2.1.3-7.2.x86_64.rpm
rpm -ivh /root/qemu-guest-agent-2.1.3-7.2.x86_64.rpm
echo "qemu-ga -v -p /dev/virtio-ports/org.qemu.guest_agent.0" >> /etc/init.d/after.local
