yum install -y -q wget
yum install -y -q expect
wget http://download.cloud.com/templates/4.2/bindir/cloud-set-guest-password.in
mv cloud-set-guest-password.in /etc/init.d/cloud-set-guest-password
chmod +x /etc/init.d/cloud-set-guest-password
chkconfig --add cloud-set-guest-password
yum update openssh*
yum update pam
yum install -y acpid
yum install -y qemu-guest-agent
ln -s /usr/lib/systemd/system/qemu-guest-agent.service /etc/systemd/system/multi-user.target.wants
chkconfig NetworkManager off
