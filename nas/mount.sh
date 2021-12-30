#!/bin/bash
#
# (C) Kazimierz Balos
#
# Changed from smbmount to mount -t cifs

debug=0
missing_pkgs=""
function check_package() {
        if [ $(dpkg --get-selections | grep -v deinstall | grep -c ^$1) -eq 0 ]
        then
                missing_pkgs="${missing_pkgs} $1"
        fi
}
for i in smbclient cifs-utils
do
        check_package $i
done
if [ "${missing_pkgs}" ]
then
        echo "sudo apt-get install${missing_pkgs}"
        exit 1
fi

version=1.0.12
mount_cfg=$HOME/.mount.cfg
access_type=ro
base_dir=$HOME/net
# vol1, vol2, ...
start_idx=1
myuid=$(id -u)
mygid=$(id -g)

if [ ! -f $mount_cfg ]
then
	echo "Missing config file: $mount_cfg"
	exit 1
fi 
perm=$(ls -al $mount_cfg | awk '{print $1}')
perm_req="-rw-------"
if [[ "${perm}" != "${perm_req}" ]]
then
	echo "File ${mount_cfg} has wrong permissions: ${perm}. Required: ${perm_req}."
	exit 1
fi

mount_user=`cat $mount_cfg | grep username | cut -d= -f2`
mount_pass=`cat $mount_cfg | grep password | cut -d= -f2`

function count_volumes() {
	vol_count=`smbclient -L //$host.local -U $mount_user -A $mount_cfg 2>&1 | grep ${pattern}.${access_type} -c`
	echo "${vol_count}"
}

function get_loop_param() {
	pattern=vol
	if [ $(smbclient -L //$host.local -U $mount_user -A $mount_cfg 2>&1 | grep -c ${pattern}0${access_type}) -eq 1 ]
	then
		start_idx=0
	fi
	vol_count=$(count_volumes)
	stop_idx=`expr $start_idx + $vol_count`
	stop_idx=`expr $stop_idx - 1`
	echo "Volumes: ${vol_count}. Loop ${start_idx}-${stop_idx}"
}

function print_usage() {
	echo "usage: ./mount.sh hostname {start|stop|status} [ro|rw]"
}

function remove_dir() {
	if [ -e $1 ]
	then
		rmdir $1
		if [ $? -eq 0 ]
		then
			echo " removed"
		else
			echo " could not be removed"
		fi
	else
		echo " does not exist"
	fi
}

function create_dir() {
	if [ ! -e $1 ]
	then
		mkdir -p $1
		if [ $? -eq 0 ]
		then
			echo "Directory $1 created successfully"
			echo -n ""
		else
			echo "Directory $1 could not be created"
		fi
		else
		echo "Directory $1 already exists" 
	fi
}

if [ $# -eq 1 ]
then
	if [ $1 = "status" ]
	then
		pattern=vol
		df -h | head -1
		df -h | grep $pattern
		exit 0
	fi
fi

if [ $# -eq 2 -o $# -eq 3 ]
then
	echo "$0 version $version"
	host=$1
	pattern=vol
else 
	print_usage
	exit 0
fi

if [ $# -eq 3 ]
then
	access_type=$3
fi

case $2 in 
start)
	get_loop_param
	for i in `seq $start_idx $stop_idx`
	do
		dir_name=${pattern}${i}
		dir_full=$base_dir/${host}/${dir_name}
		create_dir ${dir_full}
		cmd="sudo mount -t cifs //$host.local/${dir_name}${access_type} ${dir_full} -ousername=$mount_user,password=$mount_pass,uid=$myuid,gid=$mygid"
		if [ ${debug} -eq 1 ]
		then
			echo ${cmd}
		else
			${cmd}
		fi
	done
;;
stop)
	get_loop_param
	for i in `seq $start_idx $stop_idx`
	do
		dir_name=${pattern}${i}
		dir_full=$base_dir/${host}/${dir_name}
		echo -n "Directory ${dir_full}:"
		if [ -e ${dir_full} ]
		then 
			sudo umount ${dir_full}
			echo -n " unmounted"
                else
			echo -n " could not be unmounted"
		fi
		remove_dir ${dir_full}
	done
	echo -n "Directory ${base_dir}/${host}:"
	remove_dir $base_dir/$host
	echo -n "Directory ${base_dir}:"
	remove_dir $base_dir
;;
*)
	print_usage
	exit 0
;;
esac
df -h | grep $pattern
