#!/bin/bash

# check required option
if [ $# -ne 1 ]
then
	echo "usage: $0 vpn-gateway-url"
	exit 0
else
	VPNGW=$1
fi

# connect to VPN
sudo /usr/sbin/openconnect --user=$USER --verbose --no-cert-check --script=./vpnc-script $VPNGW
