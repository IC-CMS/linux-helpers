#!/bin/bash

sudo yum update
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce
sudo usermod -a -G docker ec2-user
sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/bin/docker-compose > /dev/null
sudo chmod +x /usr/bin/docker-compose
sudo service docker start
sudo chkconfig docker on
