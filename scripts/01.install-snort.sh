#!/bin/bash 

source functions.sh

echocolor "Update package for OS"
apt-get -y update

echocolor "Installing package"
sleep 3
sudo apt-get install -y build-essential libpcap-dev \
    libpcre3-dev libdumbnet-dev bison flex zlib1g-dev liblzma-dev openssl libssl-dev    
sudo apt-get install -y ethtool

echocolor "Config network"
sleep 3
cp /etc/network/interfaces /etc/network/interfaces.orig
cat << EOF > /etc/network/interfaces

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
source /etc/network/interfaces.d/*
# The loopback network interface
auto lo
iface lo inet loopback
# The primary network interface
auto eth0
iface eth0 inet dhcp
post-up ethtool -K eth0 gro off
post-up ethtool -K eth0 lro off

auto eth1
iface eth1 inet dhcp
EOF


echocolor "Restart networking service"
sleep 3
ifdown -a && ifup -a 

echo "Check LRO & GRO"
sleep 3
ethtool -k eth0 | grep receive-offload


echocolor "Make folder install Snort"
sleep 3
mkdir ~/snort_src
cd ~/snort_src

echocolor "Download DAQ package"
sleep 3
cd ~/snort_src
wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz
tar -xvzf daq-2.0.6.tar.gz
cd daq-2.0.6
./configure
make
sudo make install

echocolor "Download Snort package"
sleep 3
cd ~/snort_src
wget https://snort.org/downloads/snort/snort-2.9.8.3.tar.gz
tar -xvzf snort-2.9.8.3.tar.gz
cd snort-2.9.8.3
./configure --enable-sourcefire
make
sudo make install

echocolor "Config snort"
sleep 3
sudo ldconfig
sudo ln -s /usr/local/bin/snort /usr/sbin/snort

echocolor "Check version snort"
sleep 3
snort -V
