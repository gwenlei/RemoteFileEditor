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
