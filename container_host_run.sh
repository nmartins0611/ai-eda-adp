#!/bin/bash
export RTPASS=ansible
echo "ansible" | passwd root --stdin

cp /root/hosts /etc/
#podman stop --all
podman rm --all

# podman create --name=ceos1 --privileged -v /tmp/setup/sw01/sw01:/mnt/flash/startup-config -e INTFTYPE=eth -e ETBA=1 -e SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 -e CEOS=1 -e EOS_PLATFORM=ceoslab -e container=docker -p 9092:9092 -p 6031:6030 -p 2001:22/tcp -i -t quay.io/nmartins/ceoslab-rh /sbin/init systemd.setenv=INTFTYPE=eth systemd.setenv=ETBA=1 systemd.setenv=SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 systemd.setenv=CEOS=1 systemd.setenv=EOS_PLATFORM=ceoslab systemd.setenv=container=podman
podman run -d --network management --name=ceos1 --privileged -v /tmp/setup/sw01/sw01:/mnt/flash/startup-config -e INTFTYPE=eth -e ETBA=1 -e SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 -e CEOS=1 -e EOS_PLATFORM=ceoslab -e container=docker -p 6031:6030 -p 2001:22/tcp -i -t quay.io/nmartins/ceoslab-rh /sbin/init systemd.setenv=INTFTYPE=eth systemd.setenv=ETBA=1 systemd.setenv=SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 systemd.setenv=CEOS=1 systemd.setenv=EOS_PLATFORM=ceoslab systemd.setenv=container=podman  ##
podman run -d --network management --name=ceos2 --privileged -v /tmp/setup/sw02/sw02:/mnt/flash/startup-config -e INTFTYPE=eth -e ETBA=1 -e SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 -e CEOS=1 -e EOS_PLATFORM=ceoslab -e container=docker -p 6032:6030 -p 2002:22/tcp -i -t quay.io/nmartins/ceoslab-rh /sbin/init systemd.setenv=INTFTYPE=eth systemd.setenv=ETBA=1 systemd.setenv=SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 systemd.setenv=CEOS=1 systemd.setenv=EOS_PLATFORM=ceoslab systemd.setenv=container=podman  ##systemd.setenv=MGMT_INTF=eth0
podman run -d --network management --name=ceos3 --privileged -v /tmp/setup/sw03/sw03:/mnt/flash/startup-config -e INTFTYPE=eth -e ETBA=1 -e SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 -e CEOS=1 -e EOS_PLATFORM=ceoslab -e container=docker -p 6033:6030 -p 2003:22/tcp -i -t quay.io/nmartins/ceoslab-rh /sbin/init systemd.setenv=INTFTYPE=eth systemd.setenv=ETBA=1 systemd.setenv=SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 systemd.setenv=CEOS=1 systemd.setenv=EOS_PLATFORM=ceoslab systemd.setenv=container=podman  ##systemd.setenv=MGMT_INTF=eth0
podman run -d --network management --name=mattermost --privileged --publish 8065:8065 mattermost/mattermost-preview:7.8.6

## Attach Networks
podman network connect loop ceos1
podman network connect net1 ceos1
podman network connect net3 ceos1
podman network connect management ceos1

podman network connect loop ceos2
podman network connect net1 ceos2
podman network connect net2 ceos2
podman network connect management ceos2

podman network connect loop ceos3
podman network connect net2 ceos3
podman network connect net3 ceos3
podman network connect management ceos3

podman network connect management mattermost

## Wait for Switches to load conf
sleep 60

## Get management IP
var1=$(podman inspect ceos1 | jq -r '.[] | .NetworkSettings.Networks.management | .IPAddress')
var2=$(podman inspect ceos2 | jq -r '.[] | .NetworkSettings.Networks.management | .IPAddress')
var3=$(podman inspect ceos3 | jq -r '.[] | .NetworkSettings.Networks.management | .IPAddress')
var4=$(podman inspect mattermost | jq -r '.[] | .NetworkSettings.Networks.management | .IPAddress')

## Build local host etc/hosts
echo "$var1" ceos1 >> /etc/hosts
echo "$var2" ceos2 >> /etc/hosts
echo "$var3" ceos3 >> /etc/hosts
echo "$var4" mattermost >> /etc/hosts
