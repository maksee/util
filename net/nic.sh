#!/bin/bash

NICS=$(ifconfig | grep enp | awk -F: '{print $1}' | tr '\n' ' ')
for i in $NICS
do
        echo -n $i
        echo -en " "
	k=0
	for j in inet ether
	do
        	ifconfig $i | grep "$j\ " | awk '{print $2}' | tr '\n' ' ' | sed 's/ //g'
		if [[ $k -eq 0 ]]
		then
			echo -n " "
			k=1
		fi
	done
        ethtool $i 2>&1 | grep "Speed\|Port" | tr '\n' ' ' | tr '\t' ' ' | sed -e 's/Speed: //g' -e 's/Port: //g' -e 's/  / /g'
        echo ""
done

