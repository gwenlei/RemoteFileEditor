sudo apt-get update
export DEBIAN_FRONTEND="noninteractive"
#sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password engine'
#sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password engine'
sudo apt-get install --no-install-recommends -q -y --force-yes mysql-server 
#mysql_secure_installation
