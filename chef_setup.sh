#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | tee /etc/apt/sources.list.d/opscode.list
mkdir -p /etc/apt/trusted.gpg.d
gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
apt-get update
apt-get install opscode-keyring -y
#apt-get upgrade -y
#sudo apt-get install chef chef-server -y