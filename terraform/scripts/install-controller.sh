#!/bin/bash

sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt install -y docker-ce

sudo apt update
sudo apt install -y conntrack coreutils curl ebtables ethtool gettext grep gzip iproute2 iptables jq less openssl sed socat tar util-linux wget

wget $1 -O /home/$3/controller.tar.gz
cd /home/$3
tar -xvf controller.tar.gz
chown -R $3 /home/$3/controller-installer


echo 'now installing controller...'
/home/$3/controller-installer/install.sh -y --self-signed-cert --non-interactive --tsdb-volume-type local -m localhost -x 25 -g false -b false -l $3 -q $4 -j noreply@f5demolabb.org -f $2 -t admin -u f5demo -e $4 -p $5

echo 'licensing controller...'
curl -X POST -sk -H 'Content-Type: application/json' -d '{"credentials": {"type":"BASIC","username":"'$4'","password":"'$5'"}}' https://127.0.0.1/api/v1/platform/login -c cookie.txt
curl -X PUT -b cookie.txt -sk -H "Content-Type: application/json" -d '{"metadata": {"name":"license"},"desiredState":{"content": "'$6'"}}' https://127.0.0.1/api/v1/platform/license
