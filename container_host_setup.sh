yum install yum-utils jq podman wget git ansible-core nano -y
setenforce 0
export RTPASS=ansible
echo "ansible" | passwd root --stdin

# Grab sample switch config
rm -rf /tmp/setup ## Troubleshooting step

ansible-galaxy collection install community.general
ansible-galaxy collection install servicenow.itsm

mkdir /tmp/setup/

git clone https://github.com/nmartins0611/Instruqt_netops.git /tmp/setup/

### Configure containers

podman pull quay.io/nmartins/ceoslab-rh
#podman pull docker.io/nats
#podman run --name mattermost-preview -d --publish 8065:8065 mattermost/mattermost-preview


## Create Networks

podman network create net1
podman network create net2
podman network create net3
podman network create loop
podman network create management

# Create mattermost container
podman run -d --network management --name=mattermost --privileged --publish 8065:8065 mattermost/mattermost-preview:latest

##docker pull mattermost/platform:6.5.0

# podman create --name=ceos1 --privileged -v /tmp/setup/sw01/sw01:/mnt/flash/startup-config -e INTFTYPE=eth -e ETBA=1 -e SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 -e CEOS=1 -e EOS_PLATFORM=ceoslab -e container=docker -p 9092:9092 -p 6031:6030 -p 2001:22/tcp -i -t quay.io/nmartins/ceoslab-rh /sbin/init systemd.setenv=INTFTYPE=eth systemd.setenv=ETBA=1 systemd.setenv=SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 systemd.setenv=CEOS=1 systemd.setenv=EOS_PLATFORM=ceoslab systemd.setenv=container=podman
podman run -d --network management --name=ceos1 --privileged -v /tmp/setup/sw01/sw01:/mnt/flash/startup-config -e INTFTYPE=eth -e ETBA=1 -e SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 -e CEOS=1 -e EOS_PLATFORM=ceoslab -e container=docker -p 6031:6030 -p 2001:22/tcp -i -t quay.io/nmartins/ceoslab-rh /sbin/init systemd.setenv=INTFTYPE=eth systemd.setenv=ETBA=1 systemd.setenv=SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 systemd.setenv=CEOS=1 systemd.setenv=EOS_PLATFORM=ceoslab systemd.setenv=container=podman  ##
podman run -d --network management --name=ceos2 --privileged -v /tmp/setup/sw02/sw02:/mnt/flash/startup-config -e INTFTYPE=eth -e ETBA=1 -e SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 -e CEOS=1 -e EOS_PLATFORM=ceoslab -e container=docker -p 6032:6030 -p 2002:22/tcp -i -t quay.io/nmartins/ceoslab-rh /sbin/init systemd.setenv=INTFTYPE=eth systemd.setenv=ETBA=1 systemd.setenv=SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 systemd.setenv=CEOS=1 systemd.setenv=EOS_PLATFORM=ceoslab systemd.setenv=container=podman  ##systemd.setenv=MGMT_INTF=eth0
podman run -d --network management --name=ceos3 --privileged -v /tmp/setup/sw03/sw03:/mnt/flash/startup-config -e INTFTYPE=eth -e ETBA=1 -e SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 -e CEOS=1 -e EOS_PLATFORM=ceoslab -e container=docker -p 6033:6030 -p 2003:22/tcp -i -t quay.io/nmartins/ceoslab-rh /sbin/init systemd.setenv=INTFTYPE=eth systemd.setenv=ETBA=1 systemd.setenv=SKIP_ZEROTOUCH_BARRIER_IN_SYSDBINIT=1 systemd.setenv=CEOS=1 systemd.setenv=EOS_PLATFORM=ceoslab systemd.setenv=container=podman  ##systemd.setenv=MGMT_INTF=eth0

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

## Install Gmnic
bash -c "$(curl -sL https://get-gnmic.kmrd.dev)"

## Test GMNIC
## gnmic -a localhost:6031 -u ansible -p ansible --insecure subscribe --path   "/interfaces/interface[name=Ethernet1]/state/admin-status"
## gnmic -addr ceos1:6031 -username ansible -password ansible   get '/network-instances/network-instance[name=default]/protocols/protocol[identifier=BGP][name=BGP]/bgp'
## gnmic -a localhost:6031 -u ansible -p ansible --insecure subscribe --path 'components/component/state/memory/'

## SSH Setup
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFk2JAJHKRO9XmSxV+OYV+I0iWn4XTXGWqO3ut2wD/IsiumT7uLCLg4hjL0vheJWv/3rtCHfi7PQFD+kYzSSQ763VGHlJjaAZhqSqCRkG2fVRUFC0jmK7wkgmKxbr70uo9rRs65uUyCQVOa4eY7e9NsL2oL1KnxDSoYlQ1z5UjTdhssvuJs9PmPqsfd1ru6ez3ySowGEvt/wKIM3mcyWaX/ufK3TYykmJcvXxoJzHqLpfqM6dsq/R0SAQIjzoxkqpfY3zNHrSZ0SILgaA96HgaknTmrW3Y5gDsQ5CRMHCq25P0FgjHYmNAQsn1iL1aXoS6od3LrKGucgpgB82/h8QUmNx9ds8j3zTV/YZF2VrcmeWlbykYDIwyBD3zHZXs3VUSNwuno1BKObcxKeRKXbDqca96ORnk2UOhr2ANH4ns66RlZyw68YdqNYSPyJ9QV+GrbXHVHl2ZF9WOHWBMojRJJP9AX8CPyAy7OSIXgLYG2+LZD7kagneAWALEG7ghaAk= root@controller.ansible-automates.co.za" >> /root/.ssh/authorized_keys
echo "Host *" >> /etc/ssh/ssh_config
echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
echo "UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
chmod 400 /etc/ssh/ssh_config
systemctl restart sshd
