sudo apt-get install --no-install-recommends -q -y --force-yes qemu-guest-agent
sudo apt-get install --no-install-recommends -q -y --force-yes openssh*
sudo apt-get install --no-install-recommends -q -y --force-yes wget
sudo apt-get install --no-install-recommends -q -y --force-yes whois
wget http://192.168.0.82/downloads/cloud-set-guest-password.in
sudo mv cloud-set-guest-password.in /etc/init.d/cloud-set-guest-password
sudo chmod +x /etc/init.d/cloud-set-guest-password
sudo update-rc.d cloud-set-guest-password defaults 98
sudo ln -s /bin/bash /bin/sh
sudo sed -i "s/PermitRootLogin without-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
sudo apt-get install -y network-manager
sudo echo "manual" | sudo tee /etc/init/network-manager.override
sudo /bin/sed -i "\$i sudo start network-manager" /etc/rc.local
