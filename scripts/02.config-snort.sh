#!/bin/bash 

source functions.sh

eth0_address=`/sbin/ifconfig eth0 | awk '/inet addr/ {print $2}' | cut -f2 -d ":" `
eth0_ip_range=`route -n  | awk '/eth0/ {print $1}'`
eth0_subnetmask=`ip a | grep eth0 | awk '/inet/ {print $2}' | cut -f2 -d "/"`

sudo groupadd snort
sudo useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort


echocolor "Creat folder for Snort"
# Create the Snort directories:
sudo mkdir /etc/snort
sudo mkdir /etc/snort/rules
sudo mkdir /etc/snort/rules/iplists
sudo mkdir /etc/snort/preproc_rules
sudo mkdir /usr/local/lib/snort_dynamicrules
sudo mkdir /etc/snort/so_rules
 
# Create some files that stores rules and ip lists
sudo touch /etc/snort/rules/iplists/black_list.rules
sudo touch /etc/snort/rules/iplists/white_list.rules
sudo touch /etc/snort/rules/local.rules
sudo touch /etc/snort/sid-msg.map
 
# Create our logging directories:
sudo mkdir /var/log/snort
sudo mkdir /var/log/snort/archived_logs
 
# Adjust permissions:
sudo chmod -R 5775 /etc/snort
sudo chmod -R 5775 /var/log/snort
sudo chmod -R 5775 /var/log/snort/archived_logs
sudo chmod -R 5775 /etc/snort/so_rules
sudo chmod -R 5775 /usr/local/lib/snort_dynamicrules
 
# Change Ownership on folders:
sudo chown -R snort:snort /etc/snort
sudo chown -R snort:snort /var/log/snort
sudo chown -R snort:snort /usr/local/lib/snort_dynamicrules

echocolor "Moving file default for snort"
sleep 3
cd ~/snort_src/snort-2.9.8.3/etc/
sudo cp *.conf* /etc/snort
sudo cp *.map /etc/snort
sudo cp *.dtd /etc/snort
 
cd ~/snort_src/snort-2.9.8.3/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor/
sudo cp * /usr/local/lib/snort_dynamicpreprocessor/
cd ~/snort_src


echocolor "Config file for snort"
sleep 3
cp /etc/snort/snort.conf /etc/snort/snort.conf.orig
sudo sed -i 's/include \$RULE\_PATH/#include \$RULE\_PATH/' /etc/snort/snort.conf
sudo sed -e "s/ipvar HOME_NET any/ipvar HOME_NET $eth0_ip_range\/$eth0_subnetmask/g" /etc/snort/snort.conf
sudo sed -i 's/var RULE_PATH ..\/rules/var RULE_PATH \/etc\/snort\/rules/g' /etc/snort/snort.conf
sudo sed -i 's/var SO_RULE_PATH ..\/so_rules/var SO_RULE_PATH \/etc\/snort\/so_rules/g' /etc/snort/snort.conf
sudo sed -i 's/var PREPROC_RULE_PATH ..\/preproc_rules/var PREPROC_RULE_PATH \/etc\/snort\/preproc_rules/g' /etc/snort/snort.conf
sudo sed -i 's/var WHITE_LIST_PATH ..\/rules/var WHITE_LIST_PATH \/etc\/snort\/rules\/iplists/g' /etc/snort/snort.conf
sudo sed -i 's/var BLACK_LIST_PATH ..\/rules/var BLACK_LIST_PATH \/etc\/snort\/rules\/iplists/g' /etc/snort/snort.conf
sudo sed -i 's/#include \$RULE_PATH\/local.rules/include \$RULE_PATH\/local.rules/g' /etc/snort/snort.conf


echocolor "Check snort"
sleep 3
sudo snort -T -c /etc/snort/snort.conf -i eth0


echocolor "Config rule basic"
sleep 3
cat <<EOF > /etc/snort/rules/local.rules
alert icmp any any -> \$HOME_NET any (msg:"ICMP test detected"; GID:1; sid:10000001; rev:001; classtype:icmp-event;)
EOF


echocolor "Test the configuration file again"
sudo snort -T -c /etc/snort/snort.conf -i eth0