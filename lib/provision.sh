#!/bin/bash

set -e

curl -o /tmp/go-server-12.2.1-15143.noarch.rpm http://download01.thoughtworks.com/go/12.2.1/ga/go-server-12.2.1-15143.noarch.rpm 
curl -o /tmp/go-agent-12.2.1-15143.noarch.rpm http://download01.thoughtworks.com/go/12.2.1/ga/go-agent-12.2.1-15143.noarch.rpm 
curl -o /tmp/jdk-7u3-linux-i586.rpm http://dl.dropbox.com/u/58853148/jdk-7u3-linux-i586.rpm 

rpm -i jdk-7u3-linux-i586.rpm go-server-12.2.1-15143.noarch.rpm go-agent-12.2.1-15143.noarch.rpm


