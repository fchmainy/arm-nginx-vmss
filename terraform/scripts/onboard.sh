#!/bin/bash

# Have a controller up and running. Create location and environment.
# $1: Controller IP Address
# $2: Controller Admin Email Address
# $3: Controller Admin Password
# $4: Instance Location as defined on the controller
# $5: Gateway Name
# $6. Environment service.

 #${var.ctrlIPAddr} ${var.useremail} ${var.ctrlpassword} ${var.instanceLocation} ${var.instanceGW} ${var.svcEnv

#CONTROLLER_URL=https://$1:8443/1.4
mkdir -p /etc/ssl/nginx

# Authenticate to controller with credentials in order to get the Session Token
curl -sk -c cookie.txt -X POST --url 'https://'$1'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"$2"'","password": "'"$3"'"}}'

# Download nginx-repo cert and keys
curl -b cookie.txt -c cookie.txt -X GET --url 'https://'$1'/api/v1/platform/licenses/nginx-plus-licenses/controller-provided' --output nginx-plus-certs.gz

gunzip nginx-plus-certs.gz
cp nginx-plus-certs/* /etc/ssl/nginx/

wget https://nginx.org/keys/nginx_signing.key
wget https://cs.nginx.com/static/keys/nginx_signing.key && sudo apt-key add nginx_signing.key

apt-key add nginx_signing.key
sudo apt-get update
sudo apt-get install -y apt-transport-https lsb-release ca-certificates wget curl jq gettext vim net-tools 
printf "deb https://plus-pkgs.nginx.com/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/nginx-plus.list

wget -P /etc/apt/apt.conf.d https://cs.nginx.com/static/files/90nginx

sudo apt-get update
sudo apt-get install -y app-protect
sleep 10
sudo nginx -v

# wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/fchmainy/arm-nginx-vmss/main/nginx.conf
mv nginx.conf /etc/nginx/nginx.conf
sudo service nginx start

# Authenticate to controller with credentials in order to get the Session Token
curl -sk -c cookie.txt -X POST --url 'https://'$1'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"$2"'","password": "'"$3"'"}}'

# First, let's get the APIKey. it will be useful to onboard the instances onto the controller
apikey=$(curl -X GET -b cookie.txt -sk -H "Content-Type: application/json" https://$1/api/v1/platform/global | jq .currentStatus.agentSettings.apiKey)
echo "here is my controller API Key: $apikey"


# ------- Register to the Controller
export API_KEY=$apikey
echo $API_KEY
export HOSTNAME="$(hostname -f)"
export CTRL_FQDN=$(echo $ENV_CONTROLLER_URL | awk -F'https://' '{print $2}' | awk -F':8443' '{print $1}')
export CONTROLLER_URL=https://$1
export LOCATION=$4
export GATEWAY=$5
export SERVICE=$6

# ------ Install NGINX Controller Agent
curl -k -sS -L ${CONTROLLER_URL}/install/controller-agent > install.sh


CONTROLLER_FQDN=$(awk -F '"' '/controller_fqdn=/ { print $2 }' install.sh)
echo "${1} ${CONTROLLER_FQDN}" >> /etc/hosts

sh ./install.sh -l $LOCATION -i $HOSTNAME --insecure

# ------- Register to the Controller

# Create Environment
echo "create environment"
curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt -X POST -d '{"metadata":{"name":"'$SERVICE'"}}' --header 'Content-Type: application/json' --url 'https://'$1'/api/v1/services/environments'

gwExists=$(curl -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$1'/api/v1/services/environments/'$SERVICE'/gateways/'$GATEWAY --write-out '%{http_code}' --silent --output /dev/null)
echo $gwExists

# if the gateway does not exist, we are creating it, otherwise we add the instance reference to the gateway.
if [ $gwExists -ne 200 ]
then
	echo "Gateway does not exist"
	envsubst < gateways.json > gwPayload.json
	cat
else
	echo "Gateway exists... adding instance to gateway"
	curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$1'/api/v1/services/environments/'$SERVICE'/gateways/'$GATEWAY -o update.json
	jq '.desiredState.ingress.placement.instanceRefs += [{"ref": "/infrastructure/locations/aks/instances/'$HOSTNAME'"}]' update.json > gwPayload.json

fi
upsertgw=$(curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt -X PUT -d @gwPayload.json --header 'Content-Type: application/json' --url https://$1/api/v1/services/environments/$SERVICE/gateways/$GATEWAY)
echo $upsertgw
