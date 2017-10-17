apt-get install --no-install-recommends -q -y --force-yes curl
apt-get install --no-install-recommends -q -y --force-yes ansible
#echo "clouder        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

