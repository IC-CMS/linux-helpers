#!/bin/bash

sudo curl -L https://github.com/docker/compose/releases/download/1.20.0-rc1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo service docker start
sudo chkconfig docker on
