#!/bin/bash
#
# (C) Kazimierz Balos
#
# Changed from smbmount to mount -t cifs
#
# Package required: smbclient cifs-utils

version=1.0.10
mount_cfg=$HOME/.mount.cfg
access_type=ro
base_dir=$HOME/net
# vol0, vol1, ...
start_idx=0
myuid=$(id -u)
mygid=$(id -g)

if [ ! -f ~/.mount.cfg ]
then
	echo "Missing config file: $mount_cfg"
	exit 1
fi 

mount_user=`cat $mount_cfg | grep username | cut -d= -f2`
mount_pass=`cat $mount_cfg | grep password | cut -d= -f2`

function count_volumes() {
	vol_count=`smbclient -L //$host.local -U $mount_user -A $mount_cfg 2>&1 | grep ${pattern}.${access_type} -c`
	echo "${vol_count}"
}

function get_loop_param() {
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
		sudo mount -t cifs //$host.local/${dir_name}${access_type} ${dir_full} -ousername=$mount_user,password=$mount_pass,uid=$myuid,gid=$mygid
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
