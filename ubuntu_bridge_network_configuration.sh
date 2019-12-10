#!/usr/bin/env bash

set -xe

# shellcheck disable=SC1091
source lib/logging.sh
# shellcheck disable=SC1091
source lib/common.sh

if [ "$MANAGE_PRO_BRIDGE" == "y" ]; then
     # Adding an IP address in the libvirt definition for this network results in
     # dnsmasq being run, we don't want that as we have our own dnsmasq, so set
     # the IP address here
     sudo brctl addbr ${PRO_BRIDGE_NAME}
     # sudo ifconfig ${PRO_BRIDGE_NAME} 172.22.0.1 netmask 255.255.255.0 up
     # Use ip command. ifconfig commands are deprecated now.
     sudo ip addr add dev ${PRO_BRIDGE_NAME} 172.22.0.1/24
     sudo ip link set ${PRO_BRIDGE_NAME} up

     # Need to pass the provision interface for bare metal
     if [ "$PRO_IF" ]; then
       sudo brctl addif ${PRO_BRIDGE_NAME} "$PRO_IF"
     fi
 fi

 if [ "$MANAGE_INT_BRIDGE" == "y" ]; then
     # Create the baremetal bridge
     if ! [[  $(ip a show ${INT_BRIDGE_NAME}) ]]; then
       sudo brctl addbr ${INT_BRIDGE_NAME}
       # sudo ifconfig ${INT_BRIDGE_NAME} 192.168.111.1 netmask 255.255.255.0 up
       # Use ip command. ifconfig commands are deprecated now.
       sudo ip addr add dev ${INT_BRIDGE_NAME} 192.168.111.1/24
       sudo ip link set ${INT_BRIDGE_NAME} up
     fi

     # Add the internal interface to it if requests, this may also be the interface providing
     # external access so we need to make sure we maintain dhcp config if its available
     if [ "$INT_IF" ]; then
       sudo brctl addif "$INT_IF"
     fi
 fi

 # restart the libvirt network so it applies an ip to the bridge
 if [ "$MANAGE_BR_BRIDGE" == "y" ] ; then
     sudo virsh net-destroy ${INT_BRIDGE_NAME}
     sudo virsh net-start ${INT_BRIDGE_NAME}
     if [ "$INT_IF" ]; then #Need to bring UP the NIC after destroying the libvirt network
         sudo ifup "$INT_IF"
     fi
 fi
