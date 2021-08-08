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
		elif [[ $model == "KINGSTON" ]]
		then
			drive_supp=1
			unitw="Total_LBAs_Written"
			unitr="Total_LBAs_Read"
			# See comment for Goodram
			formula="%s/1000"
		elif [[ $model =~ "SSDPR" ]]
		then
			drive_supp=1
			unitw="Total_LBAs_Written"
			unitr="Total_LBAs_Read"
			# theoretically, this should be 512B:
			# formula="(512 * %s)/(1024 * 1024 * 1024)"
			# however, tested practically with Goodram Optimum Tool
			# and it displays GIGABYTES WRITTEN 1145GB only when we divide this value by 1000, not 1024
			formula="%s/1000"
		fi
		if [ $drive_supp -eq 1 ]
		then
			scale=3
			prefix="scale=$scale\n"
			suffix="+(0.1-0.1)"
			valw_exists=0
			valr_exists=0
			if [ $(echo ${smartctl_info} | tr '@' '\n' | grep -c $unitw) -eq 1 ]
			then
				valw_exists=1
				valw=$(echo ${smartctl_info} | tr '@' '\n' | grep $unitw | awk '{print $10}' | tr '\n' ' ')
				valw=$(printf "$prefix$formula$suffix\n" $valw | bc)
				# fix lack of leading zero in bc
				valw=$(echo -n $valw | sed -e 's/^-\./-0./' -e 's/^\./0./')
			fi
			if [ $(echo ${smartctl_info} | tr '@' '\n' | grep -c $unitr) -eq 1 ]
			then
				valr_exists=1
				valr=$(echo ${smartctl_info} | tr '@' '\n' | grep $unitr | awk '{print $10}' | tr '\n' ' ')
				valr=$(printf "$prefix$formula$suffix\n" $valr | bc)
				# fix lack of leading zero in bc
				valr=$(echo -n $valr | sed -e 's/^-\./-0./' -e 's/^\./0./')
			fi
			if [ $valr_exists -eq 1 ] && [ $valw_exists -eq 1 ]
			then
				printf "%6s TBW  %6s TBR" $valw $valr
			elif [ $valw_exists -eq 1 ]
			then
				printf "%6s TBW" $valw
			elif [ $valr_exists -eq 1 ]
			then
				printf "%6s TBR" $valr
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
