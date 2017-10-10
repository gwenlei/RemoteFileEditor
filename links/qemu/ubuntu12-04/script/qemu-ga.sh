#sudo apt-get install --no-install-recommends -q -y --force-yes openssh*
sudo apt-get install --no-install-recommends -q -y --force-yes wget
sudo apt-get install --no-install-recommends -q -y --force-yes whois
#wget http://192.168.0.82/downloads/qemu-guest-agent_2.0.0~rc1+dfsg-0ubuntu3_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/q/qemu/qemu-guest-agent_2.0.0~rc1+dfsg-0ubuntu3_amd64.deb
sudo dpkg -i qemu-guest-agent_2.0.0~rc1+dfsg-0ubuntu3_amd64.deb
#wget http://192.168.0.82/downloads/cloud-set-guest-password.in
wget http://download.cloud.com/templates/4.2/bindir/cloud-set-guest-password.in
sudo mv cloud-set-guest-password.in /etc/init.d/cloud-set-guest-password
sudo chmod +x /etc/init.d/cloud-set-guest-password
sudo update-rc.d cloud-set-guest-password defaults 98
sudo apt-get install -y network-manager
sudo echo "manual" | sudo tee /etc/init/network-manager.override
sudo /bin/sed -i "\$i sudo start network-manager" /etc/rc.local
