#!/bin/bash

#Wazuh down 
docker-compose down

#removing all the files
rm -rf services.logs
rm -rf load-balancer.logs
rm -rf wazuhdata
rm -rf nginx.conf


#Remove all the container
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
