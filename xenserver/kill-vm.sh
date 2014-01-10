#!/bin/bash

# check required option
if [ $# -ne 1 ]
then
	echo "usage: $0 vm-name"
	exit 0
else
	VM_NAME=$1
fi

VM_UUID=`xe vm-list | grep -A 1 -B 2 $VM_NAME | grep uuid  | awk '{print $5}'`
VM_DOMAIN=`list_domains | grep $VM_UUID | awk '{print $1}'`
echo VM_UUID=$VM_UUID
echo VM_DOMAIN=$VM_DOMAIN

echo -n "destroying domain... "
/opt/xensource/debug/destroy_domain -domid $VM_DOMAIN
echo "done"

echo -n "rebooting vm... "
xe vm-reboot uuid=$VM_UUID --force
echo "done"
