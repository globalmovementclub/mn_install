#!/bin/bash
# Compatible with Ubuntu 16.04

set -o errexit

sudo systemctl stop grandmastercoin
sudo wget https://github.com/grandmastercoin/grandmastercoin/releases/download/v0.7.6.2/grandmastercoin-0.7.6.2-cli-linux.tar.gz --directory-prefix /home/grandmastercoin/ -O /home/grandmastercoin/grandmastercoin-0.7.6.2-cli-linux.tar.gz
sudo tar -xzvf /home/grandmastercoin/grandmastercoin-0.7.6.2-cli-linux.tar.gz -C /home/grandmastercoin/
sudo chown -R grandmastercoin:grandmastercoin /home/grandmastercoin/grandmastercoin* && sudo chmod 755 /home/grandmastercoin/grandmastercoin*
sudo rm /home/grandmastercoin/grandmastercoin-0.7.6.2-cli-linux.tar.gz
# reset metadata to free maxconnections slots for nodes
# with recent version, as their metadata are not compatible
sudo rm /home/grandmastercoin/.grandmastercoincore/mncache.dat
sudo rm /home/grandmastercoin/.grandmastercoincore/mnpayments.dat
sudo rm /home/grandmastercoin/.grandmastercoincore/peers.dat
sudo systemctl start grandmastercoin

echo "Masternode upgrade complete!"
