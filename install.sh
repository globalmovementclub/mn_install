#!/bin/bash
#
# Copyright (C) 2020 GlobalMovementToken Team
#
# mn_install.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# mn_install.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with mn_install.sh. If not, see <http://www.gnu.org/licenses/>
#

# Compatible with Ubuntu 16.04/18.04.

set -o errexit

# OS_VERSION_ID=`gawk -F= '/^VERSION_ID/{print $2}' /etc/os-release | tr -d '"'`

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
sudo apt install curl wget git python3 python3-pip python-virtualenv -y

GMC_DAEMON_USER_PASS=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo ""`
GMC_DAEMON_RPC_PASS=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 ; echo ""`
MN_NAME_PREFIX=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6 ; echo ""`
MN_EXTERNAL_IP=`curl -s -4 https://api.ipify.org/`

sudo useradd -U -m gmc -s /bin/bash
echo "gmc:${GMC_DAEMON_USER_PASS}" | sudo chpasswd
sudo wget https://github.com/globalmovementclub/globalmovementclub/releases/download/v0.7.7.3/globalmovementclub-0.7.7.3-cli-linux.tar.gz --directory-prefix /home/gmc/
sudo tar -xzvf /home/gmc/globalmovementclub-0.7.7.3-cli-linux.tar.gz -C /home/gmc/
sudo rm /home/gmc/globalmovementclub-0.7.7.3-cli-linux.tar.gz
sudo mkdir /home/gmc/.gmc/
sudo chown -R gmc:gmc /home/gmc/gmc*
sudo chmod 755 /home/gmc/gmc*
echo -e "rpcuser=gmcrpc\nrpcpassword=${GMC_DAEMON_RPC_PASS}\nlisten=1\nserver=1\nrpcallowip=127.0.0.1\nmaxconnections=256" | sudo tee /home/gmc/.gmc/gmc.conf
sudo chown -R gmc:gmc /home/gmc/.gmc/
sudo chown 500 /home/gmc/.gmc/gmc.conf

sudo tee /etc/systemd/system/gmc.service <<EOF
[Unit]
Description=GMC, distributed currency daemon
After=network.target

[Service]
User=gmc
Group=gmc
WorkingDirectory=/home/gmc/
ExecStart=/home/gmc/gmcd

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=2s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable gmc
sudo systemctl start gmc
echo "Booting GMC node and creating keypool"
sleep 120

MNGENKEY=`sudo -H -u gmc /home/gmc/gmc-cli masternode genkey`
echo -e "masternode=1\nmasternodeprivkey=${MNGENKEY}\nexternalip=${MN_EXTERNAL_IP}:3234" | sudo tee -a /home/gmc/.gmc/gmc.conf
sudo systemctl restart gmc

echo "Installing sentinel engine"
sudo git clone https://github.com/globalmovementclub/sentinel.git /home/gmc/sentinel/
sudo chown -R gmc:gmc /home/gmc/sentinel/
cd /home/gmc/sentinel/
sudo -H -u gmc virtualenv -p python3 ./venv
sudo -H -u gmc ./venv/bin/pip install -r requirements.txt
echo "* * * * * gmc cd /home/gmc/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" | sudo tee /etc/cron.d/gmc_sentinel
sudo chmod 644 /etc/cron.d/gmc_sentinel

echo " "
echo " "
echo "==============================="
echo "Masternode installed!"
echo "==============================="
echo "Copy and keep that information in secret:"
echo "Masternode key: ${MNGENKEY}"
echo "SSH password for user \"gmc\": ${GMC_DAEMON_USER_PASS}"
echo "Prepared masternode.conf string:"
echo "mn_${MN_NAME_PREFIX} ${MN_EXTERNAL_IP}:3234 ${MNGENKEY} INPUTTX INPUTINDEX"

exit 0
