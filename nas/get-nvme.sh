#!/bin/bash

if ! [ -e /dev/nvme0 ]
then
	exit 0
fi

for i in $(ls /dev/nvme[0-9])
do
	type="Unknown"
	lineend=0
	temp=$(sudo nvme smart-log $i | grep -m 1 -i temp | grep -v 'Warning\|Critical' | awk '{print $3}')
	model=$(sudo smartctl -a /dev/nvme0 | grep "Model Number" | awk '{print $3}')
	if [[ "$i" =~ "nvme" ]]
	then
		type="Solid State Device"
	fi
	if [[ "$type" == "Solid State Device" ]]
	then
		smartctl_info=$(sudo smartctl -a $i | tr '\n' '@')
		drive_supp=0
		if [[ $model == "KINGSTON" ]]
		then
			drive_supp=1
			unitw="Data Units Written"
			unitr="Data Units Read"
			formula="%s"
		elif [[ $model == "ADATA" ]]
		then
			drive_supp=1
			unitw="Data Units Written"
			unitr="Data Units Read"
			formula="%s"
		fi
		if [ $drive_supp -eq 1 ]
		then
			scale=3
			prefix="scale=$scale\n"
			suffix=""
			valw_exists=0
			valr_exists=0
			margin=" "
			if [ $(echo ${smartctl_info} | tr '@' '\n' | grep -c "$unitw") -eq 1 ]
			then
				valw_exists=1
				valw=$(echo ${smartctl_info} | tr '@' '\n' | grep "$unitw" | awk '{print $5}' | awk -F[ '{print $2}' | tr '\n' ' ')
				valw=$(echo $valw | sed 's/,/./')
				valw=$(printf "$prefix$formula$suffix\n" $valw | bc)
				# fix lack of leading zero in bc
				valw=$(echo -n $valw | sed -e 's/^-\./-0./' -e 's/^\./0./')
			fi
			if [ $(echo ${smartctl_info} | tr '@' '\n' | grep -c "$unitr") -eq 1 ]
			then
				valr_exists=1
				valr=$(echo ${smartctl_info} | tr '@' '\n' | grep "$unitr" | awk '{print $5}' | awk -F[ '{print $2}' | tr '\n' ' ')
				valr=$(echo $valr | sed 's/,/./')
				valr=$(printf "$prefix$formula$suffix\n" $valr | bc)
				# fix lack of leading zero in bc
				valr=$(echo -n $valr | sed -e 's/^-\./-0./' -e 's/^\./0./')
			fi
			if [ $valr_exists -eq 1 ] && [ $valw_exists -eq 1 ]
			then
				printf "$i: %s°C %7s TBW  %7s TBR" "$temp" $valw $valr
			elif [ $valw_exists -eq 1 ]
			then
				printf "$i: %s°C %7s TBW" "$temp" $valw
			elif [ $valr_exists -eq 1 ]
			then
				printf "$i: %s°C %7s TBR" "$temp" $valr
			fi
		fi
	else
		echo ""
		lineend=1
	fi
	if [ $lineend -eq 0 ]
	then
		echo ""
	fi
done
