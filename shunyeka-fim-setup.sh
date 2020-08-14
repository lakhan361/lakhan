#!/bin/bash

mkdir wazuhdata
touch nginx.conf
#Check if input is Provided or Not

if [ -z "$1" ]
  then
    printf "\n\nNumber of Wazuh-Worker needed : \n\n" ; exit 1 
fi

#Number of worker check
re='^[0-99]+$'
if ! [[ $1 =~ $re ]] ; then
   echo "Pass a valid number" >&2; exit 1
fi



#Input values
echo "Number of Worker node : $1"
#echo "Email Address : $2"
#echo "Password : $3"


#sleep 3
#printf  "\n\n*******Input Validation completed.***********\n\n"

sleep 3
printf  "\n\n*******Docker and Docker-Compose installation started.***********\n\n"
sleep 3

#Docker installation process begin

apt-get update &&apt-get upgrade -y

sudo apt-get remove docker docker-engine docker.io containerd runc -y

sudo apt-get update

sudo apt-get install apt-transport-https ca-certificates  curl gnupg-agent software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sleep 3
printf  "\n\n********Docker installation Completed********\n\n"
sleep 3
docker version
sleep 3
printf "\n\n********Docker-Compose installation********\n\n"

sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

printf "\n\n"
docker-compose --version

#Increase max_map_count on your Docker host:

sysctl -w vm.max_map_count=262144
sleep 3

printf  "\n\n*******Docker and Docker-Compose installation completed.***********\n\n"

sleep 3
printf  "\n\n*******Starting Wazuh installation.***********\n\n"
sleep 3

printf "\n Pulling all the specific images!"

#Pulling the specific dockerimages images 
docker load < Shunyeka-elasticsearch.tar
docker load < Shunyeka-FIM.tar
docker load < Shunyeka-Kibana.tar
docker load < Shunyeka-nginx.tar
docker load < Shunyeka-postfix.tar


function clean_up {
    # Perform program exit housekeeping
    kill $CHILD_PID
    exit
}

trap clean_up SIGHUP SIGINT SIGTERM

rm -f nginx.conf

cp nginx_default.conf nginx.conf




#export $(cat .env | grep -i MTP_USER)
#cp ossec_default.conf ossec.conf
#sed -i -e ";s#FROM_EMAIL#$MTP_USER#g" ossec.conf
#sed -i -e ";s#TO_EMAIL#$MTP_USER#g" ossec.conf


docker-compose up --scale wazuh-worker=$1 --scale load-balancer=0 > services.logs &

CHILD_PID=$!

echo "Waiting for services start.";

sleep 10

printf "\n\nCreating load-balancer configuration\n\n";

sleep 18

MASTER_IP=$(docker-compose exec wazuh hostname -i)

sed -i -e ";s#<WAZUH-MASTER-IP>#${MASTER_IP::-1}#g" nginx.conf

for i in $(seq 1 $1)
do
    WORKER_IP=$(docker-compose exec --index=$i wazuh-worker hostname -i)
    sed -i -e ";s#NEXT_SERVER#server ${WORKER_IP::-1}:1514;\n\tNEXT_SERVER#g" nginx.conf
done

sed -i -e ";s#NEXT_SERVER##g" nginx.conf

printf "\n\nRunning load-balancer service\n\n";

docker-compose up load-balancer > load-balancer.logs &

sleep 10
printf "\n\nScript completed\n\n"; 
