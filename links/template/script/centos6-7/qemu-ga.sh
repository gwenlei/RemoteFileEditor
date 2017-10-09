yum install -y -q qemu-guest-agent
yum install -y -q openssh*
yum install -y -q pam
yum install -y -q acpid
yum install -y -q wget
yum install -y -q expect
#wget http://192.168.0.82/downloads/cloud-set-guest-password.in 
wget http://download.cloud.com/templates/4.2/bindir/cloud-set-guest-password.in
mv cloud-set-guest-password.in /etc/init.d/cloud-set-guest-password
chmod +x /etc/init.d/cloud-set-guest-password
chkconfig --add cloud-set-guest-password

