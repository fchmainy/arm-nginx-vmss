#!/bin/bash

# $1: Controller IP Address
# $2: nginx-repo.crt b64
# $3: nginx-repo.key b64
# $4: Instance Location as defined on the controller
# $5: Gateway Name
# $6: Controller Admin Email Address
# $7: Controller Admin Password
# $8. Controller API Key

CONTROLLER_URL=https://$1:8443/1.4
mkdir -p /etc/ssl/nginx

echo $2  | base64 --decode > /etc/ssl/nginx/nginx-repo.crt
echo $3  | base64 --decode > /etc/ssl/nginx/nginx-repo.key

wget https://nginx.org/keys/nginx_signing.key
wget https://cs.nginx.com/static/keys/nginx_signing.key && sudo apt-key add nginx_signing.key

apt-key add nginx_signing.key
sudo apt-get install apt-transport-https lsb-release ca-certificates wget curl jq gettext vim net-tools 
printf "deb https://plus-pkgs.nginx.com/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/nginx-plus.list

wget -P /etc/apt/apt.conf.d https://cs.nginx.com/static/files/90nginx

sudo apt-get update
sudo apt-get install app-protect

sudo nginx -v

wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/fchmainy/arm-nginx-vmss/main/nginx.conf
mv nginx.conf /etc/nginx/nginx.conf
sudo service nginx start

# ------ Install NGINX Controller Agent
vmName=$(hostname -f)
echo $vmName
CONTROLLER_URL=https://$1
echo $CONTROLLER_URL

# ------ Install NGINX Controller Agent
curl -k -sS -L ${CONTROLLER_URL}/install/controller-agent > install.sh
export API_KEY=$2
echo $API_KEY

CONTROLLER_FQDN=$(awk -F '"' '/controller_fqdn=/ { print $2 }' install.sh)
echo "${1} ${CONTROLLER_FQDN}" > /etc/hosts

sh ./install.sh -l $3 -i $vmName --insecure

# ------- Register to the Controller
# Set the following environment variables
# export CTRL_IP
# export CTRL_FQDN=controller.f5demolab.org
# export CTRL_USERNAME
# export CTRL_PASSWORD
# export LOCATION=aks

export HOSTNAME="$(hostname -f)"
export CTRL_FQDN=$(echo $ENV_CONTROLLER_URL | awk -F'https://' '{print $2}' | awk -F':8443' '{print $1}')

# AUthenticate to controller with credentials in order to get the Session Token
curl -sk -c cookie.txt -X POST --url 'https://'$1'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"$6"'","password": "'"$7"'"}}'

gwExists=$(curl -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$1'/api/v1/services/environments/'$4'/gateways/'$5 --write-out '%{http_code}' --silent --output /dev/null)
wget https://raw.githubusercontent.com/fchmainy/arm-nginx-vmss/main/gateways.json
# if the gateway does not exist, we are creating it, otherwise we add the instance reference to the gateway.
if [ $gwExists -ne 200 ]
then
        envsubst < gateways.json > $vmName.json
else
	curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$1'/api/v1/services/environments/'$4'/gateways/'$5 -o update.json
	jq '.desiredState.ingress.placement.instanceRefs += [{"ref": "/infrastructure/locations/aks/instances/'$HOSTNAME'"}]' update.json > $vmName.json

fi
curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt -X PUT -d @$HOSTNAME.json --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$4'/gateways/'$5

#---------- Remove Agent at VM Destruction -------------

function removeAgent {
    # Authenticate to controller with credentials in order to get the Session Token
    curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -c cookie.txt -X POST --url 'https://'$1'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"$6"'","password": "'"$7"'"}}'
    # 1. Remove the instance from gateway
    curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$1'/api/v1/services/environments/'$4'/gateways/'$5 -o update.json
    jq '.desiredState.ingress.placement.instanceRefs -= [{"ref": "/infrastructure/locations/'$4'/instances/'$HOSTNAME'"}]' update.json > $HOSTNAME.json
    # cat $HOSTNAME.json
    curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt -X PUT -d @$HOSTNAME.json --header 'Content-Type: application/json' --url 'https://'$1'/api/v1/services/environments/'$LOCATION'/gateways/'$5
    # 2. Remove the instance from infrastructure
    curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' -X DELETE --url 'https://'$1'/api/v1/infrastructure/locations/'$4'/instances/'$HOSTNAME

}

trap removeAgent 1 2 3 9 15


#-----------
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt install -y docker-ce

sudo apt update
sudo apt install -y conntrack coreutils curl ebtables ethtool gettext grep gzip iproute2 iptables jq less openssl sed socat tar util-linux wget

# $1: parameters('controllerTarBallURL'),
# $2: parameters('controller_fqdn'), 
# $3: parameters('adminUsername'), 
# $4: parameters('adminPassword'),
# $5: parameters('userEmail'))]"
# $6: parameters('controllerLicense'))]"

wget $1 -O /home/$3/controller.tar.gz
cd /home/$3
tar -xvf controller.tar.gz
chown -R $3 /home/$3/controller-installer

echo 'now installing controller...'
/bin/su -c "/home/$3/controller-installer/install.sh -y --self-signed-cert --non-interactive --tsdb-volume-type local -m localhost -x 25 -g false -b false -l $3 -q $4 -j controller@f5demolab.org -f $2 -t admin -u f5demo -e $5 -p $4" - $3

echo 'licensing controller...'
curl -X POST -sk -H 'Content-Type: application/json' -d '{"credentials": {"type":"BASIC","username":"'$5'","password":"'$4'"}}' https://127.0.0.1/api/v1/platform/login -c cookie.txt
curl -X PUT -b cookie.txt -sk -H "Content-Type: application/json" -d '{"metadata": {"name":"license"},"desiredState":{"content": "'$6'"}}' https://127.0.0.1/api/v1/platform/license