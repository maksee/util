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
		smartctl_info=$(sudo smartctl -a $i | tr '\n' '@')
		drive_supp=0
		if [[ $model == "ADATA" ]]
		then
			drive_supp=1
			unitw="Host_Writes_32MiB"
			unitr="Host_Reads_32MiB"
			formula="(32 * %s)/(1024 * 1024)"
		elif [[ $model == "SanDisk" ]]
		then
			drive_supp=1
			unitw="Lifetime_Writes_GiB"
			unitr="Lifetime_Reads_GiB"
			formula="%s/1024"
			:
		elif [[ $model =~ "SSDPR" ]]
		then
			drive_supp=1
			unitw="Total_LBAs_Written"
			unitr="Total_LBAs_Read"
			formula="(512 * %s)/(1024 * 1024 * 1024)"
		fi
		if [ $drive_supp -eq 1 ]
		then
			scale=2
			prefix="scale=$scale"
			valw=$(echo ${smartctl_info} | tr '@' '\n' | grep $unitw | awk '{print $10}' | tr '\n' ' ')
			valr=$(echo ${smartctl_info} | tr '@' '\n' | grep $unitr | awk '{print $10}' | tr '\n' ' ')
			valw=$(printf "$prefix\n$formula\n" $valw | bc)
			valr=$(printf "$prefix\n$formula\n" $valr | bc)
			printf " %6s TBW  %6s TBW" $valw $valr
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
