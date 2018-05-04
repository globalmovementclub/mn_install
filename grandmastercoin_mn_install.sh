#!/bin/bash
#
# Copyright (C) 2018 GrandMasterCoin Team
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

# Only Ubuntu 16.04 supported at this moment.

set -o errexit

# OS_VERSION_ID=`gawk -F= '/^VERSION_ID/{print $2}' /etc/os-release | tr -d '"'`

sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl wget git python3 python3-pip python-virtualenv -y

GMC_DAEMON_USER_PASS=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo ""`
GMC_DAEMON_RPC_PASS=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 ; echo ""`
MN_NAME_PREFIX=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6 ; echo ""`
MN_EXTERNAL_IP=`curl -s ifconfig.co`

sudo useradd -U -m grandmastercoin -s /bin/bash
echo "grandmastercoin:${GMC_DAEMON_USER_PASS}" | sudo chpasswd
sudo wget https://github.com/grandmastercoin/grandmastercoin/releases/download/v0.7.5.1/grandmastercoin-0.7.5.1-cli-linux.tar.gz --directory-prefix /home/grandmastercoin/
sudo tar -xzvf /home/grandmastercoin/grandmastercoin-0.7.5.1-cli-linux.tar.gz -C /home/grandmastercoin/
sudo rm /home/grandmastercoin/grandmastercoin-0.7.5.1-cli-linux.tar.gz
sudo mkdir /home/grandmastercoin/.grandmastercoincore/
sudo chown -R grandmastercoin:grandmastercoin /home/grandmastercoin/grandmastercoin*
sudo chmod 755 /home/grandmastercoin/grandmastercoin*
echo -e "rpcuser=grandmastercoinrpc\nrpcpassword=${GMC_DAEMON_RPC_PASS}\nlisten=1\nserver=1\nrpcallowip=127.0.0.1\nmaxconnections=256" | sudo tee /home/grandmastercoin/.grandmastercoincore/grandmastercoin.conf
sudo chown -R grandmastercoin:grandmastercoin /home/grandmastercoin/.grandmastercoincore/
sudo chown 500 /home/grandmastercoin/.grandmastercoincore/grandmastercoin.conf

sudo tee /etc/systemd/system/grandmastercoin.service <<EOF
[Unit]
Description=GrandMasterCoin, distributed currency daemon
After=network.target

[Service]
User=grandmastercoin
Group=grandmastercoin
WorkingDirectory=/home/grandmastercoin/
ExecStart=/home/grandmastercoin/grandmastercoind

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=2s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable grandmastercoin
sudo systemctl start grandmastercoin
echo "Booting GMC node and creating keypool"
sleep 120

MNGENKEY=`sudo -H -u grandmastercoin /home/grandmastercoin/grandmastercoin-cli masternode genkey`
echo -e "masternode=1\nmasternodeprivkey=${MNGENKEY}\nexternalip=${MN_EXTERNAL_IP}:3234" | sudo tee -a /home/grandmastercoin/.grandmastercoincore/grandmastercoin.conf
sudo systemctl restart grandmastercoin

echo "Installing sentinel engine"
sudo git clone https://github.com/grandmastercoin/sentinel.git /home/grandmastercoin/sentinel/
sudo chown -R grandmastercoin:grandmastercoin /home/grandmastercoin/sentinel/
cd /home/grandmastercoin/sentinel/
sudo -H -u grandmastercoin virtualenv -p python3 ./venv
sudo -H -u grandmastercoin ./venv/bin/pip install -r requirements.txt
echo "* * * * * grandmastercoin cd /home/grandmastercoin/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" | sudo tee /etc/cron.d/grandmastercoin_sentinel
sudo chmod 644 /etc/cron.d/grandmastercoin_sentinel

echo " "
echo " "
echo "==============================="
echo "Masternode installed!"
echo "==============================="
echo "Copy and keep that information in secret:"
echo "Masternode key: ${MNGENKEY}"
echo "SSH password for user \"grandmastercoin\": ${GMC_DAEMON_USER_PASS}"
echo "Prepared masternode.conf string:"
echo "mn_${MN_NAME_PREFIX} ${MN_EXTERNAL_IP}:3234 ${MNGENKEY} INPUTTX INPUTINDEX"

exit 0
