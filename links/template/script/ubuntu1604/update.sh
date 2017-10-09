#!/bin/bash -eux

# Disable the release upgrader
echo "==> Disabling the release upgrader"
sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

# echo "==> Updating list of repositories"
# sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
# avoiding hashchecksum error. 
rm -rf /var/lib/apt/lists/*

# apt-get update does not actually perform updates, it just downloads and indexes the list of packages
apt-get -y update
apt-get -y upgrade
# we need network-manager for supporting multiple networking auto-configuration. 
apt-get install -y network-manager

if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "==> Performing dist-upgrade (all packages and kernel)"
    apt-get -y dist-upgrade --force-yes
    reboot
    sleep 60
fi
