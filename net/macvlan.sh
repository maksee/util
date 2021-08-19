#!/bin/bash

# Allow host <-> guest communication
# https://superuser.com/questions/349253/guest-and-host-cannot-see-each-other-using-linux-kvm-and-macvtap

# modprobe macvlan

ipaddr=10.0.1.3
ipgw=10.0.1.1
ifname=enp0s31f6
ifmac="70:85:c2:32:02:ec"

ip link add link $ifname address $ifmac macvlan0 type macvlan mode bridge
ip address add $ipaddr/24 dev macvlan0
ip link set dev macvlan0 up

ip route flush dev $ifname
ip route add default via $ipgw dev macvlan0 proto static
