#!/bin/bash

missing_pkgs=""
function check_package() {
        if [ $(dpkg --get-selections | grep -v deinstall | grep -c ^$1) -eq 0 ]
        then
		missing_pkgs="${missing_pkgs} $1"
        fi
}
for i in smartmontools hddtemp lm-sensors nvme-cli
do
        check_package $i
done
if [ "${missing_pkgs}" ]
then
	echo "sudo apt-get install${missing_pkgs}"
	exit 1
fi

sensors | grep 'fan[245]\|Core'
#nvme list
for i in {0..4}
do
	drive=/dev/nvme$i
	if [ -e $drive ]
	then
		echo -n "$drive "
		sudo nvme smart-log $drive | grep -i temp | grep -v 'Warning\|Critical'
	fi
	sudo smartctl -A $drive | grep "Data Units"
done
for i in $(ls /dev/sd[a-z])
do
	sudo hddtemp -w $i | tr '\n' ' '
	lineend=0
	type=$(sudo hdparm -I $i | grep -i 'Nominal Media Rotation Rate' | awk -F: '{print $2}' | sed 's/^ //g')
	if [[ "$type" == "Solid State Device" ]]
	then
		model=$(sudo hdparm -i $i | grep Model | awk '{print $1}' | awk -F= '{print $2}')
		if [[ $model == "ADATA" ]]
		then
			echo -n "HW_32MiB: "
			smartctl_info=$(sudo smartctl -a $i | tr '\n' '@')
			echo ${smartctl_info} | tr '@' '\n' | grep Host_Writes_32MiB | awk '{print $10}' | tr '\n' ' '
			echo -n "HR_32MiB: "
			echo ${smartctl_info} | tr '@' '\n' | grep Host_Reads_32MiB | awk '{print $10}' | tr '\n' ' '
			echo -n "TW_32MiB: "
			echo ${smartctl_info} | tr '@' '\n' | grep TLC_Writes_32MiB | awk '{print $10}' | tr '\n' ' '
		elif [[ $model == "SanDisk" ]]
		then
			:
		elif [[ $model =~ "SSDPR" ]]
		then
			echo -n "GBW: "
			smartctl_info=$(sudo smartctl -a $i | tr '\n' '@')
			echo ${smartctl_info} | tr '@' '\n' | grep Total_LBAs_Written | awk '{print $10}' | tr '\n' ' '
			echo -n "GBR: "
			echo ${smartctl_info} | tr '@' '\n' | grep Total_LBAs_Read | awk '{print $10}' | tr '\n' ' '
		else
			:
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
